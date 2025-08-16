//
//  SettingsManager.swift
//  Laplasian
//
//  Created by Kiro on 16.08.2025.
//

import Foundation
import SwiftUI

/// Manages app settings and coordinates with shared storage
@MainActor
class SettingsManager: ObservableObject {
    @Published var currentConfiguration: EmailConfiguration?
    @Published var isConfigured: Bool = false
    @Published var lastError: ShareEmailError?
    
    private let sharedStorage = SharedStorage.shared
    
    init() {
        loadConfiguration()
    }
    
    /// Loads configuration from shared storage
    func loadConfiguration() {
        do {
            currentConfiguration = try sharedStorage.loadConfiguration()
            isConfigured = sharedStorage.isConfigured()
        } catch let error as ShareEmailError {
            lastError = error
            currentConfiguration = nil
            isConfigured = false
        } catch {
            lastError = ShareEmailError.appGroupAccessFailed
            currentConfiguration = nil
            isConfigured = false
        }
    }
    
    /// Saves email address configuration
    /// - Parameter emailAddress: The email address to configure
    /// - Returns: true if saved successfully, false otherwise
    func saveEmailAddress(_ emailAddress: String) -> Bool {
        let configuration = EmailConfiguration(recipientEmail: emailAddress.trimmingCharacters(in: .whitespacesAndNewlines))
        
        guard configuration.isValidEmail else {
            lastError = ShareEmailError.invalidEmailAddress
            return false
        }
        
        do {
            try sharedStorage.saveConfiguration(configuration)
            currentConfiguration = configuration
            isConfigured = true
            lastError = nil
            return true
        } catch let error as ShareEmailError {
            lastError = error
            return false
        } catch {
            lastError = ShareEmailError.appGroupAccessFailed
            return false
        }
    }
    
    /// Gets the currently configured email address
    /// - Returns: Email address string or nil if not configured
    func getEmailAddress() -> String? {
        return currentConfiguration?.recipientEmail
    }
    
    /// Removes the current configuration
    /// - Returns: true if removed successfully, false otherwise
    func removeConfiguration() -> Bool {
        do {
            try sharedStorage.removeConfiguration()
            currentConfiguration = nil
            isConfigured = false
            lastError = nil
            return true
        } catch let error as ShareEmailError {
            lastError = error
            return false
        } catch {
            lastError = ShareEmailError.appGroupAccessFailed
            return false
        }
    }
    
    /// Validates an email address format
    /// - Parameter email: Email address to validate
    /// - Returns: true if valid format, false otherwise
    func isValidEmailFormat(_ email: String) -> Bool {
        return EmailConfiguration.isValidEmailFormat(email)
    }
    
    /// Checks if the current configuration is valid and up to date
    /// - Returns: true if configuration exists and is valid
    func isConfigurationValid() -> Bool {
        guard let config = currentConfiguration else { return false }
        return config.isConfigured && config.isValidEmail
    }
    
    /// Refreshes the configuration status from shared storage
    func refreshConfiguration() {
        loadConfiguration()
    }
    
    /// Clears the last error
    func clearError() {
        lastError = nil
    }
}