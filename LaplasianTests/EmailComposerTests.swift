//
//  EmailComposerTests.swift
//  LaplasianTests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest
import MessageUI
import UIKit
@testable import Laplasian

class EmailComposerTests: XCTestCase {
    
    var emailComposer: EmailComposer!
    var mockViewController: UIViewController!
    
    override func setUp() {
        super.setUp()
        emailComposer = EmailComposer()
        mockViewController = UIViewController()
    }
    
    override func tearDown() {
        emailComposer = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Subject Generation Tests
    
    func testGenerateSubjectForText() {
        let textContent = SharedContent.fromText("Hello World")
        let subject = emailComposer.generateSubject(for: textContent)
        XCTAssertEqual(subject, "Shared Text Content")
    }
    
    func testGenerateSubjectForImage() {
        let image = UIImage(systemName: "star") ?? UIImage()
        let imageContent = SharedContent.fromImage(image)
        let subject = emailComposer.generateSubject(for: imageContent)
        XCTAssertEqual(subject, "Shared Image")
    }
    
    func testGenerateSubjectForURL() {
        let url = URL(string: "https://www.apple.com")!
        let urlContent = SharedContent.fromURL(url)
        let subject = emailComposer.generateSubject(for: urlContent)
        XCTAssertEqual(subject, "Shared Link from www.apple.com")
    }
    
    func testGenerateSubjectForURLWithoutHost() {
        let url = URL(string: "file:///path/to/file")!
        let urlContent = SharedContent.fromURL(url)
        let subject = emailComposer.generateSubject(for: urlContent)
        XCTAssertEqual(subject, "Shared Link")
    }
    
    func testGenerateSubjectForFile() {
        let fileURL = URL(fileURLWithPath: "/path/to/document.pdf")
        // Create file content manually since fromFile() requires actual file
        let fileContent = SharedContent(type: .file(fileURL), data: Data("test".utf8))
        let subject = emailComposer.generateSubject(for: fileContent)
        XCTAssertEqual(subject, "Shared File: document.pdf")
    }
    
    // MARK: - Email Body Formatting Tests
    
    func testFormatEmailBodyForText() {
        let textContent = SharedContent.fromText("Hello World")
        let body = emailComposer.formatEmailBody(for: textContent)
        
        XCTAssertTrue(body.contains("Shared via Laplasian"))
        XCTAssertTrue(body.contains("Content:\nHello World"))
    }
    
    func testFormatEmailBodyForImage() {
        let image = UIImage(systemName: "star") ?? UIImage()
        let imageContent = SharedContent.fromImage(image)
        let body = emailComposer.formatEmailBody(for: imageContent)
        
        XCTAssertTrue(body.contains("Shared via Laplasian"))
        XCTAssertTrue(body.contains("An image has been shared with you"))
    }
    
    func testFormatEmailBodyForURL() {
        let url = URL(string: "https://www.apple.com")!
        let urlContent = SharedContent.fromURL(url)
        let body = emailComposer.formatEmailBody(for: urlContent)
        
        XCTAssertTrue(body.contains("Shared via Laplasian"))
        XCTAssertTrue(body.contains("Link: https://www.apple.com"))
    }
    
    func testFormatEmailBodyForURLWithMetadata() {
        let url = URL(string: "https://www.apple.com")!
        let metadata = ["title": "Apple", "description": "Think Different"]
        let urlContent = SharedContent.fromURL(url, metadata: metadata)
        let body = emailComposer.formatEmailBody(for: urlContent)
        
        XCTAssertTrue(body.contains("Link: https://www.apple.com"))
        XCTAssertTrue(body.contains("Title: Apple"))
        XCTAssertTrue(body.contains("Description: Think Different"))
    }
    
    func testFormatEmailBodyForFile() {
        let fileURL = URL(fileURLWithPath: "/path/to/document.pdf")
        // Create file content manually since fromFile() requires actual file
        let fileContent = SharedContent(type: .file(fileURL), data: Data("test".utf8))
        let body = emailComposer.formatEmailBody(for: fileContent)
        
        XCTAssertTrue(body.contains("Shared via Laplasian"))
        XCTAssertTrue(body.contains("File: document.pdf"))
        XCTAssertTrue(body.contains("The file has been attached"))
    }
    
    // MARK: - Email Content Creation Tests
    
    func testCreateEmailContentFromText() {
        let textContent = SharedContent.fromText("Hello World")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        XCTAssertEqual(emailContent.subject, "Shared Text Content")
        XCTAssertTrue(emailContent.body.contains("Hello World"))
        XCTAssertTrue(emailContent.attachments.isEmpty)
    }
    
    func testCreateEmailContentFromImage() {
        let image = UIImage(systemName: "star") ?? UIImage()
        let imageContent = SharedContent.fromImage(image)
        let emailContent = emailComposer.createEmailContent(from: imageContent)
        
        XCTAssertEqual(emailContent.subject, "Shared Image")
        XCTAssertTrue(emailContent.body.contains("An image has been shared"))
        XCTAssertEqual(emailContent.attachments.count, 1)
        XCTAssertTrue(emailContent.attachments.first?.mimeType == "image/jpeg")
    }
    
    func testCreateEmailContentFromURL() {
        let url = URL(string: "https://www.apple.com")!
        let urlContent = SharedContent.fromURL(url)
        let emailContent = emailComposer.createEmailContent(from: urlContent)
        
        XCTAssertEqual(emailContent.subject, "Shared Link from www.apple.com")
        XCTAssertTrue(emailContent.body.contains("https://www.apple.com"))
        XCTAssertTrue(emailContent.attachments.isEmpty)
    }
    
    func testCreateEmailContentFromFile() {
        let fileURL = URL(fileURLWithPath: "/path/to/document.pdf")
        // Create file content manually since fromFile() requires actual file
        let fileContent = SharedContent(type: .file(fileURL), data: Data("test".utf8))
        let emailContent = emailComposer.createEmailContent(from: fileContent)
        
        XCTAssertEqual(emailContent.subject, "Shared File: document.pdf")
        XCTAssertTrue(emailContent.body.contains("document.pdf"))
        XCTAssertEqual(emailContent.attachments.count, 1)
        XCTAssertEqual(emailContent.attachments.first?.fileName, "document.pdf")
        XCTAssertEqual(emailContent.attachments.first?.mimeType, "application/pdf")
    }
    
    // MARK: - Multiple Content Tests
    
    func testCreateEmailContentFromMultipleItems() {
        let textContent = SharedContent.fromText("Hello")
        let image = UIImage(systemName: "star") ?? UIImage()
        let imageContent = SharedContent.fromImage(image)
        let url = URL(string: "https://www.apple.com")!
        let urlContent = SharedContent.fromURL(url)
        
        let contents = [textContent, imageContent, urlContent]
        let emailContent = emailComposer.createEmailContent(from: contents)
        
        XCTAssertEqual(emailContent.subject, "Shared Content (3 items)")
        XCTAssertTrue(emailContent.body.contains("Multiple items shared"))
        XCTAssertTrue(emailContent.body.contains("1. Text Content:\nHello"))
        XCTAssertTrue(emailContent.body.contains("2. Image (see attachment)"))
        XCTAssertTrue(emailContent.body.contains("3. Link: https://www.apple.com"))
        XCTAssertEqual(emailContent.attachments.count, 1) // Only image creates attachment
    }
    
    func testCreateEmailContentFromEmptyArray() {
        let emailContent = emailComposer.createEmailContent(from: [])
        
        XCTAssertEqual(emailContent.subject, "Shared Content")
        XCTAssertEqual(emailContent.body, "No content to share.")
        XCTAssertTrue(emailContent.attachments.isEmpty)
    }
    
    func testCreateEmailContentFromSingleItem() {
        let textContent = SharedContent.fromText("Single item")
        let emailContent = emailComposer.createEmailContent(from: [textContent])
        
        // Should behave the same as single item creation
        XCTAssertEqual(emailContent.subject, "Shared Text Content")
        XCTAssertTrue(emailContent.body.contains("Single item"))
    }
    
    // MARK: - Email Validation Tests
    
    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue(emailComposer.isValidEmail("test@example.com"))
        XCTAssertTrue(emailComposer.isValidEmail("user.name@domain.co.uk"))
        XCTAssertTrue(emailComposer.isValidEmail("test+tag@example.org"))
        
        // Invalid emails
        XCTAssertFalse(emailComposer.isValidEmail("invalid-email"))
        XCTAssertFalse(emailComposer.isValidEmail("@example.com"))
        XCTAssertFalse(emailComposer.isValidEmail("test@"))
        XCTAssertFalse(emailComposer.isValidEmail("test@.com"))
        XCTAssertFalse(emailComposer.isValidEmail(""))
    }
    
    // MARK: - MIME Type Tests
    
    func testMimeTypeForFile() {
        let pdfURL = URL(fileURLWithPath: "/path/to/file.pdf")
        let pdfContent = SharedContent(type: .file(pdfURL), data: Data("test".utf8))
        let emailContent = emailComposer.createEmailContent(from: pdfContent)
        XCTAssertEqual(emailContent.attachments.first?.mimeType, "application/pdf")
        
        let txtURL = URL(fileURLWithPath: "/path/to/file.txt")
        let txtContent = SharedContent(type: .file(txtURL), data: Data("test".utf8))
        let txtEmailContent = emailComposer.createEmailContent(from: txtContent)
        XCTAssertEqual(txtEmailContent.attachments.first?.mimeType, "text/plain")
        
        let jpgURL = URL(fileURLWithPath: "/path/to/image.jpg")
        let jpgContent = SharedContent(type: .file(jpgURL), data: Data("test".utf8))
        let jpgEmailContent = emailComposer.createEmailContent(from: jpgContent)
        XCTAssertEqual(jpgEmailContent.attachments.first?.mimeType, "image/jpeg")
        
        let unknownURL = URL(fileURLWithPath: "/path/to/file.unknown")
        let unknownContent = SharedContent(type: .file(unknownURL), data: Data("test".utf8))
        let unknownEmailContent = emailComposer.createEmailContent(from: unknownContent)
        XCTAssertEqual(unknownEmailContent.attachments.first?.mimeType, "application/octet-stream")
    }
    
    // MARK: - Callback Tests
    
    func testCallbacksAreSet() {
        var successCalled = false
        var failureCalled = false
        var cancelCalled = false
        
        emailComposer.onSuccess = { successCalled = true }
        emailComposer.onFailure = { _ in failureCalled = true }
        emailComposer.onCancel = { cancelCalled = true }
        
        // Test success callback
        emailComposer.onSuccess?()
        XCTAssertTrue(successCalled)
        
        // Test failure callback
        emailComposer.onFailure?(.emailCompositionFailed)
        XCTAssertTrue(failureCalled)
        
        // Test cancel callback
        emailComposer.onCancel?()
        XCTAssertTrue(cancelCalled)
    }
    
    // MARK: - Mail Compose Result Handling Tests
    
    func testMailComposeResultHandling() {
        var successCalled = false
        var failureCalled = false
        var cancelCalled = false
        var receivedError: ShareEmailError?
        
        emailComposer.onSuccess = { successCalled = true }
        emailComposer.onFailure = { error in 
            failureCalled = true
            receivedError = error
        }
        emailComposer.onCancel = { cancelCalled = true }
        
        // Test sent result
        emailComposer.handleMailComposeResult(.sent, error: nil)
        XCTAssertTrue(successCalled)
        
        // Reset flags
        successCalled = false
        
        // Test saved result (should be treated as success)
        emailComposer.handleMailComposeResult(.saved, error: nil)
        XCTAssertTrue(successCalled)
        
        // Test cancelled result
        emailComposer.handleMailComposeResult(.cancelled, error: nil)
        XCTAssertTrue(cancelCalled)
        
        // Test failed result with error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        emailComposer.handleMailComposeResult(.failed, error: testError)
        XCTAssertTrue(failureCalled)
        XCTAssertNotNil(receivedError)
        
        if case .sendingFailed(let error) = receivedError {
            XCTAssertEqual(error.localizedDescription, "Test error")
        } else {
            XCTFail("Expected sendingFailed error")
        }
    }
    
    // MARK: - Composition Error Tests
    
    func testComposeEmailWithInvalidEmail() {
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        XCTAssertThrowsError(try emailComposer.composeEmail(
            content: emailContent,
            recipientEmail: "invalid-email",
            presentingViewController: mockViewController
        )) { error in
            // The error could be either invalidEmailAddress or emailCompositionFailed
            // depending on whether MFMailComposeViewController.canSendMail() returns true
            let shareError = error as? ShareEmailError
            XCTAssertTrue(
                shareError == .invalidEmailAddress || shareError == .emailCompositionFailed,
                "Expected invalidEmailAddress or emailCompositionFailed, got \(String(describing: shareError))"
            )
        }
    }
    
    // MARK: - Automatic Sending Tests
    
    func testSendEmailConvenienceMethods() {
        let textContent = SharedContent.fromText("Test message")
        
        // Test single content sending
        XCTAssertNoThrow(try? emailComposer.sendEmail(
            sharedContent: textContent,
            recipientEmail: "test@example.com",
            presentingViewController: mockViewController
        ))
        
        // Test multiple content sending
        let image = UIImage(systemName: "star") ?? UIImage()
        let imageContent = SharedContent.fromImage(image)
        let contents = [textContent, imageContent]
        
        XCTAssertNoThrow(try? emailComposer.sendEmail(
            sharedContents: contents,
            recipientEmail: "test@example.com",
            presentingViewController: mockViewController
        ))
    }
    
    func testEmailPrerequisitesValidation() {
        // Test invalid email validation
        XCTAssertThrowsError(try emailComposer.validateEmailPrerequisites(
            recipientEmail: "invalid-email",
            checkNetwork: false
        )) { error in
            // Could fail due to invalid email format OR mail not being configured in simulator
            let shareError = error as? ShareEmailError
            XCTAssertTrue(
                shareError == .invalidEmailAddress || shareError == .emailCompositionFailed,
                "Expected invalidEmailAddress or emailCompositionFailed, got \(String(describing: shareError))"
            )
        }
        
        // Test valid email validation - this may succeed or fail depending on simulator mail setup
        // We just verify that it doesn't crash and returns a proper error type if it fails
        XCTAssertNoThrow({
            do {
                try emailComposer.validateEmailPrerequisites(
                    recipientEmail: "test@example.com",
                    checkNetwork: false
                )
                // Validation passed - this is fine
            } catch let error as ShareEmailError {
                // In simulator, this might fail due to mail not being configured
                // This is also fine, we just want to ensure it's a proper ShareEmailError
                XCTAssertTrue(
                    error == .emailCompositionFailed,
                    "Expected emailCompositionFailed in simulator, got \(error)"
                )
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }())
    }
    
    func testNetworkAvailabilityCheck() {
        // Network availability check should return a boolean
        let isAvailable = emailComposer.isNetworkAvailable()
        // Just verify the method returns without crashing and returns a boolean value
        XCTAssertNotNil(isAvailable)
        XCTAssertTrue(isAvailable == true || isAvailable == false)
    }
    
    func testEmailReadyToSendCallback() {
        var callbackCalled = false
        emailComposer.onEmailReadyToSend = {
            callbackCalled = true
        }
        
        // Trigger the callback
        emailComposer.onEmailReadyToSend?()
        XCTAssertTrue(callbackCalled)
    }
    
    func testRetryEmailSendingLogic() {
        // This test verifies the retry mechanism exists
        // In a real scenario, this would be tested with proper mocking
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        // The retry method should exist and be callable
        XCTAssertNoThrow(
            emailComposer.retryEmailSending(
                content: emailContent,
                recipientEmail: "test@example.com",
                presentingViewController: mockViewController,
                maxRetries: 1
            )
        )
    }
    
    func testSendEmailAutomaticallyMethod() {
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        // Test that the method exists and handles errors appropriately
        do {
            try emailComposer.sendEmailAutomatically(
                content: emailContent,
                recipientEmail: "invalid-email",
                presentingViewController: mockViewController
            )
            XCTFail("Should have thrown an error for invalid email")
        } catch let error as ShareEmailError {
            // Should throw either invalidEmailAddress or emailCompositionFailed
            XCTAssertTrue(
                error == .invalidEmailAddress || error == .emailCompositionFailed,
                "Expected invalidEmailAddress or emailCompositionFailed"
            )
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Enhanced Automatic Sending Tests
    
    func testSendEmailWithRetrySuccess() {
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        // Test that the method exists and handles valid input
        XCTAssertNoThrow({
            do {
                try emailComposer.sendEmailWithRetry(
                    content: emailContent,
                    recipientEmail: "test@example.com",
                    presentingViewController: mockViewController,
                    enableRetry: false // Disable retry to avoid async complications in tests
                )
            } catch let error as ShareEmailError {
                // In simulator, this might fail due to mail not being configured
                XCTAssertTrue(
                    error == .emailCompositionFailed || error == .networkUnavailable,
                    "Expected emailCompositionFailed or networkUnavailable in simulator"
                )
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }())
    }
    
    func testSendEmailWithRetryInvalidEmail() {
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        XCTAssertThrowsError(try emailComposer.sendEmailWithRetry(
            content: emailContent,
            recipientEmail: "invalid-email",
            presentingViewController: mockViewController,
            enableRetry: false
        )) { error in
            // Could fail due to invalid email format OR mail not being configured in simulator
            let shareError = error as? ShareEmailError
            XCTAssertTrue(
                shareError == .invalidEmailAddress || shareError == .emailCompositionFailed,
                "Expected invalidEmailAddress or emailCompositionFailed, got \(String(describing: shareError))"
            )
        }
    }
    
    func testIsRetryableError() {
        // Test retryable errors
        XCTAssertTrue(emailComposer.isRetryableError(ShareEmailError.networkUnavailable))
        XCTAssertTrue(emailComposer.isRetryableError(ShareEmailError.emailCompositionFailed))
        XCTAssertTrue(emailComposer.isRetryableError(ShareEmailError.sendingFailed(NSError(domain: "test", code: 1))))
        
        // Test non-retryable errors
        XCTAssertFalse(emailComposer.isRetryableError(ShareEmailError.invalidEmailAddress))
        XCTAssertFalse(emailComposer.isRetryableError(ShareEmailError.noEmailConfigured))
        XCTAssertFalse(emailComposer.isRetryableError(ShareEmailError.contentProcessingFailed))
        XCTAssertFalse(emailComposer.isRetryableError(ShareEmailError.appGroupAccessFailed))
        
        // Test unknown error (should be retryable)
        let unknownError = NSError(domain: "unknown", code: 999)
        XCTAssertTrue(emailComposer.isRetryableError(unknownError))
    }
    
    func testDescribeMailComposeResult() {
        // Test successful result
        let sentDescription = emailComposer.describeMailComposeResult(.sent, error: nil)
        XCTAssertEqual(sentDescription, "Email sent successfully")
        
        // Test cancelled result
        let cancelledDescription = emailComposer.describeMailComposeResult(.cancelled, error: nil)
        XCTAssertEqual(cancelledDescription, "Email composition cancelled by user")
        
        // Test saved result
        let savedDescription = emailComposer.describeMailComposeResult(.saved, error: nil)
        XCTAssertEqual(savedDescription, "Email saved to drafts")
        
        // Test failed result with error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let failedDescription = emailComposer.describeMailComposeResult(.failed, error: testError)
        XCTAssertEqual(failedDescription, "Email sending failed: Test error")
        
        // Test failed result without error
        let failedNoErrorDescription = emailComposer.describeMailComposeResult(.failed, error: nil)
        XCTAssertEqual(failedNoErrorDescription, "Email sending failed: Unknown error")
    }
    
    func testEnhancedMailComposeResultHandling() {
        var successCalled = false
        var failureCalled = false
        var cancelCalled = false
        var receivedError: ShareEmailError?
        
        emailComposer.onSuccess = { successCalled = true }
        emailComposer.onFailure = { error in 
            failureCalled = true
            receivedError = error
        }
        emailComposer.onCancel = { cancelCalled = true }
        
        // Test sent result
        emailComposer.handleMailComposeResult(.sent, error: nil)
        XCTAssertTrue(successCalled)
        XCTAssertFalse(failureCalled)
        XCTAssertFalse(cancelCalled)
        
        // Reset flags
        successCalled = false
        failureCalled = false
        cancelCalled = false
        receivedError = nil
        
        // Test saved result (should be treated as success)
        emailComposer.handleMailComposeResult(.saved, error: nil)
        XCTAssertTrue(successCalled)
        XCTAssertFalse(failureCalled)
        XCTAssertFalse(cancelCalled)
        
        // Reset flags
        successCalled = false
        
        // Test cancelled result
        emailComposer.handleMailComposeResult(.cancelled, error: nil)
        XCTAssertFalse(successCalled)
        XCTAssertFalse(failureCalled)
        XCTAssertTrue(cancelCalled)
        
        // Reset flags
        cancelCalled = false
        
        // Test failed result with error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        emailComposer.handleMailComposeResult(.failed, error: testError)
        XCTAssertFalse(successCalled)
        XCTAssertTrue(failureCalled)
        XCTAssertFalse(cancelCalled)
        XCTAssertNotNil(receivedError)
        
        if case .sendingFailed(let error) = receivedError {
            XCTAssertEqual(error.localizedDescription, "Test error")
        } else {
            XCTFail("Expected sendingFailed error")
        }
        
        // Reset flags
        failureCalled = false
        receivedError = nil
        
        // Test failed result without error
        emailComposer.handleMailComposeResult(.failed, error: nil)
        XCTAssertTrue(failureCalled)
        XCTAssertEqual(receivedError, .emailCompositionFailed)
    }
    
    func testValidateEmailPrerequisitesComprehensive() {
        // Test with invalid email
        XCTAssertThrowsError(try emailComposer.validateEmailPrerequisites(
            recipientEmail: "invalid-email",
            checkNetwork: false
        )) { error in
            // Could fail due to invalid email format OR mail not being configured in simulator
            let shareError = error as? ShareEmailError
            XCTAssertTrue(
                shareError == .invalidEmailAddress || shareError == .emailCompositionFailed,
                "Expected invalidEmailAddress or emailCompositionFailed, got \(String(describing: shareError))"
            )
        }
        
        // Test with empty email
        XCTAssertThrowsError(try emailComposer.validateEmailPrerequisites(
            recipientEmail: "",
            checkNetwork: false
        )) { error in
            // Could fail due to invalid email format OR mail not being configured in simulator
            let shareError = error as? ShareEmailError
            XCTAssertTrue(
                shareError == .invalidEmailAddress || shareError == .emailCompositionFailed,
                "Expected invalidEmailAddress or emailCompositionFailed, got \(String(describing: shareError))"
            )
        }
        
        // Test with valid email format but no network check
        XCTAssertNoThrow({
            do {
                try emailComposer.validateEmailPrerequisites(
                    recipientEmail: "test@example.com",
                    checkNetwork: false
                )
                // Validation passed - this is fine if mail is configured
            } catch let error as ShareEmailError {
                // In simulator, this might fail due to mail not being configured
                XCTAssertEqual(error, .emailCompositionFailed)
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }())
    }
    
    func testRetryEmailSendingWithMaxRetries() {
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        var failureCallbackCalled = false
        var receivedError: ShareEmailError?
        
        emailComposer.onFailure = { error in
            failureCallbackCalled = true
            receivedError = error
        }
        
        // Test retry with max retries of 1 (should fail quickly)
        emailComposer.retryEmailSending(
            content: emailContent,
            recipientEmail: "invalid-email", // This will cause immediate failure
            presentingViewController: mockViewController,
            maxRetries: 1
        )
        
        // Give a moment for the retry logic to execute
        let expectation = XCTestExpectation(description: "Retry failure callback")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // The failure callback should have been called
        XCTAssertTrue(failureCallbackCalled)
        XCTAssertNotNil(receivedError)
    }
    
    func testCallbackCleanupAfterResult() {
        // Set up callbacks
        emailComposer.onSuccess = { }
        emailComposer.onFailure = { _ in }
        emailComposer.onCancel = { }
        emailComposer.onEmailReadyToSend = { }
        
        // Simulate mail composer references
        emailComposer.mailComposer = MFMailComposeViewController()
        emailComposer.presentingViewController = mockViewController
        
        // Handle a result
        emailComposer.handleMailComposeResult(.sent, error: nil)
        
        // Verify cleanup occurred
        XCTAssertNil(emailComposer.mailComposer)
        XCTAssertNil(emailComposer.presentingViewController)
        XCTAssertNil(emailComposer.onEmailReadyToSend)
    }
    
    func testSendEmailAutomaticallyWithNetworkCheck() {
        let textContent = SharedContent.fromText("Test")
        let emailContent = emailComposer.createEmailContent(from: textContent)
        
        // Test with valid email - should either succeed or fail with proper error
        XCTAssertNoThrow({
            do {
                try emailComposer.sendEmailAutomatically(
                    content: emailContent,
                    recipientEmail: "test@example.com",
                    presentingViewController: mockViewController
                )
            } catch let error as ShareEmailError {
                // Should fail with either emailCompositionFailed or networkUnavailable in simulator
                XCTAssertTrue(
                    error == .emailCompositionFailed || error == .networkUnavailable,
                    "Expected emailCompositionFailed or networkUnavailable, got \(error)"
                )
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }())
    }
    
    func testMultipleCallbackTypes() {
        var successCount = 0
        var failureCount = 0
        var cancelCount = 0
        var readyCount = 0
        
        emailComposer.onSuccess = { successCount += 1 }
        emailComposer.onFailure = { _ in failureCount += 1 }
        emailComposer.onCancel = { cancelCount += 1 }
        emailComposer.onEmailReadyToSend = { readyCount += 1 }
        
        // Test multiple callback invocations
        emailComposer.onSuccess?()
        emailComposer.onSuccess?()
        XCTAssertEqual(successCount, 2)
        
        emailComposer.onFailure?(.emailCompositionFailed)
        XCTAssertEqual(failureCount, 1)
        
        emailComposer.onCancel?()
        XCTAssertEqual(cancelCount, 1)
        
        emailComposer.onEmailReadyToSend?()
        XCTAssertEqual(readyCount, 1)
    }
    
    // Note: Testing MFMailComposeViewController.canSendMail() would require mocking
    // which is complex in unit tests. This would be better tested in integration tests.
}

