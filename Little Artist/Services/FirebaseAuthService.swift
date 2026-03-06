//
//  FirebaseAuthService.swift
//  Little Artist
//
//  Manages Firebase Authentication — anonymous sign-in on launch,
//  Sign in with Apple for sync/sharing, and account linking.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation
import os
import SwiftData
import UIKit

/// Manages Firebase Authentication lifecycle.
///
/// On first launch the user is signed in anonymously. When premium
/// users enable sync, they upgrade to Sign in with Apple via
/// ``linkAppleAccount(credential:)``, preserving their anonymous UID
/// and any data already written to Firestore.
@MainActor
@Observable
final class FirebaseAuthService: NSObject {

    // MARK: - Singleton

    static let shared = FirebaseAuthService()

    // MARK: - Published State

    /// The currently authenticated Firebase user (anonymous or Apple-linked).
    private(set) var currentUser: FirebaseAuth.User?

    /// `true` while an auth operation is in flight.
    private(set) var isAuthenticating = false

    /// Human-readable error from the last auth attempt, if any.
    private(set) var authError: String?

    /// `true` once the user has linked an Apple credential (persistent sync identity).
    var isLinkedWithApple: Bool {
        currentUser?.providerData.contains(where: { $0.providerID == "apple.com" }) ?? false
    }

    /// Convenience accessor for the Firebase UID.
    var userId: String? { currentUser?.uid }

    // MARK: - Private

    private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Auth")

    /// Unhashed nonce used during the current Sign in with Apple flow.
    private var currentNonce: String?

    /// Continuation for the Sign in with Apple async bridge.
    private var signInContinuation: CheckedContinuation<ASAuthorization, Error>?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    /// Task handle for the initial anonymous sign-in so callers can await it.
    private var anonymousSignInTask: Task<Void, Never>?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Lifecycle

    /// Call once at app launch (after `FirebaseApp.configure()`).
    /// Listens for auth state changes and signs in anonymously if needed.
    func setup() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                guard user != nil else { return }

                // Only start sync if the user has completed onboarding.
                // This prevents sync from restarting after sign-out
                // (which resets hasCompletedOnboarding and re-creates an anonymous user).
                guard UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") else { return }

                FirestoreSyncService.shared.start()

                if let container = FirestoreRepository.shared.modelContainer {
                    let uploadContext = ModelContext(container)
                    await FirestoreRepository.shared.uploadAllLocalData(from: uploadContext)
                    await FirestoreRepository.shared.syncUserPreferencesToFirestore()
                }
            }
        }

        // If no user yet, sign in anonymously (store task so others can await it)
        if Auth.auth().currentUser == nil {
            anonymousSignInTask = Task { await signInAnonymously() }
        } else {
            currentUser = Auth.auth().currentUser
            logger.info("Existing user: \(self.currentUser?.uid ?? "nil", privacy: .public)")
        }
    }

    // MARK: - Anonymous Auth

    /// Signs in anonymously. Called automatically at first launch.
    func signInAnonymously() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        authError = nil

        do {
            let result = try await Auth.auth().signInAnonymously()
            currentUser = result.user
            logger.info("Anonymous sign-in OK: \(result.user.uid, privacy: .public)")
        } catch {
            authError = error.localizedDescription
            logger.error("Anonymous sign-in failed: \(error.localizedDescription, privacy: .public)")
        }

        isAuthenticating = false
        anonymousSignInTask = nil
    }

    // MARK: - Sign in with Apple

    /// Starts the Sign in with Apple flow and links the credential to
    /// the current anonymous account. Returns `true` on success.
    @discardableResult
    func signInWithApple() async throws -> Bool {
        // Wait for any in-flight anonymous sign-in to finish first,
        // so we have a currentUser to link the Apple credential to.
        await anonymousSignInTask?.value

        let nonce = randomNonceString()
        currentNonce = nonce

        let authorization = try await requestAppleAuthorization(nonce: nonce)

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        // Link to existing anonymous account (preserves UID + data)
        if let user = Auth.auth().currentUser, user.isAnonymous {
            do {
                let result = try await user.link(with: firebaseCredential)
                currentUser = result.user
                logger.info("Apple account linked to anonymous: \(result.user.uid, privacy: .public)")
                return true
            } catch let error as NSError where error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                // Apple credential already linked to a different Firebase account.
                // This happens when the user previously deleted their account but
                // the credential association persists in Firebase.
                //
                // The credential token is single-use, so we must:
                // 1. Delete the current anonymous user to avoid conflicts
                // 2. Sign in with the credential (first and only consumption)
                logger.warning("Credential already in use — deleting anonymous user and signing in directly")
                try? await user.delete()
                let result = try await Auth.auth().signIn(with: firebaseCredential)
                currentUser = result.user
                logger.info("Apple sign-in OK (credential reuse recovery): \(result.user.uid, privacy: .public)")
                return true
            }
        }

        // No anonymous user — sign in directly
        let result = try await Auth.auth().signIn(with: firebaseCredential)
        currentUser = result.user
        logger.info("Apple sign-in OK: \(result.user.uid, privacy: .public)")
        return true
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        logger.info("Signed out — will re-authenticate anonymously")
        Task { await signInAnonymously() }
    }

    /// Deletes the current Firebase account, then falls back to anonymous auth.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }

        try await user.delete()
        currentUser = nil
        logger.info("Account deleted — will re-authenticate anonymously")
        await signInAnonymously()
    }

    // MARK: - Apple Auth Helpers

    /// Bridges `ASAuthorizationController` into async/await.
    private func requestAppleAuthorization(nonce: String) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    /// Generates a random nonce string for Sign in with Apple.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA-256 hash of the nonce for Apple's anti-replay check.
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case missingToken
        case noCurrentUser

        var errorDescription: String? {
            switch self {
            case .missingToken: "Apple sign-in did not return an identity token."
            case .noCurrentUser: "No authenticated user."
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension FirebaseAuthService: ASAuthorizationControllerPresentationContextProviding {

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

            // Try the key window of the foreground-active scene first.
            if let activeScene = windowScenes.first(where: { $0.activationState == .foregroundActive }),
               let window = activeScene.windows.first(where: { $0.isKeyWindow }) {
                return window
            }

            // Fallback: any visible window from any connected scene.
            return windowScenes.lazy.compactMap { scene in
                scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
            }.first!
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension FirebaseAuthService: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            signInContinuation?.resume(returning: authorization)
            signInContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            signInContinuation?.resume(throwing: error)
            signInContinuation = nil
        }
    }
}
