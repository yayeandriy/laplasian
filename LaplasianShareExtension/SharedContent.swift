//
//  SharedContent.swift
//  LaplasianShareExtension
//
//  Created by Kiro on 16.08.2025.
//

import Foundation
import UIKit

/// Represents different types of content that can be shared
enum ContentType {
    case text(String)
    case image(UIImage)
    case url(URL)
    case file(URL)
}

/// Container for shared content with metadata
struct SharedContent {
    let type: ContentType
    let data: Data
    let metadata: [String: Any]?
    
    init(type: ContentType, data: Data, metadata: [String: Any]? = nil) {
        self.type = type
        self.data = data
        self.metadata = metadata
    }
    
    // MARK: - Conversion Methods
    
    /// Creates SharedContent from text
    static func fromText(_ text: String, metadata: [String: Any]? = nil) -> SharedContent {
        let data = text.data(using: .utf8) ?? Data()
        return SharedContent(type: .text(text), data: data, metadata: metadata)
    }
    
    /// Creates SharedContent from image
    static func fromImage(_ image: UIImage, metadata: [String: Any]? = nil) -> SharedContent {
        let data = image.jpegData(compressionQuality: 0.8) ?? Data()
        return SharedContent(type: .image(image), data: data, metadata: metadata)
    }
    
    /// Creates SharedContent from URL
    static func fromURL(_ url: URL, metadata: [String: Any]? = nil) -> SharedContent {
        let data = url.absoluteString.data(using: .utf8) ?? Data()
        return SharedContent(type: .url(url), data: data, metadata: metadata)
    }
    
    /// Creates SharedContent from file URL
    static func fromFile(_ fileURL: URL, metadata: [String: Any]? = nil) -> SharedContent? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return SharedContent(type: .file(fileURL), data: data, metadata: metadata)
    }
}

/// Email content structure for composition
struct EmailContent {
    let subject: String
    let body: String
    let attachments: [EmailAttachment]
    
    init(subject: String, body: String, attachments: [EmailAttachment] = []) {
        self.subject = subject
        self.body = body
        self.attachments = attachments
    }
}

/// Email attachment structure
struct EmailAttachment {
    let data: Data
    let mimeType: String
    let fileName: String
    
    init(data: Data, mimeType: String, fileName: String) {
        self.data = data
        self.mimeType = mimeType
        self.fileName = fileName
    }
    
    /// Creates an attachment from image
    static func fromImage(_ image: UIImage, fileName: String? = nil, compressionQuality: CGFloat = 0.8) -> EmailAttachment {
        let data = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        let name = fileName ?? "image_\(Date().timeIntervalSince1970).jpg"
        return EmailAttachment(data: data, mimeType: "image/jpeg", fileName: name)
    }
}