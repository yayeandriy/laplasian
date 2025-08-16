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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section with email input
                VStack(spacing: 20) {
                    TextField("email@tosend.to", text: $emailInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            saveConfiguration()
                        }
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
                
                Spacer()
                
                // Logo positioned at 2/3 from bottom
                VStack {
                    Image(colorScheme == .dark ? "logo_white" : "logo_black")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width * 0.6)
                }
                .frame(height: geometry.size.height * 0.33)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            loadCurrentConfiguration()
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentConfiguration() {
        settingsManager.refreshConfiguration()
        emailInput = settingsManager.getEmailAddress() ?? ""
    }
    
    private func saveConfiguration() {
        settingsManager.saveEmailAddress(emailInput)
    }
}

#Preview {
    EmailConfigurationView()
}
