//
//  EmailComposer.swift
//  Laplasian
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
    
    /// Composes an email with the provided content and attachments
    /// - Parameters:
    ///   - content: The email content including subject, body, and attachments
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present the mail composer from
    /// - Throws: ShareEmailError if composition fails
    func composeEmail(
        content: EmailContent,
        recipientEmail: String,
        presentingViewController: UIViewController
    ) throws {
        
        // Check if mail services are available
        guard MFMailComposeViewController.canSendMail() else {
            throw ShareEmailError.emailCompositionFailed
        }
        
        // Validate email address
        guard isValidEmail(recipientEmail) else {
            throw ShareEmailError.invalidEmailAddress
        }
        
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
    
    /// Generates appropriate email subject based on content type
    /// - Parameter sharedContent: The shared content to generate subject for
    /// - Returns: Generated email subject
    func generateSubject(for sharedContent: SharedContent) -> String {
        switch sharedContent.type {
        case .text:
            return "Shared Text Content"
        case .image:
            return "Shared Image"
        case .url(let url):
            if let host = url.host {
                return "Shared Link from \(host)"
            } else {
                return "Shared Link"
            }
        case .file(let fileURL):
            return "Shared File: \(fileURL.lastPathComponent)"
        }
    }
    
    /// Formats email body based on content type
    /// - Parameter sharedContent: The shared content to format
    /// - Returns: Formatted email body
    func formatEmailBody(for sharedContent: SharedContent) -> String {
        let timestamp = DateFormatter.emailTimestamp.string(from: Date())
        let header = "Shared via Laplasian on \(timestamp)\n\n"
        
        switch sharedContent.type {
        case .text(let text):
            return header + "Content:\n\(text)"
            
        case .image:
            return header + "An image has been shared with you. Please see the attachment."
            
        case .url(let url):
            var body = header + "Link: \(url.absoluteString)\n"
            
            // Add metadata if available
            if let metadata = sharedContent.metadata,
               let title = metadata["title"] as? String {
                body += "Title: \(title)\n"
            }
            
            if let metadata = sharedContent.metadata,
               let description = metadata["description"] as? String {
                body += "Description: \(description)\n"
            }
            
            return body
            
        case .file(let fileURL):
            let fileName = fileURL.lastPathComponent
            let fileSize = sharedContent.data.count
            let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            
            return header + "File: \(fileName)\nSize: \(fileSizeString)\n\nThe file has been attached to this email."
        }
    }
    
    /// Creates EmailContent from SharedContent
    /// - Parameter sharedContent: The shared content to convert
    /// - Returns: EmailContent ready for composition
    func createEmailContent(from sharedContent: SharedContent) -> EmailContent {
        let subject = generateSubject(for: sharedContent)
        let body = formatEmailBody(for: sharedContent)
        
        var attachments: [EmailAttachment] = []
        
        // Create attachments based on content type
        switch sharedContent.type {
        case .text:
            // Text content goes in body, no attachment needed
            break
            
        case .image(let image):
            let attachment = EmailAttachment.fromImage(image)
            attachments.append(attachment)
            
        case .url:
            // URL content goes in body, no attachment needed
            break
            
        case .file(let fileURL):
            let fileName = fileURL.lastPathComponent
            let mimeType = mimeTypeForFile(at: fileURL)
            let attachment = EmailAttachment(
                data: sharedContent.data,
                mimeType: mimeType,
                fileName: fileName
            )
            attachments.append(attachment)
        }
        
        return EmailContent(subject: subject, body: body, attachments: attachments)
    }
    
    /// Sends an email automatically with minimal user interaction
    /// - Parameters:
    ///   - content: The email content to send
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present from
    /// - Throws: ShareEmailError if sending fails
    func sendEmail(
        content: EmailContent,
        recipientEmail: String,
        presentingViewController: UIViewController
    ) throws {
        // This method provides the same functionality as composeEmail
        // but is named to indicate automatic sending intent
        try composeEmail(
            content: content,
            recipientEmail: recipientEmail,
            presentingViewController: presentingViewController
        )
    }
    
    /// Convenience method to send email from SharedContent
    /// - Parameters:
    ///   - sharedContent: The content to share
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present from
    /// - Throws: ShareEmailError if sending fails
    func sendEmail(
        sharedContent: SharedContent,
        recipientEmail: String,
        presentingViewController: UIViewController
    ) throws {
        let emailContent = createEmailContent(from: sharedContent)
        try sendEmail(
            content: emailContent,
            recipientEmail: recipientEmail,
            presentingViewController: presentingViewController
        )
    }
    
    /// Convenience method to send email from multiple SharedContent items
    /// - Parameters:
    ///   - sharedContents: Array of content to share
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present from
    /// - Throws: ShareEmailError if sending fails
    func sendEmail(
        sharedContents: [SharedContent],
        recipientEmail: String,
        presentingViewController: UIViewController
    ) throws {
        let emailContent = createEmailContent(from: sharedContents)
        try sendEmail(
            content: emailContent,
            recipientEmail: recipientEmail,
            presentingViewController: presentingViewController
        )
    }
    
    /// Creates EmailContent from multiple SharedContent items
    /// - Parameter sharedContents: Array of shared content items
    /// - Returns: EmailContent with combined content and attachments
    func createEmailContent(from sharedContents: [SharedContent]) -> EmailContent {
        guard !sharedContents.isEmpty else {
            return EmailContent(subject: "Shared Content", body: "No content to share.")
        }
        
        if sharedContents.count == 1 {
            return createEmailContent(from: sharedContents[0])
        }
        
        // Multiple items - create combined email
        let subject = "Shared Content (\(sharedContents.count) items)"
        let timestamp = DateFormatter.emailTimestamp.string(from: Date())
        var body = "Shared via Laplasian on \(timestamp)\n\n"
        body += "Multiple items shared:\n\n"
        
        var attachments: [EmailAttachment] = []
        
        for (index, content) in sharedContents.enumerated() {
            let itemNumber = index + 1
            
            switch content.type {
            case .text(let text):
                body += "\(itemNumber). Text Content:\n\(text)\n\n"
                
            case .image(let image):
                body += "\(itemNumber). Image (see attachment)\n\n"
                let attachment = EmailAttachment.fromImage(image, fileName: "image_\(itemNumber).jpg")
                attachments.append(attachment)
                
            case .url(let url):
                body += "\(itemNumber). Link: \(url.absoluteString)\n"
                if let metadata = content.metadata,
                   let title = metadata["title"] as? String {
                    body += "   Title: \(title)\n"
                }
                body += "\n"
                
            case .file(let fileURL):
                let fileName = fileURL.lastPathComponent
                body += "\(itemNumber). File: \(fileName) (see attachment)\n\n"
                let mimeType = mimeTypeForFile(at: fileURL)
                let attachment = EmailAttachment(
                    data: content.data,
                    mimeType: mimeType,
                    fileName: fileName
                )
                attachments.append(attachment)
            }
        }
        
        return EmailContent(subject: subject, body: body, attachments: attachments)
    }
    
    /// Attempts to send email with automatic dismissal and minimal user interaction
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
        
        // Present the composer with automatic sending intent
        presentingViewController.present(composer, animated: true) { [weak self] in
            // Note: iOS doesn't allow programmatic sending without user interaction
            // The user will still need to tap "Send" for security reasons
            // This is a limitation of the MessageUI framework
            if autoSend {
                // We can't actually auto-send due to iOS security restrictions
                // But we can provide feedback that the email is ready to send
                self?.onEmailReadyToSend?()
            }
        }
    }
    
    /// Sends email with comprehensive error handling and retry logic
    /// - Parameters:
    ///   - content: The email content to send
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present from
    ///   - enableRetry: Whether to enable automatic retry on failure
    ///   - maxRetries: Maximum number of retry attempts
    /// - Throws: ShareEmailError if sending fails immediately
    func sendEmailWithRetry(
        content: EmailContent,
        recipientEmail: String,
        presentingViewController: UIViewController,
        enableRetry: Bool = true,
        maxRetries: Int = 3
    ) throws {
        
        do {
            try sendEmailAutomatically(
                content: content,
                recipientEmail: recipientEmail,
                presentingViewController: presentingViewController
            )
        } catch {
            if enableRetry {
                // Start retry mechanism
                retryEmailSending(
                    content: content,
                    recipientEmail: recipientEmail,
                    presentingViewController: presentingViewController,
                    maxRetries: maxRetries
                )
            } else {
                // Re-throw the error if retry is disabled
                throw error
            }
        }
    }
    
    /// Callback for when email is ready to send (composed and presented)
    var onEmailReadyToSend: (() -> Void)?
    
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
    
    /// Checks if network is available for sending emails
    /// - Returns: True if network appears to be available
    func isNetworkAvailable() -> Bool {
        // Basic network availability check
        // In a real implementation, you might use Network framework or Reachability
        // For now, we'll assume network is available if we can send mail
        return MFMailComposeViewController.canSendMail()
    }
    
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
        
        // Check network if requested
        if checkNetwork && !isNetworkAvailable() {
            throw ShareEmailError.networkUnavailable
        }
    }
    
    /// Handles retry logic for failed email sending
    /// - Parameters:
    ///   - content: The email content to retry
    ///   - recipientEmail: The email address to send to
    ///   - presentingViewController: The view controller to present from
    ///   - maxRetries: Maximum number of retry attempts
    func retryEmailSending(
        content: EmailContent,
        recipientEmail: String,
        presentingViewController: UIViewController,
        maxRetries: Int = 3
    ) {
        var retryCount = 0
        
        func attemptSend() {
            do {
                try sendEmailAutomatically(
                    content: content,
                    recipientEmail: recipientEmail,
                    presentingViewController: presentingViewController
                )
            } catch {
                retryCount += 1
                
                // Determine if this error is retryable
                let isRetryable = isRetryableError(error)
                
                if retryCount < maxRetries && isRetryable {
                    // Calculate exponential backoff delay
                    let delay = min(pow(2.0, Double(retryCount)), 10.0) // Max 10 seconds
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        attemptSend()
                    }
                } else {
                    // Max retries reached or non-retryable error, call failure callback
                    if let shareError = error as? ShareEmailError {
                        onFailure?(shareError)
                    } else {
                        onFailure?(.sendingFailed(error))
                    }
                }
            }
        }
        
        attemptSend()
    }
    
    /// Determines if an error is retryable
    /// - Parameter error: The error to check
    /// - Returns: True if the error might be resolved by retrying
    internal func isRetryableError(_ error: Error) -> Bool {
        if let shareError = error as? ShareEmailError {
            switch shareError {
            case .networkUnavailable, .emailCompositionFailed:
                return true
            case .sendingFailed:
                return true
            case .invalidEmailAddress, .noEmailConfigured, .contentProcessingFailed, .appGroupAccessFailed:
                return false
            }
        }
        return true // Unknown errors might be retryable
    }
    
    internal func handleMailComposeResult(_ result: MFMailComposeResult, error: Error?) {
        // Dismiss the composer first, then handle the result
        defer {
            // Clean up references
            mailComposer = nil
            presentingViewController = nil
            onEmailReadyToSend = nil
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
    
    /// Provides detailed result information for debugging and logging
    /// - Parameters:
    ///   - result: The mail compose result
    ///   - error: Any error that occurred
    /// - Returns: A descriptive string of the result
    func describeMailComposeResult(_ result: MFMailComposeResult, error: Error?) -> String {
        switch result {
        case .sent:
            return "Email sent successfully"
        case .failed:
            if let error = error {
                return "Email sending failed: \(error.localizedDescription)"
            } else {
                return "Email sending failed: Unknown error"
            }
        case .cancelled:
            return "Email composition cancelled by user"
        case .saved:
            return "Email saved to drafts"
        @unknown default:
            return "Unknown mail compose result"
        }
    }
    
    internal func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    internal func mimeTypeForFile(at url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "txt":
            return "text/plain"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt":
            return "application/vnd.ms-powerpoint"
        case "pptx":
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "zip":
            return "application/zip"
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let emailTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}