//
//  ContentProcessor.swift
//  LaplasianShareExtension
//
//  Created by Kiro on 16.08.2025.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import LinkPresentation

/// Processes different types of shared content for email composition
struct ContentProcessor {
    
    // MARK: - Content Processing Methods
    
    /// Processes plain text content
    /// - Parameter text: The text content to process
    /// - Returns: EmailContent with the text in the body
    static func processText(_ text: String) -> EmailContent {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Generate subject from first line or first 50 characters
        let subject = generateSubjectFromText(trimmedText)
        
        let body = "\(trimmedText)\n\nLength: \(trimmedText.count) characters"
        return EmailContent(
            subject: subject,
            body: body,
            attachments: []
        )
    }
    
    /// Processes image content with compression
    /// - Parameter image: The UIImage to process
    /// - Returns: EmailContent with the image as an attachment
    static func processImage(_ image: UIImage) -> EmailContent {
        let compressedImageData = compressImage(image)
        let fileName = "shared_image_\(Date().timeIntervalSince1970).jpg"
        
        let attachment = EmailAttachment(
            data: compressedImageData,
            mimeType: "image/jpeg",
            fileName: fileName
        )
        
        let sizeString = ByteCountFormatter.string(fromByteCount: Int64(compressedImageData.count), countStyle: .file)
        let dimensions = "\(Int(image.size.width))x\(Int(image.size.height)) px"
        let body = "Please find the shared image attached.\nSize: \(sizeString)\nDimensions: \(dimensions)"
        return EmailContent(
            subject: "Shared Image",
            body: body,
            attachments: [attachment]
        )
    }
    
    /// Processes URL content with metadata extraction
    /// - Parameter url: The URL to process
    /// - Returns: EmailContent with URL and metadata in the body
    static func processURL(_ url: URL, metadata: [String: Any]? = nil) -> EmailContent {
        let subject: String
        if let title = metadata?["title"] as? String, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            subject = title
        } else {
            subject = "Shared Link: \(url.host ?? "Website")"
        }
        
        // Create body with URL and basic metadata
        var body = "Shared URL: \(url.absoluteString)\n\n"
        
        // Add basic URL information
        if let host = url.host {
            body += "Domain: \(host)\n"
        }
        
        if let scheme = url.scheme {
            body += "Protocol: \(scheme)\n"
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let items = components.queryItems, !items.isEmpty {
            body += "Query parameters: \(items.count)\n"
        }
        
        if let data = (metadata?["previewImageData"] as? Data) ?? (metadata?["imageData"] as? Data) {
            let html = htmlBody(withPlainText: body, inlineImageData: data, mimeType: "image/jpeg")
            return EmailContent(subject: subject, body: html, attachments: [], isHTML: true)
        } else {
            return EmailContent(subject: subject, body: body, attachments: [])
        }
    }
    
    /// Processes file content for attachment
    /// - Parameter fileURL: The file URL to process
    /// - Returns: EmailContent with the file as an attachment
    /// - Throws: ShareEmailError if file processing fails
    static func processFile(_ fileURL: URL) throws -> EmailContent {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw ShareEmailError.contentProcessingFailed
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let mimeType = getMimeType(for: fileURL)
            
            let attachment = EmailAttachment(
                data: fileData,
                mimeType: mimeType,
                fileName: fileName
            )
            
            let subject = "Shared File: \(fileName)"
            let sizeString = ByteCountFormatter.string(fromByteCount: Int64(fileData.count), countStyle: .file)
            let body = "Please find the shared file '\(fileName)' attached.\n\nFile size: \(sizeString)\nMIME: \(mimeType)"
            
            return EmailContent(
                subject: subject,
                body: body,
                attachments: [attachment]
            )
        } catch {
            throw ShareEmailError.contentProcessingFailed
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generates an appropriate email subject from text content
    /// - Parameter text: The text to generate subject from
    /// - Returns: A suitable subject line
    private static func generateSubjectFromText(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let prefix = "Shared Text: "
        let maxTotalLength = 54
        let maxContentLength = maxTotalLength - prefix.count - 3 // 3 for "..."
        
        if !firstLine.isEmpty && (prefix.count + firstLine.count) <= maxTotalLength {
            return "Shared Text: \(firstLine)"
        } else if !firstLine.isEmpty {
            let truncated = String(firstLine.prefix(maxContentLength)) + "..."
            return "Shared Text: \(truncated)"
        } else {
            return "Shared Text Content"
        }
    }
    
    /// Compresses an image for email attachment
    /// - Parameter image: The image to compress
    /// - Returns: Compressed image data
    private static func compressImage(_ image: UIImage) -> Data {
        // Start with high quality and reduce if needed
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        // Reduce quality if image is too large (> 5MB)
        let maxSize = 5 * 1024 * 1024 // 5MB
        
        while let data = imageData, data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        return imageData ?? Data()
    }
    
    /// Determines MIME type for a file URL
    /// - Parameter url: The file URL
    /// - Returns: MIME type string
    private static func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        if #available(iOS 14.0, *) {
            if let utType = UTType(filenameExtension: pathExtension) {
                return utType.preferredMIMEType ?? "application/octet-stream"
            }
        }
        
        // Fallback for common file types
        switch pathExtension {
        case "txt":
            return "text/plain"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        default:
            return "application/octet-stream"
        }
    }

    private static func htmlBody(withPlainText text: String, inlineImageData: Data, mimeType: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br/>")
        let base64 = inlineImageData.base64EncodedString()
        let imgTag = "<br/><img src=\"data:\(mimeType);base64,\(base64)\" alt=\"shared image\" style=\"max-width:100%; height:auto;\"/>"
        return "<html><body><div style=\"font-family:-apple-system,Helvetica,Arial,sans-serif;\">\(escaped)\(imgTag)</div></body></html>"
    }
}