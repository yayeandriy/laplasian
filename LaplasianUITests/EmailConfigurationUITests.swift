//
//  EmailConfigurationUITests.swift
//  LaplasianUITests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest

final class EmailConfigurationUITests: XCTestCase {
    
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
    func testEmailConfigurationViewElements() throws {
        // Navigate to email configuration view
        navigateToEmailConfiguration()
        
        // Verify main UI elements exist
        XCTAssertTrue(app.staticTexts["Configure Email Address"].exists)
        XCTAssertTrue(app.staticTexts["Set the email address where shared content will be sent automatically."].exists)
        XCTAssertTrue(app.staticTexts["Email Address"].exists)
        XCTAssertTrue(app.textFields["Enter email address"].exists)
        XCTAssertTrue(app.buttons["Save Configuration"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }
    
    @MainActor
    func testEmailValidationFeedback() throws {
        navigateToEmailConfiguration()
        
        let emailTextField = app.textFields["Enter email address"]
        
        // Test invalid email
        emailTextField.tap()
        emailTextField.typeText("invalid-email")
        
        // Check for validation feedback
        XCTAssertTrue(app.staticTexts["Invalid email format"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.images["xmark.circle.fill"].exists)
        
        // Clear and test valid email
        emailTextField.clearAndEnterText("test@example.com")
        
        // Check for positive validation feedback
        XCTAssertTrue(app.staticTexts["Valid email address"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.images["checkmark.circle.fill"].exists)
    }
    
    @MainActor
    func testSaveButtonState() throws {
        navigateToEmailConfiguration()
        
        let emailTextField = app.textFields["Enter email address"]
        let saveButton = app.buttons["Save Configuration"]
        
        // Save button should be disabled initially
        XCTAssertFalse(saveButton.isEnabled)
        
        // Enter invalid email - save should remain disabled
        emailTextField.tap()
        emailTextField.typeText("invalid")
        XCTAssertFalse(saveButton.isEnabled)
        
        // Enter valid email - save should be enabled
        emailTextField.clearAndEnterText("test@example.com")
        XCTAssertTrue(saveButton.isEnabled)
    }
    
    @MainActor
    func testSuccessfulEmailConfiguration() throws {
        navigateToEmailConfiguration()
        
        let emailTextField = app.textFields["Enter email address"]
        let saveButton = app.buttons["Save Configuration"]
        
        // Enter valid email and save
        emailTextField.tap()
        emailTextField.typeText("test@example.com")
        saveButton.tap()
        
        // Check for success alert
        let successAlert = app.alerts["Success"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 3))
        XCTAssertTrue(successAlert.staticTexts["Email configuration saved successfully!"].exists)
        
        // Dismiss alert
        successAlert.buttons["OK"].tap()
        
        // Should return to previous view
        XCTAssertFalse(app.staticTexts["Configure Email Address"].exists)
    }
    
    @MainActor
    func testCancelButton() throws {
        navigateToEmailConfiguration()
        
        let emailTextField = app.textFields["Enter email address"]
        let cancelButton = app.buttons["Cancel"]
        
        // Enter some text
        emailTextField.tap()
        emailTextField.typeText("test@example.com")
        
        // Tap cancel
        cancelButton.tap()
        
        // Should return to previous view without saving
        XCTAssertFalse(app.staticTexts["Configure Email Address"].exists)
    }
    
    @MainActor
    func testRemoveConfigurationButton() throws {
        // First configure an email
        navigateToEmailConfiguration()
        
        let emailTextField = app.textFields["Enter email address"]
        let saveButton = app.buttons["Save Configuration"]
        
        emailTextField.tap()
        emailTextField.typeText("test@example.com")
        saveButton.tap()
        
        // Dismiss success alert
        let successAlert = app.alerts["Success"]
        if successAlert.waitForExistence(timeout: 3) {
            successAlert.buttons["OK"].tap()
        }
        
        // Navigate back to configuration
        navigateToEmailConfiguration()
        
        // Remove configuration button should now be visible
        let removeButton = app.buttons["Remove Configuration"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 2))
        
        removeButton.tap()
        
        // Email field should be cleared
        let emailField = app.textFields["Enter email address"]
        XCTAssertEqual(emailField.value as? String ?? "", "")
    }
    
    @MainActor
    func testRealTimeValidation() throws {
        navigateToEmailConfiguration()
        
        let emailTextField = app.textFields["Enter email address"]
        emailTextField.tap()
        
        // Test progressive typing with validation
        emailTextField.typeText("t")
        XCTAssertTrue(app.staticTexts["Invalid email format"].waitForExistence(timeout: 1))
        
        emailTextField.typeText("est@")
        XCTAssertTrue(app.staticTexts["Invalid email format"].exists)
        
        emailTextField.typeText("example.com")
        XCTAssertTrue(app.staticTexts["Valid email address"].waitForExistence(timeout: 1))
    }
    
    // MARK: - Helper Methods
    
    private func navigateToEmailConfiguration() {
        // Tap the Settings button in the toolbar
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()
        
        // Wait for the configuration view to appear
        XCTAssertTrue(app.staticTexts["Configure Email Address"].waitForExistence(timeout: 5))
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard self.exists else { return }
        
        self.tap()
        self.press(forDuration: 1.0)
        
        let selectAllMenuItem = XCUIApplication().menuItems["Select All"]
        if selectAllMenuItem.exists {
            selectAllMenuItem.tap()
        }
        
        self.typeText(text)
    }
}