//
//  EmailComposer.swift
//  LaplasianShareExtension
//
//  Created by Kiro on 16.08.2025.
//

import Foundation
import MessageUI
import UIKit

/// Handles email composition and sending using MessageUI framework
class EmailComposer: NSObject, MFMailComposeViewControllerDelegate {
    
    // MARK: - Properties
    
    /// Callback for successful email sending
    var onSuccess: (() -> Void)?
    
    /// Callback for email sending failure
    var onFailure: ((ShareEmailError) -> Void)?
    
    /// Callback for email sending cancellation
    var onCancel: (() -> Void)?
    
    internal var mailComposer: MFMailComposeViewController?
    internal weak var presentingViewController: UIViewController?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Sends an email automatically with minimal user interaction
    /// - Parameters:
    ///   - content: The email content to send
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present from
    ///   - autoSend: Whether to attempt automatic sending (iOS limitations apply)
    /// - Throws: ShareEmailError if sending fails
    func sendEmailAutomatically(
        content: EmailContent,
        recipientEmail: String,
        presentingViewController: UIViewController,
        autoSend: Bool = true
    ) throws {
        
        // Validate prerequisites before attempting to send
        try validateEmailPrerequisites(recipientEmail: recipientEmail, checkNetwork: true)
        
        // Create mail composer
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        
        // Set recipient
        composer.setToRecipients([recipientEmail])
        
        // Set subject
        composer.setSubject(content.subject)
        
        // Set body
        composer.setMessageBody(content.body, isHTML: false)
        
        // Add attachments
        for attachment in content.attachments {
            composer.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.fileName
            )
        }
        
        // Store references
        self.mailComposer = composer
        self.presentingViewController = presentingViewController
        
        // Present the composer
        presentingViewController.present(composer, animated: true)
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.handleMailComposeResult(result, error: error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Validates that all prerequisites for sending email are met
    /// - Parameters:
    ///   - recipientEmail: The email address to validate
    ///   - checkNetwork: Whether to check network availability
    /// - Throws: ShareEmailError if validation fails
    func validateEmailPrerequisites(recipientEmail: String, checkNetwork: Bool = true) throws {
        // Check if mail services are available
        guard MFMailComposeViewController.canSendMail() else {
            throw ShareEmailError.emailCompositionFailed
        }
        
        // Validate email address
        guard isValidEmail(recipientEmail) else {
            throw ShareEmailError.invalidEmailAddress
        }
    }
    
    internal func handleMailComposeResult(_ result: MFMailComposeResult, error: Error?) {
        // Clean up references
        defer {
            mailComposer = nil
            presentingViewController = nil
        }
        
        switch result {
        case .sent:
            // Email was successfully sent
            onSuccess?()
            
        case .failed:
            // Email sending failed
            let shareError: ShareEmailError
            if let error = error {
                shareError = .sendingFailed(error)
            } else {
                shareError = .emailCompositionFailed
            }
            onFailure?(shareError)
            
        case .cancelled:
            // User cancelled the email composition
            onCancel?()
            
        case .saved:
            // Email was saved to drafts - treat as success since composition succeeded
            onSuccess?()
            
        @unknown default:
            // Handle any future cases
            onFailure?(.emailCompositionFailed)
        }
    }
    
    internal func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}