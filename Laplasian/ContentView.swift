//
//  ContentView.swift
//  Laplasian
//
//  Created by Andrii Ieroshevych on 16.08.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @StateObject private var settingsManager = SettingsManager()
    @State private var showingEmailConfiguration = false

    var body: some View {
        NavigationSplitView {
            VStack {
                // Email Configuration Status Section
                emailConfigurationStatus
                
                // Main Content List
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Laplasian")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingEmailConfiguration = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEmailConfiguration) {
                EmailConfigurationView()
            }
            .onAppear {
                settingsManager.refreshConfiguration()
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private var emailConfigurationStatus: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: settingsManager.isConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(settingsManager.isConfigured ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Configuration")
                        .font(.headline)
                    
                    Text(configurationStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Configure") {
                    showingEmailConfiguration = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if !settingsManager.isConfigured {
                Text("Configure your email address to enable sharing content from other apps.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }
    
    private var configurationStatusText: String {
        if settingsManager.isConfigured {
            if let email = settingsManager.getEmailAddress() {
                return "Configured: \(email)"
            } else {
                return "Configured"
            }
        } else {
            return "Not configured - sharing disabled"
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
