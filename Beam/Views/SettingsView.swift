//
//  SettingsView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var database = DatabaseService.shared
    @State private var user: User?
    @State private var displayName = ""
    @State private var isEditingName = false
    @State private var enableDHTRelay = true
    @State private var autoDeleteEnabled = false
    @State private var autoDeleteDays = 7
    @State private var showingMyQR = false
    @State private var showingSaveConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        #if os(macOS)
        // macOS version without NavigationView split
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section with Avatar
                    VStack(spacing: 20) {
                        if let user = user {
                            // Avatar
                            AvatarView(name: user.displayName, size: 100)
                                .overlay(
                                    Circle()
                                        .stroke(Color.beamBlue, lineWidth: 3)
                                )
                            
                            // Editable Display Name
                            HStack(spacing: 12) {
                                if isEditingName {
                                    TextField("Display Name", text: $displayName)
                                        .font(.title2.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .textFieldStyle(.plain)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(8)
                                        .foregroundColor(.primary)
                                } else {
                                    Text(user.displayName)
                                        .font(.title2.weight(.semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: {
                                    if isEditingName {
                                        saveSettings()
                                        showingSaveConfirmation = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showingSaveConfirmation = false
                                        }
                                    }
                                    isEditingName.toggle()
                                }) {
                                    Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(isEditingName ? .green : .beamBlue)
                                }
                                .buttonStyle(.plain)
                                .help(isEditingName ? "Save" : "Edit Name")
                            }
                            
                            // Save confirmation
                            if showingSaveConfirmation {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Saved")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .transition(.opacity)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Beam ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(user.beamId)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.primary)
                                    
                                    Button(action: copyBeamId) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.beamBlue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showingMyQR = true }) {
                                Label("Show My QR Code", systemImage: "qrcode")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.beamBlue)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    
                    // Settings Section  
                    VStack(spacing: 0) {
                        SettingToggleRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Enable DHT Relay",
                            description: "Use DHT network when direct connection unavailable",
                            isOn: $enableDHTRelay
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        SettingToggleRow(
                            icon: "clock.arrow.circlepath",
                            title: "Auto-delete messages",
                            description: "Automatically delete messages after \(autoDeleteDays) days",
                            isOn: $autoDeleteEnabled
                        )
                        
                        if autoDeleteEnabled {
                            HStack {
                                Text("Delete after")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Picker("Days", selection: $autoDeleteDays) {
                                    Text("7 days").tag(7)
                                    Text("30 days").tag(30)
                                    Text("90 days").tag(90)
                                }
                                .pickerStyle(.menu)
                            }
                            .padding()
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Debug Section
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "ant.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reset Encryption Sessions")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Clear all session states if messages won't decrypt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Reset") {
                                KeychainService.shared.deleteAllSessionStates()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                        .padding()
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 20)
                }
                .padding(.vertical)
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .sheet(isPresented: $showingMyQR) {
            MyQRCodeView()
        }
        .onAppear {
            loadUser()
        }
        .onChange(of: enableDHTRelay) { _ in
            saveSettings()
        }
        .onChange(of: autoDeleteEnabled) { _ in
            saveSettings()
        }
        .onChange(of: autoDeleteDays) { _ in
            saveSettings()
        }
        #else
        // iOS version with NavigationView
        NavigationView {
            ZStack {
                Color.beamBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section with Avatar
                        VStack(spacing: 20) {
                            if let user = user {
                                // Avatar
                                AvatarView(name: user.displayName, size: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.beamBlue, lineWidth: 3)
                                    )
                                
                                // Editable Display Name
                                HStack(spacing: 12) {
                                    if isEditingName {
                                        TextField("Display Name", text: $displayName)
                                            .font(.title2.weight(.semibold))
                                            .multilineTextAlignment(.center)
                                            .textFieldStyle(.plain)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                    } else {
                                        Text(user.displayName)
                                            .font(.title2.weight(.semibold))
                                    }
                                    
                                    Button(action: {
                                        if isEditingName {
                                            saveSettings()
                                            showingSaveConfirmation = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                showingSaveConfirmation = false
                                            }
                                        }
                                        isEditingName.toggle()
                                    }) {
                                        Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(isEditingName ? .green : .beamBlue)
                                    }
                                    .help(isEditingName ? "Save" : "Edit Name")
                                }
                                
                                // Save confirmation
                                if showingSaveConfirmation {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Saved")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .transition(.opacity)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("Beam ID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text(user.beamId)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.primary)
                                        
                                        Button(action: copyBeamId) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.beamBlue)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: { showingMyQR = true }) {
                                    Label("Show My QR Code", systemImage: "qrcode")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.beamBlue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        
                        // Settings Section
                        VStack(spacing: 0) {
                            SettingToggleRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Enable DHT Relay",
                                description: "Use DHT network when direct connection unavailable",
                                isOn: $enableDHTRelay
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            SettingToggleRow(
                                icon: "clock.arrow.circlepath",
                                title: "Auto-delete messages",
                                description: "Automatically delete messages after \(autoDeleteDays) days",
                                isOn: $autoDeleteEnabled
                            )
                            
                            if autoDeleteEnabled {
                                HStack {
                                    Text("Delete after")
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Picker("Days", selection: $autoDeleteDays) {
                                        Text("7 days").tag(7)
                                        Text("30 days").tag(30)
                                        Text("90 days").tag(90)
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                                .padding()
                                .background(Color.white)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Debug Section
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "ant.fill")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reset Encryption Sessions")
                                        .font(.headline)
                                    Text("Clear all session states if messages won't decrypt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Reset") {
                                    KeychainService.shared.deleteAllSessionStates()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // About Section
                        VStack(spacing: 0) {
                            SettingRow(icon: "info.circle", title: "About Beam")
                            Divider().padding(.leading, 60)
                            SettingRow(icon: "hand.raised.fill", title: "Privacy Policy")
                            Divider().padding(.leading, 60)
                            SettingRow(icon: "doc.text", title: "Terms of Service")
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingMyQR) {
                MyQRCodeView()
            }
            .onAppear {
                loadUser()
            }
            .onChange(of: enableDHTRelay) { _ in
                saveSettings()
            }
            .onChange(of: autoDeleteEnabled) { _ in
                saveSettings()
            }
            .onChange(of: autoDeleteDays) { _ in
                saveSettings()
            }
        }
        #endif
    }
    
    private func loadUser() {
        user = database.getCurrentUser()
        if let user = user {
            displayName = user.displayName
            enableDHTRelay = user.enableDHTRelay
            autoDeleteDays = user.autoDeleteDays ?? 7
            autoDeleteEnabled = user.autoDeleteDays != nil
        }
    }
    
    private func saveSettings() {
        guard var user = user else { return }
        
        user.displayName = displayName
        user.enableDHTRelay = enableDHTRelay
        user.autoDeleteDays = autoDeleteEnabled ? autoDeleteDays : nil
        
        database.saveUser(user)
        self.user = user
    }
    
    private func copyBeamId() {
        if let user = user {
            #if canImport(UIKit)
            UIPasteboard.general.string = user.beamId
            #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(user.beamId, forType: .string)
            #endif
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.beamBlue)
                .frame(width: 28)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct SettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.beamBlue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
    }
}
