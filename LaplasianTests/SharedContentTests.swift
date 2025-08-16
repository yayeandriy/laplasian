//
//  SharedContentTests.swift
//  LaplasianTests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest
import UIKit
@testable import Laplasian

class SharedContentTests: XCTestCase {
    
    // MARK: - ContentType Tests
    
    func testContentType_TextCase() {
        // Given
        let text = "Hello World"
        let contentType = ContentType.text(text)
        
        // When/Then
        if case .text(let extractedText) = contentType {
            XCTAssertEqual(extractedText, text)
        } else {
            XCTFail("Expected text content type")
        }
    }
    
    func testContentType_ImageCase() {
        // Given
        let image = createTestImage()
        let contentType = ContentType.image(image)
        
        // When/Then
        if case .image(let extractedImage) = contentType {
            XCTAssertEqual(extractedImage, image)
        } else {
            XCTFail("Expected image content type")
        }
    }
    
    func testContentType_URLCase() {
        // Given
        let url = URL(string: "https://example.com")!
        let contentType = ContentType.url(url)
        
        // When/Then
        if case .url(let extractedURL) = contentType {
            XCTAssertEqual(extractedURL, url)
        } else {
            XCTFail("Expected URL content type")
        }
    }
    
    func testContentType_FileCase() {
        // Given
        let fileURL = URL(fileURLWithPath: "/path/to/file.txt")
        let contentType = ContentType.file(fileURL)
        
        // When/Then
        if case .file(let extractedURL) = contentType {
            XCTAssertEqual(extractedURL, fileURL)
        } else {
            XCTFail("Expected file content type")
        }
    }
    
    // MARK: - SharedContent Tests
    
    func testSharedContent_Initialization() {
        // Given
        let text = "Test content"
        let data = text.data(using: .utf8)!
        let metadata = ["source": "test"]
        
        // When
        let sharedContent = SharedContent(type: .text(text), data: data, metadata: metadata)
        
        // Then
        XCTAssertEqual(sharedContent.data, data)
        XCTAssertEqual(sharedContent.metadata?["source"] as? String, "test")
        if case .text(let extractedText) = sharedContent.type {
            XCTAssertEqual(extractedText, text)
        } else {
            XCTFail("Expected text content type")
        }
    }
    
    func testSharedContent_FromText() {
        // Given
        let text = "Hello World"
        let metadata = ["key": "value"]
        
        // When
        let sharedContent = SharedContent.fromText(text, metadata: metadata)
        
        // Then
        XCTAssertEqual(sharedContent.data, text.data(using: .utf8))
        XCTAssertEqual(sharedContent.metadata?["key"] as? String, "value")
        if case .text(let extractedText) = sharedContent.type {
            XCTAssertEqual(extractedText, text)
        } else {
            XCTFail("Expected text content type")
        }
    }
    
    func testSharedContent_FromImage() {
        // Given
        let image = createTestImage()
        
        // When
        let sharedContent = SharedContent.fromImage(image)
        
        // Then
        XCTAssertFalse(sharedContent.data.isEmpty)
        if case .image(let extractedImage) = sharedContent.type {
            XCTAssertEqual(extractedImage, image)
        } else {
            XCTFail("Expected image content type")
        }
    }
    
    func testSharedContent_FromURL() {
        // Given
        let url = URL(string: "https://example.com")!
        
        // When
        let sharedContent = SharedContent.fromURL(url)
        
        // Then
        XCTAssertEqual(sharedContent.data, url.absoluteString.data(using: .utf8))
        if case .url(let extractedURL) = sharedContent.type {
            XCTAssertEqual(extractedURL, url)
        } else {
            XCTFail("Expected URL content type")
        }
    }
    
    func testSharedContent_FromFile() {
        // Given
        let fileURL = createTestFile()
        
        // When
        let sharedContent = SharedContent.fromFile(fileURL)
        
        // Then
        XCTAssertNotNil(sharedContent)
        XCTAssertFalse(sharedContent!.data.isEmpty)
        if case .file(let extractedURL) = sharedContent!.type {
            XCTAssertEqual(extractedURL, fileURL)
        } else {
            XCTFail("Expected file content type")
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testSharedContent_FromFile_InvalidFile() {
        // Given
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.txt")
        
        // When
        let sharedContent = SharedContent.fromFile(invalidURL)
        
        // Then
        XCTAssertNil(sharedContent)
    }
    
    func testSharedContent_AsString_Text() {
        // Given
        let text = "Hello World"
        let sharedContent = SharedContent.fromText(text)
        
        // When
        let result = sharedContent.asString()
        
        // Then
        XCTAssertEqual(result, text)
    }
    
    func testSharedContent_AsString_URL() {
        // Given
        let url = URL(string: "https://example.com")!
        let sharedContent = SharedContent.fromURL(url)
        
        // When
        let result = sharedContent.asString()
        
        // Then
        XCTAssertEqual(result, url.absoluteString)
    }
    
    func testSharedContent_AsString_Image() {
        // Given
        let image = createTestImage()
        let sharedContent = SharedContent.fromImage(image)
        
        // When
        let result = sharedContent.asString()
        
        // Then
        XCTAssertNil(result)
    }
    
    func testSharedContent_DisplayName() {
        // Given/When/Then
        let textContent = SharedContent.fromText("Hello")
        XCTAssertEqual(textContent.displayName(), "Text Content")
        
        let imageContent = SharedContent.fromImage(createTestImage())
        XCTAssertEqual(imageContent.displayName(), "Image")
        
        let urlContent = SharedContent.fromURL(URL(string: "https://example.com")!)
        XCTAssertEqual(urlContent.displayName(), "example.com")
        
        let fileURL = URL(fileURLWithPath: "/path/to/document.pdf")
        let fileContent = SharedContent(type: .file(fileURL), data: Data())
        XCTAssertEqual(fileContent.displayName(), "document.pdf")
    }
    
    // MARK: - EmailContent Tests
    
    func testEmailContent_Initialization() {
        // Given
        let subject = "Test Subject"
        let body = "Test Body"
        let attachment = EmailAttachment.fromText("attachment content")
        
        // When
        let emailContent = EmailContent(subject: subject, body: body, attachments: [attachment])
        
        // Then
        XCTAssertEqual(emailContent.subject, subject)
        XCTAssertEqual(emailContent.body, body)
        XCTAssertEqual(emailContent.attachments.count, 1)
    }
    
    func testEmailContent_WithAttachment() {
        // Given
        let subject = "Test Subject"
        let body = "Test Body"
        let attachment = EmailAttachment.fromText("attachment content")
        
        // When
        let emailContent = EmailContent.withAttachment(subject: subject, body: body, attachment: attachment)
        
        // Then
        XCTAssertEqual(emailContent.subject, subject)
        XCTAssertEqual(emailContent.body, body)
        XCTAssertEqual(emailContent.attachments.count, 1)
        XCTAssertEqual(emailContent.attachments.first?.fileName, "attachment.txt")
    }
    
    func testEmailContent_AddingAttachment() {
        // Given
        let originalContent = EmailContent(subject: "Test", body: "Body")
        let attachment = EmailAttachment.fromText("new attachment")
        
        // When
        let updatedContent = originalContent.addingAttachment(attachment)
        
        // Then
        XCTAssertEqual(updatedContent.attachments.count, 1)
        XCTAssertEqual(originalContent.attachments.count, 0) // Original unchanged
    }
    
    func testEmailContent_TotalAttachmentSize() {
        // Given
        let attachment1 = EmailAttachment.fromText("Hello")
        let attachment2 = EmailAttachment.fromText("World")
        let emailContent = EmailContent(subject: "Test", body: "Body", attachments: [attachment1, attachment2])
        
        // When
        let totalSize = emailContent.totalAttachmentSize
        
        // Then
        let expectedSize = "Hello".data(using: .utf8)!.count + "World".data(using: .utf8)!.count
        XCTAssertEqual(totalSize, expectedSize)
    }
    
    func testEmailContent_HasAttachments() {
        // Given
        let contentWithAttachments = EmailContent(subject: "Test", body: "Body", attachments: [EmailAttachment.fromText("test")])
        let contentWithoutAttachments = EmailContent(subject: "Test", body: "Body")
        
        // When/Then
        XCTAssertTrue(contentWithAttachments.hasAttachments)
        XCTAssertFalse(contentWithoutAttachments.hasAttachments)
    }
    
    // MARK: - EmailAttachment Tests
    
    func testEmailAttachment_Initialization() {
        // Given
        let data = "test content".data(using: .utf8)!
        let mimeType = "text/plain"
        let fileName = "test.txt"
        
        // When
        let attachment = EmailAttachment(data: data, mimeType: mimeType, fileName: fileName)
        
        // Then
        XCTAssertEqual(attachment.data, data)
        XCTAssertEqual(attachment.mimeType, mimeType)
        XCTAssertEqual(attachment.fileName, fileName)
    }
    
    func testEmailAttachment_FromText() {
        // Given
        let text = "Hello World"
        let fileName = "custom.txt"
        
        // When
        let attachment = EmailAttachment.fromText(text, fileName: fileName)
        
        // Then
        XCTAssertEqual(attachment.data, text.data(using: .utf8))
        XCTAssertEqual(attachment.mimeType, "text/plain")
        XCTAssertEqual(attachment.fileName, fileName)
    }
    
    func testEmailAttachment_FromText_DefaultFileName() {
        // Given
        let text = "Hello World"
        
        // When
        let attachment = EmailAttachment.fromText(text)
        
        // Then
        XCTAssertEqual(attachment.fileName, "attachment.txt")
    }
    
    func testEmailAttachment_FromImage() {
        // Given
        let image = createTestImage()
        let fileName = "custom.jpg"
        
        // When
        let attachment = EmailAttachment.fromImage(image, fileName: fileName)
        
        // Then
        XCTAssertFalse(attachment.data.isEmpty)
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertEqual(attachment.fileName, fileName)
    }
    
    func testEmailAttachment_FromImage_DefaultFileName() {
        // Given
        let image = createTestImage()
        
        // When
        let attachment = EmailAttachment.fromImage(image)
        
        // Then
        XCTAssertTrue(attachment.fileName.hasPrefix("image_"))
        XCTAssertTrue(attachment.fileName.hasSuffix(".jpg"))
    }
    
    func testEmailAttachment_FileSizeString() {
        // Given
        let text = "Hello World"
        let attachment = EmailAttachment.fromText(text)
        
        // When
        let sizeString = attachment.fileSizeString
        
        // Then
        XCTAssertFalse(sizeString.isEmpty)
        XCTAssertTrue(sizeString.contains("bytes") || sizeString.contains("B"))
    }
    
    func testEmailAttachment_IsImage() {
        // Given
        let imageAttachment = EmailAttachment.fromImage(createTestImage())
        let textAttachment = EmailAttachment.fromText("test")
        
        // When/Then
        XCTAssertTrue(imageAttachment.isImage)
        XCTAssertFalse(textAttachment.isImage)
    }
    
    func testEmailAttachment_IsText() {
        // Given
        let imageAttachment = EmailAttachment.fromImage(createTestImage())
        let textAttachment = EmailAttachment.fromText("test")
        
        // When/Then
        XCTAssertFalse(imageAttachment.isText)
        XCTAssertTrue(textAttachment.isText)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createTestFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("shared_content_test.txt")
        
        let testContent = "This is test file content."
        try! testContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}