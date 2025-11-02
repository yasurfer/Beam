//
//  EncryptionService.swift
//  Beam
//
//  Legacy wrapper around CryptoService for backward compatibility
//

import Foundation
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()
    
    private let crypto = CryptoService.shared
    
    private init() {}
    
    // MARK: - Key Generation (Legacy)
    func generateKeyPair() -> (publicKey: String, privateKey: String) {
        // Use new crypto service
        let signingKey = crypto.getMySigningPublicKey().base64EncodedString()
        let agreementKey = crypto.getMyKeyAgreementPublicKey().base64EncodedString()
        
        return (
            publicKey: signingKey,
            privateKey: agreementKey // Note: Don't expose private keys in production
        )
    }
    
    // MARK: - Encryption/Decryption (Legacy - for backward compatibility)
    func encrypt(message: String, with publicKey: String) -> String {
        // Simple base64 encoding for legacy compatibility
        // Real encryption happens through CryptoService
        let data = message.data(using: .utf8) ?? Data()
        return data.base64EncodedString()
    }
    
    func decrypt(encryptedMessage: String, with privateKey: String) -> String {
        // Simple base64 decoding for legacy compatibility
        guard let data = Data(base64Encoded: encryptedMessage),
              let decrypted = String(data: data, encoding: .utf8) else {
            return ""
        }
        return decrypted
    }
    
    // MARK: - Beam ID Generation
    func generateBeamId(from publicKey: String) -> String {
        // If publicKey is base64, decode it first
        if let keyData = Data(base64Encoded: publicKey) {
            return crypto.generateBeamId(from: keyData)
        }
        
        // Otherwise hash the string directly (legacy)
        guard let data = publicKey.data(using: .utf8) else {
            return ""
        }
        let hash = SHA256.hash(data: data)
        return "beam_" + hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).lowercased()
    }
    
    // MARK: - Simple Direct Encryption (No Sessions)
    
    func encryptMessage(plaintext: String, to contact: Contact) -> EncryptedMessage? {
        // SIMPLE: Just encrypt directly with recipient's public key
        return crypto.encryptDirectly(plaintext: plaintext, to: contact)
    }
    
    func decryptMessage(_ envelope: EncryptedMessage, from contact: Contact) -> String? {
        // SIMPLE: Just decrypt with our private key
        return crypto.decryptDirectly(envelope: envelope, from: contact)
    }
}
