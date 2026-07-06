//
//  AIEngine.swift
//  Little Artist
//
//  Identifies which engine produced an AI result and encodes the
//  engine-ladder selection rules. Kept free of iOS 27 availability
//  gating so ladder logic is unit-testable on any deployment target.
//

import Foundation

// MARK: - AI Engine

/// The engine that produced an AI-generated result.
///
/// Ladder order: on-device (private, free, offline) → Apple Private Cloud
/// Compute (private, quota-gated) → Gemini (cloud) → static fallback.
enum AIEngine: String, Equatable {
    case onDevice
    case privateCloudCompute
    case gemini
    case fallback

    /// A short user-facing privacy note, or nil when nothing should be shown.
    /// Privacy is a feature — surface it when an Apple engine did the work.
    var privacyBadge: String? {
        switch self {
        case .onDevice:
            return "Generated on-device — never leaves your iPhone"
        case .privateCloudCompute:
            return "Generated with Apple Private Cloud Compute"
        case .gemini, .fallback:
            return nil
        }
    }
}

// MARK: - Engine Availability

/// A snapshot of which Apple Intelligence engines can serve a multimodal
/// request right now. Built from the live models at runtime; hand-built
/// in unit tests.
struct AIEngineAvailability: Equatable {
    var onDeviceAvailable = false
    var onDeviceSupportsVision = false
    var privateCloudAvailable = false
    var privateCloudSupportsVision = false
    var privateCloudQuotaReached = false

    /// Apple engines capable of serving a multimodal request, in ladder
    /// order: on-device first, then Private Cloud Compute. Empty when the
    /// caller should fall through to Gemini or static fallbacks.
    var capableAppleEngines: [AIEngine] {
        var engines: [AIEngine] = []
        if onDeviceAvailable && onDeviceSupportsVision {
            engines.append(.onDevice)
        }
        if privateCloudAvailable && privateCloudSupportsVision && !privateCloudQuotaReached {
            engines.append(.privateCloudCompute)
        }
        return engines
    }
}
