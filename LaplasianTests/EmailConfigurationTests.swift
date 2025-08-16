//
//  EmailConfigurationTests.swift
//  LaplasianTests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest
@testable import Laplasian

final class EmailConfigurationTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        // Clean up any test configurations
        try? EmailConfiguration.remove()
    }
    
    func testEmailConfigurationInit() {
        let email = "test@example.com"
        let config = EmailConfiguration(recipientEmail: email)
        
        XCTAssertEqual(config.recipientEmail, email)
        XCTAssertTrue(config.isConfigured)
        XCTAssertNotNil(config.lastUpdated)
    }
    
    func testEmailConfigurationInitWithWhitespace() {
        let email = "  test@example.com  "
        let config = EmailConfiguration(recipientEmail: email)
        
        XCTAssertEqual(config.recipientEmail, "test@example.com")
        XCTAssertTrue(config.isConfigured)
    }
    
    func testEmptyEmailConfiguration() {
        let config = EmailConfiguration(recipientEmail: "")
        
        XCTAssertEqual(config.recipientEmail, "")
        XCTAssertFalse(config.isConfigured)
    }
    
    func testInvalidEmailConfiguration() {
        let config = EmailConfiguration(recipientEmail: "invalid-email")
        
        XCTAssertEqual(config.recipientEmail, "invalid-email")
        XCTAssertFalse(config.isConfigured)
    }
    
    func testValidEmailValidation() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org",
            "123@test.com",
            "user_name@example-domain.com",
            "test.email+tag@example.co.uk"
        ]
        
        for email in validEmails {
            let config = EmailConfiguration(recipientEmail: email)
            XCTAssertTrue(config.isValidEmail, "Email \(email) should be valid")
            XCTAssertTrue(EmailConfiguration.isValidEmailFormat(email), "Static validation should also pass for \(email)")
        }
    }
    
    func testInvalidEmailValidation() {
        let invalidEmails = [
            "",
            "invalid",
            "@example.com",
            "test@",
            "test.example.com",
            "test@.com",
            "test@com",
            "test..test@example.com",
            "test@example.",
            "test @example.com",
            "test@ex ample.com"
        ]
        
        for email in invalidEmails {
            let config = EmailConfiguration(recipientEmail: email)
            XCTAssertFalse(config.isValidEmail, "Email \(email) should be invalid")
            XCTAssertFalse(EmailConfiguration.isValidEmailFormat(email), "Static validation should also fail for \(email)")
        }
    }
    
    func testStaticEmailValidation() {
        XCTAssertTrue(EmailConfiguration.isValidEmailFormat("test@example.com"))
        XCTAssertTrue(EmailConfiguration.isValidEmailFormat("  test@example.com  "))
        XCTAssertFalse(EmailConfiguration.isValidEmailFormat(""))
        XCTAssertFalse(EmailConfiguration.isValidEmailFormat("   "))
        XCTAssertFalse(EmailConfiguration.isValidEmailFormat("invalid"))
    }
    
    func testCodableConformance() throws {
        let originalConfig = EmailConfiguration(recipientEmail: "test@example.com")
        
        // Encode
        let data = try JSONEncoder().encode(originalConfig)
        XCTAssertFalse(data.isEmpty)
        
        // Decode
        let decodedConfig = try JSONDecoder().decode(EmailConfiguration.self, from: data)
        
        XCTAssertEqual(originalConfig.recipientEmail, decodedConfig.recipientEmail)
        XCTAssertEqual(originalConfig.isConfigured, decodedConfig.isConfigured)
    }
    
    func testPersistenceMethods() throws {
        let config = EmailConfiguration(recipientEmail: "test@example.com")
        
        // Test save
        try config.save()
        
        // Test load
        let loadedConfig = try EmailConfiguration.load()
        XCTAssertNotNil(loadedConfig)
        XCTAssertEqual(loadedConfig?.recipientEmail, config.recipientEmail)
        XCTAssertEqual(loadedConfig?.isConfigured, config.isConfigured)
        
        // Test remove
        try EmailConfiguration.remove()
        let removedConfig = try EmailConfiguration.load()
        XCTAssertNil(removedConfig)
    }
    
    func testLoadNonExistentConfiguration() throws {
        // Ensure no configuration exists
        try? EmailConfiguration.remove()
        
        let config = try EmailConfiguration.load()
        XCTAssertNil(config)
    }
}