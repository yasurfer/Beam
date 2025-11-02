//
//  SessionState.swift
//  Beam
//
//  Session state for Double-Ratchet encryption
//

import Foundation

struct SessionState: Codable {
    // Root key for deriving chain keys
    var rootKey: Data
    
    // Send chain state
    var sendChainKey: Data
    var sendCounter: UInt64
    
    // Receive chain state
    var receiveChainKey: Data
    var receiveCounter: UInt64
    
    // Ephemeral keys (optional, for forward secrecy upgrade)
    var myEphemeralPrivateKey: Data?
    var theirEphemeralPublicKey: Data?
    
    // Replay protection
    var seenMessageIndices: Set<UInt64>
    var seenNonces: Set<String>
    
    // Creation timestamp
    var createdAt: Date
    var lastUsed: Date
    
    init(rootKey: Data,
         sendChainKey: Data,
         receiveChainKey: Data) {
        self.rootKey = rootKey
        self.sendChainKey = sendChainKey
        self.sendCounter = 0
        self.receiveChainKey = receiveChainKey
        self.receiveCounter = 0
        self.seenMessageIndices = []
        self.seenNonces = []
        self.createdAt = Date()
        self.lastUsed = Date()
    }
    
    // MARK: - Session Management
    
    mutating func advanceSendChain() -> Data {
        // Derive message key
        let messageKey = CryptoService.shared.deriveMessageKey(from: sendChainKey, counter: sendCounter)
        
        // Advance chain
        sendChainKey = CryptoService.shared.advanceChainKey(sendChainKey)
        sendCounter += 1
        lastUsed = Date()
        
        return messageKey
    }
    
    mutating func advanceReceiveChain(to index: UInt64) -> Data? {
        // Ensure we haven't already processed this message
        guard !seenMessageIndices.contains(index) else {
            return nil
        }
        
        // Derive message key for this index
        let messageKey = CryptoService.shared.deriveMessageKey(from: receiveChainKey, counter: index)
        
        // Advance chain to this index
        while receiveCounter <= index {
            receiveChainKey = CryptoService.shared.advanceChainKey(receiveChainKey)
            receiveCounter += 1
        }
        
        seenMessageIndices.insert(index)
        lastUsed = Date()
        
        // Clean up old indices (keep last 1000)
        if seenMessageIndices.count > 1000 {
            let sorted = Array(seenMessageIndices).sorted()
            seenMessageIndices = Set(sorted.suffix(1000))
        }
        
        return messageKey
    }
    
    mutating func recordNonce(_ nonce: String) -> Bool {
        guard !seenNonces.contains(nonce) else {
            return false // Replay detected
        }
        
        seenNonces.insert(nonce)
        
        // Clean up old nonces (keep last 10000)
        if seenNonces.count > 10000 {
            let sorted = Array(seenNonces).sorted()
            seenNonces = Set(sorted.suffix(10000))
        }
        
        return true
    }
    
    // MARK: - Persistence
    
    func save(for contactId: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        try KeychainService.shared.saveSessionState(data, for: contactId)
    }
    
    static func load(for contactId: String) throws -> SessionState {
        let data = try KeychainService.shared.loadSessionState(for: contactId)
        let decoder = JSONDecoder()
        return try decoder.decode(SessionState.self, from: data)
    }
    
    static func delete(for contactId: String) throws {
        try KeychainService.shared.deleteSessionState(for: contactId)
    }
}
