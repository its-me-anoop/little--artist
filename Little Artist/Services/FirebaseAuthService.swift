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

/// Manages Firebase Authentication lifecycle.
///
/// On first launch the user is signed in anonymously. When the user enables
/// Cloud Sync, they upgrade to Sign in with Apple via
/// ``handleSignInWithAppleResult(_:)``, preserving their anonymous UID
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

    /// Most recent Apple authorization code captured during sign-in. Stored
    /// so account deletion can revoke the Apple token within the ~5-minute
    /// window Apple permits for a given code.
    private var lastAppleAuthorizationCode: String?

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

    /// Configures an `ASAuthorizationAppleIDRequest` with the scopes and
    /// hashed nonce required to complete Sign in with Apple.
    ///
    /// Call this from the request-builder closure of `SignInWithAppleButton`.
    /// The unhashed nonce is stored on the service so that
    /// ``handleSignInWithAppleResult(_:)`` can use it when exchanging the
    /// Apple credential for a Firebase credential.
    func configureSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Handles the authorization result returned by `SignInWithAppleButton`
    /// and links or signs in the user with Firebase.
    ///
    /// - Parameter result: The result passed to the `onCompletion` closure of
    ///   `SignInWithAppleButton`.
    func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) async throws {
        // Wait for any in-flight anonymous sign-in to finish first, so we
        // have a currentUser to link the Apple credential to.
        await anonymousSignInTask?.value

        let authorization: ASAuthorization
        switch result {
        case .success(let auth):
            authorization = auth
        case .failure(let error):
            throw error
        }

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        guard let nonce = currentNonce else {
            throw AuthError.missingToken
        }
        currentNonce = nil

        // Capture the authorization code so account deletion can revoke the
        // Apple token later (required by App Store guideline 5.1.1(v)).
        if let codeData = appleCredential.authorizationCode,
           let codeString = String(data: codeData, encoding: .utf8) {
            lastAppleAuthorizationCode = codeString
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        // Link to existing anonymous account (preserves UID + data)
        if let user = Auth.auth().currentUser, user.isAnonymous {
            do {
                let linkResult = try await user.link(with: firebaseCredential)
                currentUser = linkResult.user
                logger.info("Apple account linked to anonymous: \(linkResult.user.uid, privacy: .public)")
                return
            } catch let error as NSError where error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                // Apple credential already linked to a different Firebase account.
                // The credential token is single-use, so we must:
                // 1. Delete the current anonymous user to avoid conflicts
                // 2. Sign in with the credential (first and only consumption)
                logger.warning("Credential already in use — deleting anonymous user and signing in directly")
                try? await user.delete()
                let signInResult = try await Auth.auth().signIn(with: firebaseCredential)
                currentUser = signInResult.user
                logger.info("Apple sign-in OK (credential reuse recovery): \(signInResult.user.uid, privacy: .public)")
                return
            }
        }

        // No anonymous user — sign in directly
        let signInResult = try await Auth.auth().signIn(with: firebaseCredential)
        currentUser = signInResult.user
        logger.info("Apple sign-in OK: \(signInResult.user.uid, privacy: .public)")
    }

    /// Revokes the Apple authorization code for the current user.
    ///
    /// Called before account deletion so the Apple credential no longer
    /// grants access to the now-deleted Firebase user (Apple requires this
    /// per App Store guideline 5.1.1(v)).
    ///
    /// Revocation is best-effort: the authorization code must have been
    /// captured within the past ~5 minutes during sign-in. If no code is
    /// available (e.g. the user signed in during a previous session), this
    /// method logs a warning and returns without throwing so the account
    /// deletion flow can still proceed.
    func revokeAppleTokenForCurrentUser() async throws {
        guard Auth.auth().currentUser != nil else {
            throw AuthError.noCurrentUser
        }

        guard let authorizationCode = lastAppleAuthorizationCode else {
            logger.warning("Apple token revocation skipped — no recent authorization code available")
            return
        }

        do {
            try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
            lastAppleAuthorizationCode = nil
            logger.info("Apple token revoked")
        } catch {
            // Token revocation is best-effort — the account deletion flow
            // should proceed even if revocation fails (e.g. offline or the
            // code has already expired).
            logger.warning("Apple token revocation failed: \(error.localizedDescription, privacy: .public)")
        }
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

