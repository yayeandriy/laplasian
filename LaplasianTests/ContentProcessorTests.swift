//
//  ContentProcessorTests.swift
//  LaplasianTests
//
//  Created by Kiro on 16.08.2025.
//

import XCTest
import UIKit
@testable import Laplasian

class ContentProcessorTests: XCTestCase {
    
    // MARK: - Text Processing Tests
    
    func testProcessText_WithSimpleText_ReturnsCorrectEmailContent() {
        // Given
        let inputText = "Hello, this is a test message."
        
        // When
        let result = ContentProcessor.processText(inputText)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Text: Hello, this is a test message.")
        XCTAssertEqual(result.body, inputText)
        XCTAssertTrue(result.attachments.isEmpty)
    }
    
    func testProcessText_WithLongText_TruncatesSubject() {
        // Given
        let longText = "This is a very long text that should be truncated in the subject line because it exceeds the maximum length"
        
        // When
        let result = ContentProcessor.processText(longText)
        
        // Then
        XCTAssertTrue(result.subject.hasSuffix("..."))
        XCTAssertTrue(result.subject.count <= 54) // "Shared Text: " + 47 chars + "..."
        XCTAssertEqual(result.body, longText)
    }
    
    func testProcessText_WithMultilineText_UsesFirstLineForSubject() {
        // Given
        let multilineText = "First line\nSecond line\nThird line"
        
        // When
        let result = ContentProcessor.processText(multilineText)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Text: First line")
        XCTAssertEqual(result.body, multilineText)
    }
    
    func testProcessText_WithWhitespaceText_TrimsCorrectly() {
        // Given
        let textWithWhitespace = "  \n  Hello World  \n  "
        
        // When
        let result = ContentProcessor.processText(textWithWhitespace)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Text: Hello World")
        XCTAssertEqual(result.body, "Hello World")
    }
    
    func testProcessText_WithEmptyText_ReturnsDefaultSubject() {
        // Given
        let emptyText = ""
        
        // When
        let result = ContentProcessor.processText(emptyText)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Text Content")
        XCTAssertEqual(result.body, "")
    }
    
    // MARK: - Image Processing Tests
    
    func testProcessImage_WithValidImage_ReturnsEmailContentWithAttachment() {
        // Given
        let image = createTestImage()
        
        // When
        let result = ContentProcessor.processImage(image)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Image")
        XCTAssertEqual(result.body, "Please find the shared image attached.")
        XCTAssertEqual(result.attachments.count, 1)
        
        let attachment = result.attachments.first!
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertTrue(attachment.fileName.hasPrefix("shared_image_"))
        XCTAssertTrue(attachment.fileName.hasSuffix(".jpg"))
        XCTAssertFalse(attachment.data.isEmpty)
    }
    
    func testProcessImage_CompressesLargeImage() {
        // Given
        let largeImage = createLargeTestImage()
        
        // When
        let result = ContentProcessor.processImage(largeImage)
        
        // Then
        let attachment = result.attachments.first!
        // Compressed image should be smaller than 5MB
        XCTAssertLessThan(attachment.data.count, 5 * 1024 * 1024)
    }
    
    // MARK: - URL Processing Tests
    
    func testProcessURL_WithHTTPSURL_ReturnsCorrectEmailContent() {
        // Given
        let url = URL(string: "https://www.example.com/path?param=value")!
        
        // When
        let result = ContentProcessor.processURL(url)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Link: www.example.com")
        XCTAssertTrue(result.body.contains("Shared URL: https://www.example.com/path?param=value"))
        XCTAssertTrue(result.body.contains("Domain: www.example.com"))
        XCTAssertTrue(result.body.contains("Protocol: https"))
        XCTAssertTrue(result.attachments.isEmpty)
    }
    
    func testProcessURL_WithoutHost_HandlesGracefully() {
        // Given
        let url = URL(string: "file:///local/path/file.txt")!
        
        // When
        let result = ContentProcessor.processURL(url)
        
        // Then
        XCTAssertEqual(result.subject, "Shared Link: Website")
        XCTAssertTrue(result.body.contains("file:///local/path/file.txt"))
        XCTAssertTrue(result.body.contains("Protocol: file"))
    }
    
    // MARK: - File Processing Tests
    
    func testProcessFile_WithValidFile_ReturnsEmailContentWithAttachment() throws {
        // Given
        let testFileURL = createTestFile()
        
        // When
        let result = try ContentProcessor.processFile(testFileURL)
        
        // Then
        XCTAssertTrue(result.subject.hasPrefix("Shared File:"))
        XCTAssertTrue(result.body.contains("Please find the shared file"))
        XCTAssertTrue(result.body.contains("File size:"))
        XCTAssertEqual(result.attachments.count, 1)
        
        let attachment = result.attachments.first!
        XCTAssertEqual(attachment.mimeType, "text/plain")
        XCTAssertTrue(attachment.fileName.hasSuffix(".txt"))
        XCTAssertFalse(attachment.data.isEmpty)
        
        // Clean up
        try? FileManager.default.removeItem(at: testFileURL)
    }
    
    func testProcessFile_WithPDFFile_ReturnsCorrectMimeType() throws {
        // Given
        let pdfURL = createTestFileWithExtension("pdf")
        
        // When
        let result = try ContentProcessor.processFile(pdfURL)
        
        // Then
        let attachment = result.attachments.first!
        XCTAssertEqual(attachment.mimeType, "application/pdf")
        
        // Clean up
        try? FileManager.default.removeItem(at: pdfURL)
    }
    
    func testProcessFile_WithImageFile_ReturnsCorrectMimeType() throws {
        // Given
        let imageURL = createTestFileWithExtension("jpg")
        
        // When
        let result = try ContentProcessor.processFile(imageURL)
        
        // Then
        let attachment = result.attachments.first!
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        
        // Clean up
        try? FileManager.default.removeItem(at: imageURL)
    }
    
    func testProcessFile_WithUnknownExtension_ReturnsDefaultMimeType() throws {
        // Given
        let unknownURL = createTestFileWithExtension("unknown")
        
        // When
        let result = try ContentProcessor.processFile(unknownURL)
        
        // Then
        let attachment = result.attachments.first!
        XCTAssertEqual(attachment.mimeType, "application/octet-stream")
        
        // Clean up
        try? FileManager.default.removeItem(at: unknownURL)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createLargeTestImage() -> UIImage {
        let size = CGSize(width: 2000, height: 2000)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createTestFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_file.txt")
        
        let testContent = "This is test file content for unit testing."
        try! testContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func createTestFileWithExtension(_ ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_file.\(ext)")
        
        let testContent = "Test content"
        try! testContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}