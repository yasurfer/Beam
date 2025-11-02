//
//  MyQRCodeView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MyQRCodeView: View {
    @StateObject private var database = DatabaseService.shared
    @StateObject private var crypto = CryptoService.shared
    @Environment(\.dismiss) var dismiss
    @State private var user: User?
    @State private var contactCard: ContactCard?
    
    var body: some View {
        #if os(macOS)
        // macOS version without NavigationView split
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("My QR Code")
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
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    if let user = user {
                        AvatarView(name: user.displayName, size: 60)
                        
                        Text(user.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 32)
                
                // QR Code with contact card
                if let card = contactCard, let qrData = card.toJSON() {
                    Image(nsImage: generateQRCode(from: qrData))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                }
                
                VStack(spacing: 8) {
                    if let card = contactCard {
                        Text("Beam ID: \(card.beamId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                        
                        Text("🔐 Cryptographically Signed")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: copyBeamId) {
                    Label("Copy Beam ID", systemImage: "doc.on.doc")
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
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(width: 420, height: 620)
        .onAppear {
            loadUserData()
        }
        #else
        // iOS version with NavigationView
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    if let user = user {
                        AvatarView(name: user.displayName, size: 80)
                        
                        Text(user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                // QR Code with contact card
                if let card = contactCard, let qrData = card.toJSON() {
                    #if canImport(UIKit)
                    Image(uiImage: generateQRCode(from: qrData))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                    #else
                    Image(nsImage: generateQRCode(from: qrData))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                    #endif
                }
                
                VStack(spacing: 8) {
                    if let card = contactCard {
                        Text("Beam ID: \(card.beamId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("🔐 Cryptographically Signed")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: copyBeamId) {
                    Label("Copy Beam ID", systemImage: "doc.on.doc")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.beamBlue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .background(Color.beamBackground.ignoresSafeArea())
            .navigationTitle("My QR Code")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadUserData()
        }
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func loadUserData() {
        user = database.getCurrentUser()
        if let user = user {
            contactCard = crypto.createContactCard(displayName: user.displayName)
            
            // DEBUG: Print contact card JSON to console
            if let card = contactCard, let _ = card.toJSON() {
            }
        }
    }
    
    #if canImport(UIKit)
    private func generateQRCode(from string: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    #else
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
    #endif
    
    private func copyBeamId() {
        guard let beamId = contactCard?.beamId else { return }
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(beamId, forType: .string)
        #else
        UIPasteboard.general.string = beamId
        #endif
    }
}
