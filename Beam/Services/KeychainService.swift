//
//  KeychainService.swift
//  Beam
//
//  Secure storage for cryptographic keys using iOS Keychain
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Key Storage
    
    func saveKey(_ data: Data, identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete existing key first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func loadKey(identifier: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }
        
        return data
    }
    
    func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Convenience Methods for Beam Keys
    
    func saveIdentityKey(_ privateKey: Data) throws {
        try saveKey(privateKey, identifier: "beam.identity.ed25519.private")
    }
    
    func loadIdentityKey() throws -> Data {
        try loadKey(identifier: "beam.identity.ed25519.private")
    }
    
    func saveKeyAgreementKey(_ privateKey: Data) throws {
        try saveKey(privateKey, identifier: "beam.keyagreement.x25519.private")
    }
    
    func loadKeyAgreementKey() throws -> Data {
        try loadKey(identifier: "beam.keyagreement.x25519.private")
    }
    
    // Session state storage
    func saveSessionState(_ data: Data, for contactId: String) throws {
        try saveKey(data, identifier: "beam.session.\(contactId)")
    }
    
    func loadSessionState(for contactId: String) throws -> Data {
        try loadKey(identifier: "beam.session.\(contactId)")
    }
    
    func deleteSessionState(for contactId: String) throws {
        try deleteKey(identifier: "beam.session.\(contactId)")
    }
    
    // Delete all session states (useful for debugging/resetting encryption)
    func deleteAllSessionStates() {
        // Query for all session state items
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return
        }
        
        var deletedCount = 0
        for item in items {
            if let account = item[kSecAttrAccount as String] as? String,
               account.hasPrefix("beam.session.") {
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: account
                ]
                SecItemDelete(deleteQuery as CFDictionary)
                deletedCount += 1
            }
        }
        
    }
}

// MARK: - Errors

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}
