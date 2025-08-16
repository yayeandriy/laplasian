//
//  ContentView.swift
//  Laplasian
//
//  Created by Andrii Ieroshevych on 16.08.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var emailInput: String = ""
    @State private var showCheckmark = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Invisible background to dismiss keyboard when tapped
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTextFieldFocused {
                        isTextFieldFocused = false
                    }
                }
            
            VStack(spacing: 0) {
                // Center the input field
                Spacer()
                
                HStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        TextField("email@tosend.to", text: $emailInput)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                saveConfiguration()
                            }
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        // Clear button - shows when focused and has text
                        if isTextFieldFocused && !emailInput.isEmpty {
                            Button(action: {
                                emailInput = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                            }
                            .padding(.trailing, 15)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    if showCheckmark {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                            .padding(.leading, 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // Logo at very bottom, ignoring safe area
            VStack {
                Spacer()
                
                Image(colorScheme == .dark ? "logo_white" : "logo_black")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6)
            }
            .ignoresSafeArea(.all, edges: .bottom)
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
        
        // Show checkmark with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showCheckmark = true
        }
        
        // Hide checkmark after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCheckmark = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
