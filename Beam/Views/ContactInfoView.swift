//
//  ContactInfoView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContactInfoView: View {
    let contact: Contact
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var database = DatabaseService.shared
    @StateObject private var messageService = MessageService.shared
    @State private var showingQRScanner = false
    @State private var showingContactQR = false
    @State private var isMuted = false
    @State private var showingDeleteConfirmation = false
    @State private var shouldPopToRoot = false
    
    var body: some View {
        #if os(macOS)
        // macOS: Show content directly without NavigationView wrapper
        contentView
        #else
        // iOS: Use NavigationView with toolbar
        NavigationView {
            contentView
                .navigationTitle("Contact Info")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { 
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Chat")
                                    .font(.body)
                            }
                            .foregroundColor(.beamBlue)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.beamBlue)
                    }
                }
        }
        .navigationViewStyle(.stack)
        #endif
    }
    
    var contentView: some View {
        VStack(spacing: 0) {
            // Header with contact info
            VStack(spacing: 16) {
                AvatarView(name: contact.name, size: 80)
                
                Text(contact.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let lastSeen = contact.lastSeen {
                    Text("Last seen \(lastSeen.timeAgo())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            #if os(macOS)
            .background(Color(NSColor.textBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif
            
            // Info sections
            ScrollView {
                VStack(spacing: 0) {
                    // Encryption section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.title2)
                                    .foregroundColor(.beamBlue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End-to-End Encrypted")
                                        .font(.headline)
                                    
                                    Text("Messages are secured with encryption")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Contact details
                    VStack(alignment: .leading, spacing: 0) {
                        DetailRow(label: "Beam ID", value: contact.id)
                        Divider().padding(.leading, 16)
                        DetailRow(label: "Public Key", value: String(contact.publicKey.prefix(32)) + "...")
                    }
                    #if os(macOS)
                    .background(Color(NSColor.controlBackgroundColor))
                    #else
                    .background(Color(UIColor.secondarySystemBackground))
                    #endif
                    
                    Divider()
                    
                    // Actions
                    VStack(alignment: .leading, spacing: 0) {
                        ActionButton(
                            icon: isMuted ? "bell.fill" : "bell.slash.fill", 
                            title: isMuted ? "Unmute Notifications" : "Mute Notifications", 
                            color: isMuted ? .green : .orange
                        ) {
                            toggleMute()
                        }
                        
                        Divider().padding(.leading, 56)
                        
                        ActionButton(icon: "trash.fill", title: "Delete Chat", color: .red) {
                            showingDeleteConfirmation = true
                        }
                    }
                    #if os(macOS)
                    .background(Color(NSColor.controlBackgroundColor))
                    #else
                    .background(Color(UIColor.secondarySystemBackground))
                    #endif
                    .padding(.top, 20)
                }
            }
            #if os(macOS)
            .background(Color(NSColor.textBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif
        }
        .sheet(isPresented: $showingQRScanner) {
            VerificationScannerView(contact: contact, isPresented: $showingQRScanner)
        }
        .sheet(isPresented: $showingContactQR) {
            ContactQRCodeView(contact: contact)
        }
        .alert("Delete Chat", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteChat()
            }
        } message: {
            Text("Are you sure you want to delete \(contact.name)? This will delete the contact and all messages.")
        }
        .onAppear {
            // Load mute status from contact
            isMuted = contact.isMuted
        }
    }
    
    private func toggleMute() {
        isMuted.toggle()
        // Save the mute preference to the database
        database.updateContactMuteStatus(contactId: contact.id, isMuted: isMuted)
    }
    
    private func deleteChat() {
        #if os(macOS)
        // macOS: Clear selection FIRST, before deleting
        NotificationCenter.default.post(
            name: NSNotification.Name("DeselectContact"),
            object: nil,
            userInfo: ["contactId": contact.id]
        )
        
        // Small delay to let the deselection complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Delete contact and all messages
            self.database.deleteContact(self.contact.id)
            self.database.deleteAllMessages(for: self.contact.id)
            self.messageService.messages.removeValue(forKey: self.contact.id)
            self.messageService.loadMessages()
            
            // Notify ChatListView to refresh
            NotificationCenter.default.post(
                name: NSNotification.Name("ChatDeleted"),
                object: nil,
                userInfo: ["contactId": self.contact.id]
            )
        }
        #else
        // Delete contact and all messages from database
        database.deleteContact(contact.id)
        database.deleteAllMessages(for: contact.id)
        
        // Clear from message service
        messageService.messages.removeValue(forKey: contact.id)
        
        // Reload messages to sync state
        messageService.loadMessages()
        
        // iOS: Post notification BEFORE dismissing to queue the navigation change
        NotificationCenter.default.post(
            name: NSNotification.Name("ChatDeleted"),
            object: nil,
            userInfo: ["contactId": contact.id]
        )
        
        // Dismiss this view - let the transition complete before any other navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            presentationMode.wrappedValue.dismiss()
        }
        #endif
    }
}

// New view for showing contact's QR code
struct ContactQRCodeView: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    AvatarView(name: contact.name, size: 60)
                    
                    Text(contact.name)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("Scan this QR code to verify the contact's identity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)
                
                // QR Code with contact's Beam ID
                Group {
                    #if os(macOS)
                    Image(nsImage: generateQRCode(from: contact.id))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                    #else
                    Image(uiImage: generateQRCode(from: contact.id))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                    #endif
                }
                .frame(width: 240, height: 240)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4)
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.beamBlue)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
            #if os(macOS)
            .background(Color(NSColor.textBackgroundColor))
            #else
            .background(Color(UIColor.systemBackground))
            #endif
        }
        .frame(width: 420, height: 580)
    }
    
    #if os(macOS)
    private func generateQRCode(from string: String) -> NSImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let rep = NSCIImageRep(ciImage: outputImage)
            let image = NSImage(size: rep.size)
            image.addRepresentation(rep)
            return image
        }
        
        return NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil) ?? NSImage()
    }
    #else
    private func generateQRCode(from string: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    #endif
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// Scanner view for verifying contact QR code
struct VerificationScannerView: View {
    let contact: Contact
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @State private var scannedCode: String?
    @State private var verificationResult: VerificationResult?
    
    enum VerificationResult {
        case success
        case mismatch
        case invalid
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Verify \(contact.name)")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            #if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
            #else
            .background(Color(UIColor.secondarySystemBackground))
            #endif
            
            Divider()
            
            ZStack {
                // Camera preview would go here
                Color.black
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Scan \(contact.name)'s QR code")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Ask them to show their QR code from Settings")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    
                    // Scan border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(verificationColor, lineWidth: 3)
                        .frame(width: 260, height: 260)
                    
                    // Verification status
                    if let result = verificationResult {
                        VStack(spacing: 12) {
                            Image(systemName: verificationIcon(for: result))
                                .font(.system(size: 50))
                                .foregroundColor(verificationColor)
                            
                            Text(verificationMessage(for: result))
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if result == .success {
                                Button("Done") {
                                    dismiss()
                                    isPresented = false
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .padding(.top, 8)
                            } else {
                                Button("Try Again") {
                                    verificationResult = nil
                                    scannedCode = nil
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .padding(.top, 8)
                            }
                        }
                        .padding(.bottom, 60)
                    } else {
                        Text("Camera preview requires physical device")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 60)
                    }
                }
            }
        }
        .frame(width: 420, height: 580)
        .onAppear {
            // Simulate scanning for demo (would use actual camera on device)
            simulateScan()
        }
    }
    
    private var verificationColor: Color {
        guard let result = verificationResult else { return .beamBlue }
        switch result {
        case .success: return .green
        case .mismatch: return .orange
        case .invalid: return .red
        }
    }
    
    private func verificationIcon(for result: VerificationResult) -> String {
        switch result {
        case .success: return "checkmark.shield.fill"
        case .mismatch: return "exclamationmark.shield.fill"
        case .invalid: return "xmark.shield.fill"
        }
    }
    
    private func verificationMessage(for result: VerificationResult) -> String {
        switch result {
        case .success:
            return "✓ Verified!\n\(contact.name)'s identity confirmed"
        case .mismatch:
            return "⚠️ Warning!\nBeam ID doesn't match this contact"
        case .invalid:
            return "✗ Invalid QR Code\nPlease scan a valid Beam QR code"
        }
    }
    
    private func simulateScan() {
        // In real implementation, this would use camera to scan QR code
        // For now, simulate after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Simulate successful verification
            scannedCode = contact.id
            verifyScannedCode(scannedCode!)
        }
    }
    
    private func verifyScannedCode(_ code: String) {
        if code == contact.id {
            verificationResult = .success
        } else if code.starts(with: "beam_") {
            verificationResult = .mismatch
        } else {
            verificationResult = .invalid
        }
    }
}
