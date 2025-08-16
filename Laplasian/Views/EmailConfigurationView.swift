//
//  EmailConfigurationView.swift
//  Laplasian
//
//  Created by Kiro on 16.08.2025.
//

import SwiftUI

struct EmailConfigurationView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var emailInput: String = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                
                emailInputSection
                
                validationFeedback
                
                Spacer()
                
                actionButtons
            }
            .padding()
            .navigationTitle("Email Configuration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentConfiguration()
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Email configuration saved successfully!")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") {
                    settingsManager.clearError()
                }
            } message: {
                Text(settingsManager.lastError?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Configure Email Address")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Set the email address where shared content will be sent automatically.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var emailInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
                .font(.headline)
            
            TextField("Enter email address", text: $emailInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: emailInput) { _, _ in
                    isEditing = true
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
    }
    
    private var validationFeedback: some View {
        HStack {
            if !emailInput.isEmpty {
                Image(systemName: isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isValidEmail ? .green : .red)
                
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(isValidEmail ? .green : .red)
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: emailInput)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: saveConfiguration) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Save Configuration")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!canSave)
            
            if settingsManager.isConfigured {
                Button(action: removeConfiguration) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove Configuration")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        settingsManager.isValidEmailFormat(emailInput)
    }
    
    private var canSave: Bool {
        !emailInput.isEmpty && isValidEmail && hasChanges
    }
    
    private var hasChanges: Bool {
        emailInput != (settingsManager.getEmailAddress() ?? "")
    }
    
    private var borderColor: Color {
        if emailInput.isEmpty {
            return .gray.opacity(0.3)
        }
        return isValidEmail ? .green : .red
    }
    
    private var validationMessage: String {
        if emailInput.isEmpty {
            return ""
        }
        return isValidEmail ? "Valid email address" : "Invalid email format"
    }
    
    // MARK: - Actions
    
    private func loadCurrentConfiguration() {
        settingsManager.refreshConfiguration()
        emailInput = settingsManager.getEmailAddress() ?? ""
        isEditing = false
    }
    
    private func saveConfiguration() {
        let success = settingsManager.saveEmailAddress(emailInput)
        
        if success {
            showingSuccessAlert = true
        } else {
            showingErrorAlert = true
        }
    }
    
    private func removeConfiguration() {
        let success = settingsManager.removeConfiguration()
        
        if success {
            emailInput = ""
            isEditing = false
        } else {
            showingErrorAlert = true
        }
    }
}

#Preview {
    EmailConfigurationView()
}