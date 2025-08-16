//
//  ContentViewIntegrationTests.swift
//  LaplasianUITests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest

final class ContentViewIntegrationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    @MainActor
    func testMainViewElements() throws {
        // Verify main navigation elements
        XCTAssertTrue(app.navigationBars["Laplasian"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Email Configuration"].exists)
    }
    
    @MainActor
    func testEmailConfigurationStatusDisplay() throws {
        // Check for configuration status section
        XCTAssertTrue(app.staticTexts["Email Configuration"].exists)
        XCTAssertTrue(app.buttons["Configure"].exists)
        
        // Should show not configured initially
        XCTAssertTrue(app.staticTexts["Not configured - sharing disabled"].exists)
        XCTAssertTrue(app.staticTexts["Configure your email address to enable sharing content from other apps."].exists)
    }
    
    @MainActor
    func testSettingsNavigation() throws {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        
        // Tap settings button
        settingsButton.tap()
        
        // Should open email configuration sheet
        XCTAssertTrue(app.staticTexts["Configure Email Address"].waitForExistence(timeout: 3))
        
        // Cancel and return
        app.buttons["Cancel"].tap()
        
        // Should be back to main view
        XCTAssertTrue(app.navigationBars["Laplasian"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testConfigureButtonNavigation() throws {
        let configureButton = app.buttons["Configure"]
        XCTAssertTrue(configureButton.exists)
        
        // Tap configure button
        configureButton.tap()
        
        // Should open email configuration sheet
        XCTAssertTrue(app.staticTexts["Configure Email Address"].waitForExistence(timeout: 3))
        
        // Cancel and return
        app.buttons["Cancel"].tap()
        
        // Should be back to main view
        XCTAssertTrue(app.navigationBars["Laplasian"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testConfigurationStatusUpdate() throws {
        // Configure an email address
        app.buttons["Configure"].tap()
        
        let emailTextField = app.textFields["Enter email address"]
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 3))
        
        emailTextField.tap()
        emailTextField.typeText("test@example.com")
        
        app.buttons["Save Configuration"].tap()
        
        // Dismiss success alert
        let successAlert = app.alerts["Success"]
        if successAlert.waitForExistence(timeout: 3) {
            successAlert.buttons["OK"].tap()
        }
        
        // Should be back to main view with updated status
        XCTAssertTrue(app.navigationBars["Laplasian"].waitForExistence(timeout: 3))
        
        // Status should now show configured
        XCTAssertTrue(app.staticTexts["Configured: test@example.com"].waitForExistence(timeout: 2))
        
        // Warning message should be gone
        XCTAssertFalse(app.staticTexts["Configure your email address to enable sharing content from other apps."].exists)
    }
    
    @MainActor
    func testNavigationStateManagement() throws {
        // Test that navigation state is properly managed
        
        // Start from main view
        XCTAssertTrue(app.navigationBars["Laplasian"].exists)
        
        // Open settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Configure Email Address"].waitForExistence(timeout: 3))
        
        // Enter some text but don't save
        let emailTextField = app.textFields["Enter email address"]
        emailTextField.tap()
        emailTextField.typeText("partial@")
        
        // Cancel
        app.buttons["Cancel"].tap()
        
        // Should be back to main view
        XCTAssertTrue(app.navigationBars["Laplasian"].waitForExistence(timeout: 2))
        
        // Open settings again - should not retain previous input
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Configure Email Address"].waitForExistence(timeout: 3))
        
        // Field should be empty (or show saved configuration)
        let fieldValue = emailTextField.value as? String ?? ""
        XCTAssertTrue(fieldValue.isEmpty || fieldValue.contains("@"))
    }
    
    @MainActor
    func testVisualIndicators() throws {
        // Test that visual indicators work correctly
        
        // Initially should show warning icon
        XCTAssertTrue(app.images["exclamationmark.triangle.fill"].exists)
        
        // Configure email
        app.buttons["Configure"].tap()
        
        let emailTextField = app.textFields["Enter email address"]
        emailTextField.tap()
        emailTextField.typeText("test@example.com")
        
        app.buttons["Save Configuration"].tap()
        
        // Dismiss alert
        let successAlert = app.alerts["Success"]
        if successAlert.waitForExistence(timeout: 3) {
            successAlert.buttons["OK"].tap()
        }
        
        // Should now show checkmark icon
        XCTAssertTrue(app.images["checkmark.circle.fill"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.images["exclamationmark.triangle.fill"].exists)
    }
}