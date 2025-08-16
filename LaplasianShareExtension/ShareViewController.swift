import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    // MARK: - UI Elements
    private var titleLabel: UILabel!
    private var statusLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    private var containerView: UIView!
    
    // MARK: - State Management
    private var isProcessing = false
    
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
            self.statusLabel.text = "Content shared successfully!"
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
            handleError(message: "Extension context not available")
            return
        }
        
        // Validate extension context has input items
        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem],
              !inputItems.isEmpty else {
            handleError(message: "No content to share")
            return
        }
        
        // TODO: Implement actual content processing in future tasks
        // For now, simulate processing and show success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSuccessState()
            
            // Auto-dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismissExtension()
            }
        }
    }
    
    // MARK: - Extension Context Management
    
    private func dismissExtension(with error: Error? = nil) {
        isProcessing = false
        
        if let error = error {
            extensionContext?.cancelRequest(withError: error)
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
    private func handleError(message: String) {
        print("Share Extension Error: \(message)")
        
        showErrorState(message: message)
        
        // Auto-dismiss after showing error
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let error = NSError(domain: "ShareExtensionError", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            self.dismissExtension(with: error)
        }
    }
}