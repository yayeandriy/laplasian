//
//  EmailConfiguration.swift
//  Laplasian
//
//  Created by Kiro on 16.08.2025.
//

import Foundation

/// Configuration model for email settings that can be shared between main app and extension
struct EmailConfiguration: Codable {
    let recipientEmail: String
    let isConfigured: Bool
    let lastUpdated: Date
    
    init(recipientEmail: String) {
        let trimmedEmail = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        self.recipientEmail = trimmedEmail
        self.isConfigured = !trimmedEmail.isEmpty && EmailConfiguration.isValidEmailFormat(trimmedEmail)
        self.lastUpdated = Date()
    }
    
    /// Validates if the email address format is correct using comprehensive regex pattern
    var isValidEmail: Bool {
        return EmailConfiguration.isValidEmailFormat(recipientEmail)
    }
    
    /// Static method to validate email format without creating an instance
    /// - Parameter email: Email string to validate
    /// - Returns: true if email format is valid
    static func isValidEmailFormat(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return false }
        
        // Check for spaces in the email (not allowed)
        if trimmedEmail.contains(" ") { return false }
        
        // Check for consecutive dots (not allowed)
        if trimmedEmail.contains("..") { return false }
        
        // Must contain exactly one @ symbol
        let atCount = trimmedEmail.filter { $0 == "@" }.count
        guard atCount == 1 else { return false }
        
        // Split by @ to validate local and domain parts
        let parts = trimmedEmail.split(separator: "@")
        guard parts.count == 2 else { return false }
        
        let localPart = String(parts[0])
        let domainPart = String(parts[1])
        
        // Local part validation
        guard !localPart.isEmpty && !localPart.hasPrefix(".") && !localPart.hasSuffix(".") else { return false }
        
        // Domain part validation
        guard !domainPart.isEmpty && !domainPart.hasPrefix(".") && !domainPart.hasSuffix(".") else { return false }
        guard domainPart.contains(".") else { return false }
        
        // Use regex for final validation
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: trimmedEmail)
    }
    
    /// Saves this configuration to shared storage
    /// - Throws: ShareEmailError if saving fails
    func save() throws {
        try SharedStorage.shared.saveConfiguration(self)
    }
    
    /// Loads configuration from shared storage
    /// - Returns: EmailConfiguration if found, nil otherwise
    /// - Throws: ShareEmailError if loading fails
    static func load() throws -> EmailConfiguration? {
        return try SharedStorage.shared.loadConfiguration()
    }
    
    /// Removes configuration from shared storage
    /// - Throws: ShareEmailError if removal fails
    static func remove() throws {
        try SharedStorage.shared.removeConfiguration()
    }
}