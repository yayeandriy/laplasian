//
//  SharedStorage.swift
//  Laplasian
//
//  Created by Kiro on 16.08.2025.
//

import Foundation

/// Manages shared storage between main app and share extension using App Groups
class SharedStorage {
    static let shared = SharedStorage()
    
    /// App Group identifier - must match the one configured in project capabilities
    private let appGroupIdentifier = "group.operators.yayeandriy.Laplasian"
    
    /// Configuration file name in shared container
    private let configurationFileName = "email-configuration.json"
    
    private init() {}
    
    /// Returns the shared container URL for the App Group
    /// - Returns: URL of the shared container or nil if App Group is not configured
    func getSharedContainer() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    /// Saves email configuration to shared storage
    /// - Parameter configuration: EmailConfiguration to save
    /// - Throws: ShareEmailError if saving fails
    func saveConfiguration(_ configuration: EmailConfiguration) throws {
        guard let containerURL = getSharedContainer() else {
            throw ShareEmailError.appGroupAccessFailed
        }
        
        let configurationURL = containerURL.appendingPathComponent(configurationFileName)
        
        do {
            let data = try JSONEncoder().encode(configuration)
            try data.write(to: configurationURL)
        } catch {
            throw ShareEmailError.appGroupAccessFailed
        }
    }
    
    /// Loads email configuration from shared storage
    /// - Returns: EmailConfiguration if found, nil otherwise
    /// - Throws: ShareEmailError if loading fails
    func loadConfiguration() throws -> EmailConfiguration? {
        guard let containerURL = getSharedContainer() else {
            throw ShareEmailError.appGroupAccessFailed
        }
        
        let configurationURL = containerURL.appendingPathComponent(configurationFileName)
        
        guard FileManager.default.fileExists(atPath: configurationURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configurationURL)
            return try JSONDecoder().decode(EmailConfiguration.self, from: data)
        } catch {
            throw ShareEmailError.appGroupAccessFailed
        }
    }
    
    /// Checks if email configuration exists and is valid
    /// - Returns: true if configuration exists and is valid
    func isConfigured() -> Bool {
        do {
            guard let configuration = try loadConfiguration() else {
                return false
            }
            return configuration.isConfigured && configuration.isValidEmail
        } catch {
            return false
        }
    }
    
    /// Removes configuration from shared storage
    /// - Throws: ShareEmailError if removal fails
    func removeConfiguration() throws {
        guard let containerURL = getSharedContainer() else {
            throw ShareEmailError.appGroupAccessFailed
        }
        
        let configurationURL = containerURL.appendingPathComponent(configurationFileName)
        
        if FileManager.default.fileExists(atPath: configurationURL.path) {
            do {
                try FileManager.default.removeItem(at: configurationURL)
            } catch {
                throw ShareEmailError.appGroupAccessFailed
            }
        }
    }
}