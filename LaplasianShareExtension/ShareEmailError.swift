//
//  ShareEmailError.swift
//  LaplasianShareExtension
//
//  Created by Kiro on 16.08.2025.
//

import Foundation

/// Error types for the share email functionality
enum ShareEmailError: LocalizedError, Equatable {
    case noEmailConfigured
    case invalidEmailAddress
    case contentProcessingFailed
    case emailCompositionFailed
    case sendingFailed(Error)
    case networkUnavailable
    case appGroupAccessFailed
    
    var errorDescription: String? {
        switch self {
        case .noEmailConfigured:
            return "No email address configured. Please open the main app to set up."
        case .invalidEmailAddress:
            return "Invalid email address configured."
        case .contentProcessingFailed:
            return "Failed to process shared content."
        case .emailCompositionFailed:
            return "Failed to compose email."
        case .sendingFailed(let error):
            return "Failed to send email: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable. Please check your connection."
        case .appGroupAccessFailed:
            return "Failed to access shared storage. Please reinstall the app."
        }
    }
    
    // MARK: - Equatable
    static func == (lhs: ShareEmailError, rhs: ShareEmailError) -> Bool {
        switch (lhs, rhs) {
        case (.noEmailConfigured, .noEmailConfigured),
             (.invalidEmailAddress, .invalidEmailAddress),
             (.contentProcessingFailed, .contentProcessingFailed),
             (.emailCompositionFailed, .emailCompositionFailed),
             (.networkUnavailable, .networkUnavailable),
             (.appGroupAccessFailed, .appGroupAccessFailed):
            return true
        case (.sendingFailed(let lhsError), .sendingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}