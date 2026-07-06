//
//  CloudSyncStatus.swift
//  Little Artist
//
//  Observes the user's iCloud account availability so Settings can show
//  whether CloudKit sync is active. Sync itself is automatic — SwiftData
//  mirrors the store to the private iCloud database whenever an account
//  is available.
//

import CloudKit
import Foundation
import Observation

/// Reports whether the user's iCloud account is available for sync.
@MainActor
@Observable
final class CloudSyncStatus {
    static let shared = CloudSyncStatus()

    /// The CloudKit container backing the SwiftData store.
    static let containerIdentifier = "iCloud.uk.co.flutterly.Little-Artist"

    enum Status {
        case checking
        case active
        case noAccount
        case unavailable

        /// A short user-facing description of the sync state.
        var label: String {
            switch self {
            case .checking: return "Checking iCloud…"
            case .active: return "Backed up to your private iCloud"
            case .noAccount: return "Sign in to iCloud to back up and sync"
            case .unavailable: return "iCloud is unavailable on this device"
            }
        }

        /// Whether sync is currently working.
        var isActive: Bool { self == .active }
    }

    private(set) var status: Status = .checking

    private init() {}

    /// Re-checks the iCloud account status. Safe to call repeatedly.
    func refresh() {
        Task {
            let account = try? await CKContainer(
                identifier: Self.containerIdentifier
            ).accountStatus()

            switch account {
            case .available:
                status = .active
            case .noAccount:
                status = .noAccount
            default:
                status = .unavailable
            }
        }
    }
}
