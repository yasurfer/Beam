//
//  ScanQRCodeView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI
import AVFoundation

@available(macOS 13.0, iOS 13.0, *)
struct ScanQRCodeView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @StateObject private var qrScanner = QRScannerViewModel()
    @StateObject private var database = DatabaseService.shared
    @StateObject private var messageService = MessageService.shared
    
    var body: some View {
        #if os(macOS)
        macOSContent
        #else
        iOSContent
        #endif
    }
    
    // MARK: - macOS Content
    #if os(macOS)
    var macOSContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Scan QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Close") {
                    qrScanner.stopScanning()
                    dismiss()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ZStack {
                // Camera preview
                QRScannerViewRepresentable(qrScanner: qrScanner)
                
                // Overlay
                VStack(spacing: 20) {
                    if qrScanner.scannedCode == nil && !qrScanner.hasError {
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 70))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            
                            Text("Position QR code within frame")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.top, 60)
                        
                        Spacer()
                        
                        // Scan border animation
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.beamBlue, lineWidth: 3)
                            .frame(width: 260, height: 260)
                        
                        Spacer()
                    } else if qrScanner.hasError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            
                            Text("Camera Access Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(qrScanner.errorMessage ?? "Please grant camera access in System Preferences")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("Open System Preferences")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.beamBlue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                qrScanner.reset()
                            }) {
                                Text("Try Again")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if let code = qrScanner.scannedCode {
                        successView(code: code)
                    }
                }
            }
        }
        .frame(width: 420, height: 580)
        .onDisappear {
            qrScanner.stopScanning()
        }
    }
    #endif
    
    // MARK: - iOS Content
    #if os(iOS)
    var iOSContent: some View {
        NavigationView {
            ZStack {
                // Camera preview
                QRScannerViewRepresentable(qrScanner: qrScanner)
                    .ignoresSafeArea()
                
                // Overlay
                VStack {
                    if qrScanner.scannedCode == nil && !qrScanner.hasError {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            
                            Text("Position QR code within frame")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        
                        Spacer()
                        
                        // Scan border
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.beamBlue, lineWidth: 4)
                            .frame(width: 280, height: 280)
                        
                        Spacer()
                    } else if qrScanner.hasError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            
                            Text("Camera Access Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(qrScanner.errorMessage ?? "Please grant camera access in Settings")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if let code = qrScanner.scannedCode {
                        successView(code: code)
                    }
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        qrScanner.stopScanning()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            qrScanner.stopScanning()
        }
    }
    #endif
    
    // MARK: - Success View
    func successView(code: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("QR Code Scanned!")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(code)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            
            Button("Add Contact") {
                addContact(from: code)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Button("Scan Another") {
                qrScanner.reset()
            }
            .foregroundColor(.white)
        }
        .padding()
    }
    
    // MARK: - Add Contact
    func addContact(from qrCode: String) {
        // Try to parse as ContactCard JSON
        if let contactCard = ContactCard.fromJSON(qrCode) {
            // Verify the contact card signature
            if contactCard.verify() {
                // Create and save contact immediately
                let contact = Contact.from(card: contactCard)
                database.saveContact(contact)
                
                qrScanner.stopScanning()
                dismiss()
                isPresented = false
            } else {
                // Invalid signature
                DispatchQueue.main.async {
                    qrScanner.hasError = true
                    qrScanner.errorMessage = "Invalid contact card - signature verification failed"
                    qrScanner.scannedCode = nil
                }
            }
        } else {
            // Not a valid ContactCard JSON
            DispatchQueue.main.async {
                qrScanner.hasError = true
                qrScanner.errorMessage = "Invalid QR code format"
                qrScanner.scannedCode = nil
            }
        }
    }
}

// MARK: - QR Scanner ViewModel
@available(macOS 13.0, iOS 13.0, *)
class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    @Published var hasError = false
    @Published var errorMessage: String?
    @Published var isSessionReady = false
    
    var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "qr.scanner.session")
    
    override init() {
        super.init()
        startScanning()
    }
    
    func startScanning() {
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }
    
    func stopScanning() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.scannedCode = nil
            self.hasError = false
            self.errorMessage = nil
        }
        startScanning()
    }
    
    private func setupCaptureSession() {
        // Check camera authorization status first
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Camera access denied. Please enable in System Preferences > Privacy & Security > Camera"
            }
            return
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession()
                } else {
                    DispatchQueue.main.async {
                        self?.hasError = true
                        self?.errorMessage = "Camera access is required to scan QR codes"
                    }
                }
            }
            return
            
        case .authorized:
            break
            
        @unknown default:
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Unknown camera authorization status"
            }
            return
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "No camera available"
            }
            session.commitConfiguration()
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Camera access denied: \(error.localizedDescription)"
            }
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Could not add video input"
            }
            session.commitConfiguration()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Check if QR code type is available before setting it
            if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                DispatchQueue.main.async {
                    self.hasError = true
                    self.errorMessage = "QR code scanning is not supported on this device"
                }
                session.commitConfiguration()
                return
            }
        } else {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Could not add metadata output"
            }
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        self.captureSession = session
        
        DispatchQueue.main.async {
            self.isSessionReady = true
        }
        
        session.startRunning()
    }
    
    // AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Found a QR code
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            scannedCode = stringValue
            stopScanning()
        }
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - UIKit/AppKit Representative
#if os(iOS)
@available(iOS 13.0, *)
struct QRScannerViewRepresentable: UIViewRepresentable {
    @ObservedObject var qrScanner: QRScannerViewModel
    
    class CameraPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        view.previewLayer.videoGravity = .resizeAspectFill
        
        if let session = qrScanner.captureSession {
            view.previewLayer.session = session
        }
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if uiView.previewLayer.session == nil, let session = qrScanner.captureSession {
            uiView.previewLayer.session = session
        }
    }
}
#else
@available(macOS 13.0, *)
struct QRScannerViewRepresentable: NSViewRepresentable {
    @ObservedObject var qrScanner: QRScannerViewModel
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Remove old preview layer if exists
        if let oldLayer = nsView.layer?.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) {
            oldLayer.removeFromSuperlayer()
        }
        
        // Add new preview layer when session is ready
        if qrScanner.isSessionReady, let previewLayer = qrScanner.previewLayer {
            previewLayer.frame = nsView.bounds
            nsView.layer?.insertSublayer(previewLayer, at: 0)
        }
    }
}
#endif
