//
//  ShareEmailError.swift
//  Laplasian
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
    
    var recoverySuggestion: String? {
        switch self {
        case .noEmailConfigured:
            return "Open the main app and configure your email address in settings."
        case .invalidEmailAddress:
            return "Please check the email address format and try again."
        case .contentProcessingFailed:
            return "Try sharing the content again."
        case .emailCompositionFailed:
            return "Check if Mail app is configured on your device."
        case .sendingFailed:
            return "Check your internet connection and try again."
        case .networkUnavailable:
            return "Connect to the internet and try again."
        case .appGroupAccessFailed:
            return "Try restarting the app or reinstalling if the problem persists."
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