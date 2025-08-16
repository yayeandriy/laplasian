//
//  SharedContent.swift
//  Laplasian
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
}