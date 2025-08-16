//
//  SharedStorageTests.swift
//  LaplasianTests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest
@testable import Laplasian

final class SharedStorageTests: XCTestCase {
    
    var sharedStorage: SharedStorage!
    
    override func setUpWithError() throws {
        sharedStorage = SharedStorage.shared
        // Clean up any existing configuration
        try? sharedStorage.removeConfiguration()
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        try? sharedStorage.removeConfiguration()
    }
    
    func testSharedContainerAccess() throws {
        // Test that we can access the shared container
        let containerURL = sharedStorage.getSharedContainer()
        XCTAssertNotNil(containerURL, "Should be able to access shared container")
    }
    
    func testSaveAndLoadConfiguration() throws {
        // Test saving and loading configuration
        let testEmail = "test@example.com"
        let configuration = EmailConfiguration(recipientEmail: testEmail)
        
        // Save configuration
        XCTAssertNoThrow(try sharedStorage.saveConfiguration(configuration))
        
        // Load configuration
        let loadedConfiguration = try sharedStorage.loadConfiguration()
        XCTAssertNotNil(loadedConfiguration)
        XCTAssertEqual(loadedConfiguration?.recipientEmail, testEmail)
        XCTAssertTrue(loadedConfiguration?.isConfigured ?? false)
    }
    
    func testIsConfigured() throws {
        // Initially should not be configured
        XCTAssertFalse(sharedStorage.isConfigured())
        
        // Save valid configuration
        let configuration = EmailConfiguration(recipientEmail: "test@example.com")
        try sharedStorage.saveConfiguration(configuration)
        
        // Should now be configured
        XCTAssertTrue(sharedStorage.isConfigured())
    }
    
    func testRemoveConfiguration() throws {
        // Save configuration first
        let configuration = EmailConfiguration(recipientEmail: "test@example.com")
        try sharedStorage.saveConfiguration(configuration)
        XCTAssertTrue(sharedStorage.isConfigured())
        
        // Remove configuration
        XCTAssertNoThrow(try sharedStorage.removeConfiguration())
        XCTAssertFalse(sharedStorage.isConfigured())
        
        // Should return nil when loading
        let loadedConfiguration = try sharedStorage.loadConfiguration()
        XCTAssertNil(loadedConfiguration)
    }
}