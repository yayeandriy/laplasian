//
//  SettingsManager.swift
//  LaplasianShareExtension
//
//  Created by Kiro on 16.08.2025.
//

import Foundation

/// Email configuration data model
struct EmailConfiguration: Codable {
    let recipientEmail: String
    let isConfigured: Bool
    let lastUpdated: Date
    
    init(recipientEmail: String) {
        self.recipientEmail = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isConfigured = !self.recipientEmail.isEmpty && Self.isValidEmailFormat(self.recipientEmail)
        self.lastUpdated = Date()
    }
    
    var isValidEmail: Bool {
        return isConfigured && Self.isValidEmailFormat(recipientEmail)
    }
    
    static func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

/// Shared storage for app group communication
class SharedStorage {
    static let shared = SharedStorage()
    
    private let appGroupIdentifier = "group.operators.yayeandriy.Laplasian"
    private let configurationKey = "EmailConfiguration"
    
    private init() {}
    
    /// Gets the shared container URL for the app group
    /// - Returns: URL of the shared container
    /// - Throws: ShareEmailError if container access fails
    func getSharedContainer() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw ShareEmailError.appGroupAccessFailed
        }
        return containerURL
    }
    
    /// Saves email configuration to shared storage
    /// - Parameter configuration: The configuration to save
    /// - Throws: ShareEmailError if saving fails
    func saveConfiguration(_ configuration: EmailConfiguration) throws {
        let containerURL = try getSharedContainer()
        let configURL = containerURL.appendingPathComponent("\(configurationKey).json")
        
        do {
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: configURL)
        } catch {
            throw ShareEmailError.appGroupAccessFailed
        }
    }
    
    /// Loads email configuration from shared storage
    /// - Returns: The loaded configuration or nil if not found
    /// - Throws: ShareEmailError if loading fails
    func loadConfiguration() throws -> EmailConfiguration? {
        let containerURL = try getSharedContainer()
        let configURL = containerURL.appendingPathComponent("\(configurationKey).json")
        
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            return try JSONDecoder().decode(EmailConfiguration.self, from: data)
        } catch {
            throw ShareEmailError.appGroupAccessFailed
        }
    }
    
    /// Checks if configuration exists and is valid
    /// - Returns: true if configured, false otherwise
    func isConfigured() -> Bool {
        do {
            if let config = try loadConfiguration() {
                return config.isConfigured
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Removes the configuration from shared storage
    /// - Throws: ShareEmailError if removal fails
    func removeConfiguration() throws {
        let containerURL = try getSharedContainer()
        let configURL = containerURL.appendingPathComponent("\(configurationKey).json")
        
        if FileManager.default.fileExists(atPath: configURL.path) {
            do {
                try FileManager.default.removeItem(at: configURL)
            } catch {
                throw ShareEmailError.appGroupAccessFailed
            }
        }
    }
}

/// Manages app settings and coordinates with shared storage
class SettingsManager {
    private let sharedStorage = SharedStorage.shared
    
    init() {}
    
    /// Gets the currently configured email address
    /// - Returns: Email address string or nil if not configured
    func getEmailAddress() -> String? {
        do {
            return try sharedStorage.loadConfiguration()?.recipientEmail
        } catch {
            return nil
        }
    }
    
    /// Checks if the app is configured with a valid email
    var isConfigured: Bool {
        return sharedStorage.isConfigured()
    }
    
    /// Checks if the current configuration is valid and up to date
    /// - Returns: true if configuration exists and is valid
    func isConfigurationValid() -> Bool {
        do {
            guard let config = try sharedStorage.loadConfiguration() else { return false }
            return config.isConfigured && config.isValidEmail
        } catch {
            return false
        }
    }
}