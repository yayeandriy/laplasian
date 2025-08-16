//
//  SettingsManagerTests.swift
//  LaplasianTests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest
@testable import Laplasian

@MainActor
final class SettingsManagerTests: XCTestCase {
    
    var settingsManager: SettingsManager!
    
    override func setUp() async throws {
        try await super.setUp()
        settingsManager = SettingsManager()
        // Clean up any existing configuration
        _ = settingsManager.removeConfiguration()
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        _ = settingsManager.removeConfiguration()
        settingsManager = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        // When creating a new SettingsManager without existing configuration
        // Then it should not be configured
        XCTAssertFalse(settingsManager.isConfigured)
        XCTAssertNil(settingsManager.currentConfiguration)
        XCTAssertNil(settingsManager.getEmailAddress())
    }
    
    func testSaveValidEmailAddress() {
        let validEmail = "test@example.com"
        
        let result = settingsManager.saveEmailAddress(validEmail)
        
        XCTAssertTrue(result)
        XCTAssertTrue(settingsManager.isConfigured)
        XCTAssertNotNil(settingsManager.currentConfiguration)
        XCTAssertEqual(settingsManager.getEmailAddress(), validEmail)
        XCTAssertNil(settingsManager.lastError)
    }
    
    func testSaveInvalidEmailAddress() {
        let invalidEmail = "invalid-email"
        
        let result = settingsManager.saveEmailAddress(invalidEmail)
        
        XCTAssertFalse(result)
        XCTAssertFalse(settingsManager.isConfigured)
        XCTAssertNil(settingsManager.currentConfiguration)
        XCTAssertNil(settingsManager.getEmailAddress())
        XCTAssertEqual(settingsManager.lastError, ShareEmailError.invalidEmailAddress)
    }
    
    func testSaveEmailWithWhitespace() {
        let emailWithWhitespace = "  test@example.com  "
        let expectedEmail = "test@example.com"
        
        let result = settingsManager.saveEmailAddress(emailWithWhitespace)
        
        XCTAssertTrue(result)
        XCTAssertTrue(settingsManager.isConfigured)
        XCTAssertEqual(settingsManager.getEmailAddress(), expectedEmail)
    }
    
    func testRemoveConfiguration() {
        // First save a configuration
        _ = settingsManager.saveEmailAddress("test@example.com")
        XCTAssertTrue(settingsManager.isConfigured)
        
        // Then remove it
        let result = settingsManager.removeConfiguration()
        
        XCTAssertTrue(result)
        XCTAssertFalse(settingsManager.isConfigured)
        XCTAssertNil(settingsManager.currentConfiguration)
        XCTAssertNil(settingsManager.getEmailAddress())
        XCTAssertNil(settingsManager.lastError)
    }
    
    func testEmailValidation() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org"
        ]
        
        let invalidEmails = [
            "",
            "invalid",
            "@example.com",
            "test@",
            "test.example.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(settingsManager.isValidEmailFormat(email), "Email \(email) should be valid")
        }
        
        for email in invalidEmails {
            XCTAssertFalse(settingsManager.isValidEmailFormat(email), "Email \(email) should be invalid")
        }
    }
    
    func testConfigurationValidation() {
        // Initially should not be valid
        XCTAssertFalse(settingsManager.isConfigurationValid())
        
        // After saving valid email should be valid
        _ = settingsManager.saveEmailAddress("test@example.com")
        XCTAssertTrue(settingsManager.isConfigurationValid())
        
        // After removing should not be valid
        _ = settingsManager.removeConfiguration()
        XCTAssertFalse(settingsManager.isConfigurationValid())
    }
    
    func testLoadConfiguration() {
        let testEmail = "test@example.com"
        
        // Save configuration
        _ = settingsManager.saveEmailAddress(testEmail)
        
        // Create new settings manager to test loading
        let newSettingsManager = SettingsManager()
        
        XCTAssertTrue(newSettingsManager.isConfigured)
        XCTAssertEqual(newSettingsManager.getEmailAddress(), testEmail)
        XCTAssertTrue(newSettingsManager.isConfigurationValid())
    }
    
    func testRefreshConfiguration() {
        let testEmail = "test@example.com"
        
        // Save configuration using shared storage directly
        let config = EmailConfiguration(recipientEmail: testEmail)
        try? SharedStorage.shared.saveConfiguration(config)
        
        // Refresh configuration in settings manager
        settingsManager.refreshConfiguration()
        
        XCTAssertTrue(settingsManager.isConfigured)
        XCTAssertEqual(settingsManager.getEmailAddress(), testEmail)
    }
    
    func testClearError() {
        // Trigger an error
        _ = settingsManager.saveEmailAddress("invalid-email")
        XCTAssertNotNil(settingsManager.lastError)
        
        // Clear the error
        settingsManager.clearError()
        XCTAssertNil(settingsManager.lastError)
    }
}