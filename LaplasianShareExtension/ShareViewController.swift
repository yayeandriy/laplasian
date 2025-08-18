import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import MessageUI
import LinkPresentation

// MARK: - Embedded Models for Share Extension

/// Error types for the share email functionality
enum ShareEmailError: LocalizedError, Equatable {
    case noEmailConfigured
    case invalidEmailAddress
    case contentProcessingFailed
    case emailCompositionFailed
    case sendingFailed(Error)
    case networkUnavailable
    case appGroupAccessFailed
    
    var errorDescription: String? {
        switch self {
        case .noEmailConfigured:
            return "No email address configured. Please open the main app to set up."
        case .invalidEmailAddress:
            return "Invalid email address configured."
        case .contentProcessingFailed:
            return "Failed to process shared content."
        case .emailCompositionFailed:
            return "Mail app not configured. Please set up an email account in the Mail app first."
        case .sendingFailed(let error):
            return "Failed to send email: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable. Please check your connection."
        case .appGroupAccessFailed:
            return "Failed to access shared storage. Please reinstall the app."
        }
    }
    
    static func == (lhs: ShareEmailError, rhs: ShareEmailError) -> Bool {
        switch (lhs, rhs) {
        case (.noEmailConfigured, .noEmailConfigured),
             (.invalidEmailAddress, .invalidEmailAddress),
             (.contentProcessingFailed, .contentProcessingFailed),
             (.emailCompositionFailed, .emailCompositionFailed),
             (.networkUnavailable, .networkUnavailable),
             (.appGroupAccessFailed, .appGroupAccessFailed):
            return true
        case (.sendingFailed(let lhsError), .sendingFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

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
    
    static func fromText(_ text: String, metadata: [String: Any]? = nil) -> SharedContent {
        let data = text.data(using: .utf8) ?? Data()
        return SharedContent(type: .text(text), data: data, metadata: metadata)
    }
    
    static func fromImage(_ image: UIImage, metadata: [String: Any]? = nil) -> SharedContent {
        let data = image.jpegData(compressionQuality: 0.8) ?? Data()
        return SharedContent(type: .image(image), data: data, metadata: metadata)
    }
    
    static func fromURL(_ url: URL, metadata: [String: Any]? = nil) -> SharedContent {
        let data = url.absoluteString.data(using: .utf8) ?? Data()
        return SharedContent(type: .url(url), data: data, metadata: metadata)
    }
    
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
    let isHTML: Bool
    
    init(subject: String, body: String, attachments: [EmailAttachment] = [], isHTML: Bool = false) {
        self.subject = subject
        self.body = body
        self.attachments = attachments
        self.isHTML = isHTML
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
    
    static func fromImage(_ image: UIImage, fileName: String? = nil, compressionQuality: CGFloat = 0.8) -> EmailAttachment {
        let data = image.jpegData(compressionQuality: compressionQuality) ?? Data()
        let name = fileName ?? "image_\(Date().timeIntervalSince1970).jpg"
        return EmailAttachment(data: data, mimeType: "image/jpeg", fileName: name)
    }
}

/// Email configuration data model
struct EmailConfiguration: Codable {
    let recipientEmail: String
    let isConfigured: Bool
    let lastUpdated: Date
    
    init(recipientEmail: String) {
        self.recipientEmail = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isConfigured = !self.recipientEmail.isEmpty && Self.isValidEmailFormat(self.recipientEmail)
        self.lastUpdated = Date()
    }
    
    var isValidEmail: Bool {
        return isConfigured && Self.isValidEmailFormat(recipientEmail)
    }
    
    static func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

/// Shared storage for app group communication
class SharedStorage {
    static let shared = SharedStorage()
    
    private let appGroupIdentifier = "group.operators.yayeandriy.Laplasian"
    private let configurationKey = "email-configuration.json"
    
    private init() {}
    
    func getSharedContainer() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw ShareEmailError.appGroupAccessFailed
        }
        return containerURL
    }
    
    func loadConfiguration() throws -> EmailConfiguration? {
        let containerURL = try getSharedContainer()
        let configURL = containerURL.appendingPathComponent(configurationKey)
        
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            return try JSONDecoder().decode(EmailConfiguration.self, from: data)
        } catch {
            throw ShareEmailError.appGroupAccessFailed
        }
    }
    
    func isConfigured() -> Bool {
        do {
            if let config = try loadConfiguration() {
                return config.isConfigured
            }
            return false
        } catch {
            return false
        }
    }
}

/// Manages app settings and coordinates with shared storage
class SettingsManager {
    private let sharedStorage = SharedStorage.shared
    
    init() {}
    
    func getEmailAddress() -> String? {
        do {
            return try sharedStorage.loadConfiguration()?.recipientEmail
        } catch {
            return nil
        }
    }
    
    var isConfigured: Bool {
        return sharedStorage.isConfigured()
    }
    
    func isConfigurationValid() -> Bool {
        do {
            guard let config = try sharedStorage.loadConfiguration() else { return false }
            return config.isConfigured && config.isValidEmail
        } catch {
            return false
        }
    }
}

/// Handles email composition and sending using MessageUI framework
class EmailComposer: NSObject, MFMailComposeViewControllerDelegate {
    
    var onSuccess: (() -> Void)?
    var onFailure: ((ShareEmailError) -> Void)?
    var onCancel: (() -> Void)?
    
    internal var mailComposer: MFMailComposeViewController?
    internal weak var presentingViewController: UIViewController?
    
    override init() {
        super.init()
    }
    
    func sendEmailAutomatically(
        content: EmailContent,
        recipientEmail: String,
        presentingViewController: UIViewController,
        autoSend: Bool = true
    ) throws {
        
        try validateEmailPrerequisites(recipientEmail: recipientEmail, checkNetwork: true)
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        
        composer.setToRecipients([recipientEmail])
        composer.setSubject(content.subject)
        composer.setMessageBody(content.body, isHTML: content.isHTML)
        
        for attachment in content.attachments {
            composer.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.fileName
            )
        }
        
        self.mailComposer = composer
        self.presentingViewController = presentingViewController
        
        presentingViewController.present(composer, animated: true)
    }
    
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.handleMailComposeResult(result, error: error)
        }
    }
    
    func validateEmailPrerequisites(recipientEmail: String, checkNetwork: Bool = true) throws {
        guard MFMailComposeViewController.canSendMail() else {
            print("ShareExtension: Mail services not available - MFMailComposeViewController.canSendMail() returned false")
            throw ShareEmailError.emailCompositionFailed
        }
        
        guard isValidEmail(recipientEmail) else {
            print("ShareExtension: Invalid email address: \(recipientEmail)")
            throw ShareEmailError.invalidEmailAddress
        }
    }
    
    internal func handleMailComposeResult(_ result: MFMailComposeResult, error: Error?) {
        defer {
            mailComposer = nil
            presentingViewController = nil
        }
        
        switch result {
        case .sent:
            onSuccess?()
        case .failed:
            let shareError: ShareEmailError
            if let error = error {
                shareError = .sendingFailed(error)
            } else {
                shareError = .emailCompositionFailed
            }
            onFailure?(shareError)
        case .cancelled:
            onCancel?()
        case .saved:
            onSuccess?()
        @unknown default:
            onFailure?(.emailCompositionFailed)
        }
    }
    
    internal func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

/// Processes different types of shared content for email composition
struct ContentProcessor {
    
    static func processText(_ text: String) -> EmailContent {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = generateSubjectFromText(trimmedText)
        let body = "\(trimmedText)\n\nLength: \(trimmedText.count) characters"
        return EmailContent(
            subject: subject,
            body: body,
            attachments: []
        )
    }
    
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
    
    static func processURL(_ url: URL, metadata: [String: Any]? = nil) -> EmailContent {
        let subject: String
        if let title = metadata?["title"] as? String, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            subject = title
        } else {
            subject = "Shared Link: \(url.host ?? "Website")"
        }
        
        var body = "Shared URL: \(url.absoluteString)\n\n"
        
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
    
    private static func generateSubjectFromText(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let prefix = "Shared Text: "
        let maxTotalLength = 54
        let maxContentLength = maxTotalLength - prefix.count - 3
        
        if !firstLine.isEmpty && (prefix.count + firstLine.count) <= maxTotalLength {
            return "Shared Text: \(firstLine)"
        } else if !firstLine.isEmpty {
            let truncated = String(firstLine.prefix(maxContentLength)) + "..."
            return "Shared Text: \(truncated)"
        } else {
            return "Shared Text Content"
        }
    }
    
    private static func compressImage(_ image: UIImage) -> Data {
        var compressionQuality: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        
        let maxSize = 5 * 1024 * 1024 // 5MB
        
        while let data = imageData, data.count > maxSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }
        
        return imageData ?? Data()
    }
    
    private static func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        if #available(iOS 14.0, *) {
            if let utType = UTType(filenameExtension: pathExtension) {
                return utType.preferredMIMEType ?? "application/octet-stream"
            }
        }
        
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

class ShareViewController: UIViewController {
    
    // MARK: - UI Elements
    private var titleLabel: UILabel!
    private var statusLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    private var containerView: UIView!
    
    // MARK: - State Management
    private var isProcessing = false
    private var processedEmailContent: EmailContent?
    
    // MARK: - Components
    private let settingsManager = SettingsManager()
    private var emailComposer: EmailComposer?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        showLoadingState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start processing shared content when view appears
        if !isProcessing {
            processSharedContent()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Clean up any ongoing operations
        stopLoadingIndicator()
        cleanupEmailComposer()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Create container view for better layout management
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Title label
        titleLabel = UILabel()
        titleLabel.text = "Share to Email"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "Processing shared content..."
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        statusLabel.textAlignment = .center
        statusLabel.textColor = UIColor.secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        // Activity indicator
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        containerView.addSubview(activityIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Status label constraints
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Activity indicator constraints
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    // MARK: - UI State Management
    
    private func showLoadingState() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Processing shared content..."
            self.statusLabel.textColor = UIColor.secondaryLabel
            self.activityIndicator.startAnimating()
        }
    }
    
    private func showSuccessState() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Email sent successfully!"
            self.statusLabel.textColor = UIColor.systemGreen
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func showErrorState(message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.statusLabel.textColor = UIColor.systemRed
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func stopLoadingIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - Content Processing
    
    private func processSharedContent() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        guard let extensionContext = extensionContext else {
            handleError(ShareEmailError.contentProcessingFailed)
            return
        }
        
        // Validate extension context has input items
        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem],
              !inputItems.isEmpty else {
            handleError(ShareEmailError.contentProcessingFailed)
            return
        }
        
        // Process all input items
        extractContentFromInputItems(inputItems) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let sharedContents):
                    self?.processExtractedContent(sharedContents)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    /// Extracts content from NSExtensionItem array
    /// - Parameters:
    ///   - inputItems: Array of NSExtensionItem from extension context
    ///   - completion: Completion handler with result
    private func extractContentFromInputItems(
        _ inputItems: [NSExtensionItem],
        completion: @escaping (Result<[SharedContent], ShareEmailError>) -> Void
    ) {
        var extractedContents: [SharedContent] = []
        let dispatchGroup = DispatchGroup()
        var extractionError: ShareEmailError?
        
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                dispatchGroup.enter()
                
                // Process different content types
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    extractTextContent(from: attachment) { result in
                        switch result {
                        case .success(let content):
                            extractedContents.append(content)
                        case .failure(let error):
                            extractionError = error
                        }
                        dispatchGroup.leave()
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    extractImageContent(from: attachment) { result in
                        switch result {
                        case .success(let content):
                            extractedContents.append(content)
                        case .failure(let error):
                            extractionError = error
                        }
                        dispatchGroup.leave()
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    extractURLContent(from: attachment) { result in
                        switch result {
                        case .success(let content):
                            extractedContents.append(content)
                        case .failure(let error):
                            extractionError = error
                        }
                        dispatchGroup.leave()
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    extractFileContent(from: attachment) { result in
                        switch result {
                        case .success(let content):
                            extractedContents.append(content)
                        case .failure(let error):
                            extractionError = error
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    // Try to handle as generic data
                    extractGenericContent(from: attachment) { result in
                        switch result {
                        case .success(let content):
                            extractedContents.append(content)
                        case .failure(let error):
                            extractionError = error
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            if let error = extractionError {
                completion(.failure(error))
            } else if extractedContents.isEmpty {
                completion(.failure(.contentProcessingFailed))
            } else {
                completion(.success(extractedContents))
            }
        }
    }
    
    /// Extracts text content from NSItemProvider
    private func extractTextContent(
        from provider: NSItemProvider,
        completion: @escaping (Result<SharedContent, ShareEmailError>) -> Void
    ) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
            if let error = error {
                print("Error loading text content: \(error)")
                completion(.failure(.contentProcessingFailed))
                return
            }
            
            if let text = item as? String {
                let sharedContent = SharedContent.fromText(text)
                completion(.success(sharedContent))
            } else if let data = item as? Data,
                      let text = String(data: data, encoding: .utf8) {
                let sharedContent = SharedContent.fromText(text)
                completion(.success(sharedContent))
            } else {
                completion(.failure(.contentProcessingFailed))
            }
        }
    }
    
    /// Extracts image content from NSItemProvider
    private func extractImageContent(
        from provider: NSItemProvider,
        completion: @escaping (Result<SharedContent, ShareEmailError>) -> Void
    ) {
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
            if let error = error {
                print("Error loading image content: \(error)")
                completion(.failure(.contentProcessingFailed))
                return
            }
            
            var image: UIImage?
            
            if let imageItem = item as? UIImage {
                image = imageItem
            } else if let data = item as? Data {
                image = UIImage(data: data)
            } else if let url = item as? URL {
                if let data = try? Data(contentsOf: url) {
                    image = UIImage(data: data)
                }
            }
            
            if let image = image {
                let sharedContent = SharedContent.fromImage(image)
                completion(.success(sharedContent))
            } else {
                completion(.failure(.contentProcessingFailed))
            }
        }
    }
    
    /// Extracts URL content from NSItemProvider
    private func extractURLContent(
        from provider: NSItemProvider,
        completion: @escaping (Result<SharedContent, ShareEmailError>) -> Void
    ) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
            if let error = error {
                print("Error loading URL content: \(error)")
                completion(.failure(.contentProcessingFailed))
                return
            }
            
            if let url = item as? URL {
                // Try to fetch rich link metadata if available via LinkPresentation
                self.fetchLinkMetadata(for: url) { metadata in
                    let sharedContent = SharedContent.fromURL(url, metadata: metadata)
                    completion(.success(sharedContent))
                }
            } else if let urlString = item as? String,
                      let url = URL(string: urlString) {
                self.fetchLinkMetadata(for: url) { metadata in
                    let sharedContent = SharedContent.fromURL(url, metadata: metadata)
                    completion(.success(sharedContent))
                }
            } else {
                completion(.failure(.contentProcessingFailed))
            }
        }
    }
    
    /// Extracts file content from NSItemProvider
    private func extractFileContent(
        from provider: NSItemProvider,
        completion: @escaping (Result<SharedContent, ShareEmailError>) -> Void
    ) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let error = error {
                print("Error loading file content: \(error)")
                completion(.failure(.contentProcessingFailed))
                return
            }
            
            if let fileURL = item as? URL {
                if let sharedContent = SharedContent.fromFile(fileURL) {
                    completion(.success(sharedContent))
                } else {
                    completion(.failure(.contentProcessingFailed))
                }
            } else {
                completion(.failure(.contentProcessingFailed))
            }
        }
    }
    
    /// Extracts generic content from NSItemProvider as fallback
    private func extractGenericContent(
        from provider: NSItemProvider,
        completion: @escaping (Result<SharedContent, ShareEmailError>) -> Void
    ) {
        // Try to load as data first
        if let typeIdentifier = provider.registeredTypeIdentifiers.first {
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error = error {
                    print("Error loading generic content: \(error)")
                    completion(.failure(.contentProcessingFailed))
                    return
                }
                
                // Try different data types
                if let text = item as? String {
                    let sharedContent = SharedContent.fromText(text)
                    completion(.success(sharedContent))
                } else if let url = item as? URL {
                    self.fetchLinkMetadata(for: url) { metadata in
                        let sharedContent = SharedContent.fromURL(url, metadata: metadata)
                        completion(.success(sharedContent))
                    }
                } else if let image = item as? UIImage {
                    let sharedContent = SharedContent.fromImage(image)
                    completion(.success(sharedContent))
                } else {
                    completion(.failure(.contentProcessingFailed))
                }
            }
        } else {
            completion(.failure(.contentProcessingFailed))
        }
    }

    private func fetchLinkMetadata(for url: URL, completion: @escaping ([String: Any]?) -> Void) {
        if #available(iOS 13.0, *) {
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, _ in
                var dict: [String: Any] = [:]
                if let title = metadata?.title { dict["title"] = title }
                if let imageProvider = metadata?.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                            dict["previewImageData"] = data
                        }
                        completion(dict.isEmpty ? nil : dict)
                    }
                    return
                }
                completion(dict.isEmpty ? nil : dict)
            }
        } else {
            completion(nil)
        }
    }
    
    /// Processes extracted content using ContentProcessor
    private func processExtractedContent(_ sharedContents: [SharedContent]) {
        do {
            var emailContents: [EmailContent] = []
            
            for sharedContent in sharedContents {
                let emailContent: EmailContent
                
                switch sharedContent.type {
                case .text(let text):
                    emailContent = ContentProcessor.processText(text)
                case .image(let image):
                    emailContent = ContentProcessor.processImage(image)
                case .url(let url):
                    emailContent = ContentProcessor.processURL(url, metadata: sharedContent.metadata)
                case .file(let fileURL):
                    emailContent = try ContentProcessor.processFile(fileURL)
                }
                
                emailContents.append(emailContent)
            }
            
            // Combine multiple email contents if needed
            let finalEmailContent = combineEmailContents(emailContents)
            
            // Store processed content for next step
            self.processedEmailContent = finalEmailContent
            
            // Update UI to show processing complete
            showProcessingComplete()
            
        } catch {
            handleError(ShareEmailError.contentProcessingFailed)
        }
    }
    
    /// Combines multiple EmailContent objects into one
    private func combineEmailContents(_ emailContents: [EmailContent]) -> EmailContent {
        guard !emailContents.isEmpty else {
            return EmailContent(subject: "Shared Content", body: "No content to share.")
        }
        
        if emailContents.count == 1 {
            return emailContents[0]
        }
        
        // Multiple items - create combined email
        let subject = "Shared Content (\(emailContents.count) items)"
        var combinedBody = ""
        var allAttachments: [EmailAttachment] = []
        
        for (index, content) in emailContents.enumerated() {
            let itemNumber = index + 1
            
            if !combinedBody.isEmpty {
                combinedBody += "\n\n"
            }
            
            combinedBody += "Item \(itemNumber):\n"
            combinedBody += "Subject: \(content.subject)\n"
            combinedBody += content.body
            
            allAttachments.append(contentsOf: content.attachments)
        }
        
        return EmailContent(
            subject: subject,
            body: combinedBody,
            attachments: allAttachments
        )
    }
    
    /// Shows processing complete state and initiates email sending
    private func showProcessingComplete() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Content processed successfully"
            self.statusLabel.textColor = UIColor.systemBlue
            self.activityIndicator.stopAnimating()
            
            // Start email composition and sending workflow
            self.initiateEmailWorkflow()
        }
    }
    
    // MARK: - Email Workflow
    
    /// Initiates the email composition and sending workflow
    private func initiateEmailWorkflow() {
        print("ShareExtension: Starting email workflow")
        
        // First check if Mail services are available
        guard MFMailComposeViewController.canSendMail() else {
            print("ShareExtension: Mail services not available")
            handleError(ShareEmailError.emailCompositionFailed)
            return
        }
        
        // Check if email is configured
        guard settingsManager.isConfigured,
              let recipientEmail = settingsManager.getEmailAddress() else {
            print("ShareExtension: No email configured - isConfigured: \(settingsManager.isConfigured)")
            handleError(ShareEmailError.noEmailConfigured)
            return
        }
        
        print("ShareExtension: Email configured: \(recipientEmail)")
        
        // Validate email configuration
        guard settingsManager.isConfigurationValid() else {
            print("ShareExtension: Email configuration invalid")
            handleError(ShareEmailError.invalidEmailAddress)
            return
        }
        
        // Ensure we have processed content
        guard let emailContent = processedEmailContent else {
            print("ShareExtension: No processed email content")
            handleError(ShareEmailError.contentProcessingFailed)
            return
        }
        
        print("ShareExtension: Email content ready - subject: \(emailContent.subject)")
        
        // Update UI to show email composition
        showEmailCompositionState()
        
        // Create and configure email composer
        setupEmailComposer()
        
        // Compose and send email
        composeAndSendEmail(content: emailContent, recipientEmail: recipientEmail)
    }
    
    /// Sets up the email composer with callbacks
    private func setupEmailComposer() {
        emailComposer = EmailComposer()
        
        emailComposer?.onSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.handleEmailSuccess()
            }
        }
        
        emailComposer?.onFailure = { [weak self] error in
            DispatchQueue.main.async {
                self?.handleEmailFailure(error)
            }
        }
        
        emailComposer?.onCancel = { [weak self] in
            DispatchQueue.main.async {
                self?.handleEmailCancellation()
            }
        }
    }
    
    /// Composes and sends the email
    private func composeAndSendEmail(content: EmailContent, recipientEmail: String) {
        guard let composer = emailComposer else {
            print("ShareExtension: EmailComposer is nil")
            handleError(ShareEmailError.emailCompositionFailed)
            return
        }
        
        print("ShareExtension: Attempting to send email to: \(recipientEmail)")
        
        do {
            try composer.sendEmailAutomatically(
                content: content,
                recipientEmail: recipientEmail,
                presentingViewController: self,
                autoSend: true
            )
            print("ShareExtension: Email composer presented successfully")
        } catch let error as ShareEmailError {
            print("ShareExtension: ShareEmailError caught: \(error)")
            handleError(error)
        } catch {
            print("ShareExtension: Generic error caught: \(error)")
            handleError(ShareEmailError.sendingFailed(error))
        }
    }
    
    /// Shows email composition state
    private func showEmailCompositionState() {
        DispatchQueue.main.async {
            self.statusLabel.text = "Composing email..."
            self.statusLabel.textColor = UIColor.systemBlue
            self.activityIndicator.startAnimating()
        }
    }
    
    /// Handles successful email sending
    private func handleEmailSuccess() {
        showSuccessState()
        
        // Auto-dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismissExtension()
        }
    }
    
    /// Handles email sending failure
    private func handleEmailFailure(_ error: ShareEmailError) {
        handleError(error)
    }
    
    /// Handles email composition cancellation
    private func handleEmailCancellation() {
        // User cancelled email composition, dismiss extension
        dismissExtension()
    }
    
    /// Cleans up email composer resources
    private func cleanupEmailComposer() {
        emailComposer?.onSuccess = nil
        emailComposer?.onFailure = nil
        emailComposer?.onCancel = nil
        emailComposer = nil
    }
    
    // MARK: - Extension Context Management
    
    private func dismissExtension(with error: Error? = nil) {
        isProcessing = false
        cleanupEmailComposer()
        
        if let error = error {
            extensionContext?.cancelRequest(withError: error)
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    private func handleError(_ error: ShareEmailError) {
        let message = error.errorDescription ?? "An error occurred"
        print("Share Extension Error: \(message)")
        
        showErrorState(message: message)
        
        // Auto-dismiss after showing error
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let nsError = NSError(domain: "ShareExtensionError", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            self.dismissExtension(with: nsError)
        }
    }
    
    private func handleError(message: String) {
        handleError(ShareEmailError.contentProcessingFailed)
    }
}