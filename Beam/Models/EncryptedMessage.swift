//
//  EncryptedMessage.swift
//  Beam
//
//  Wire format for encrypted messages
//

import Foundation

struct EncryptedMessage: Codable {
    let v: Int // Protocol version
    var from: String // Sender's Beam ID
    var to: String // Recipient's Beam ID
    var t: Int64 // Unix timestamp (seconds)
    var rIdx: UInt64 // Ratchet index (send chain counter)
    var nonce: String // Base64 encoded 12-byte nonce
    var ciphertext: String // Base64 encoded encrypted data
    var sig: String // Base64 encoded Ed25519 signature
    
    init(from: String,
         to: String,
         rIdx: UInt64,
         nonce: Data,
         ciphertext: Data) {
        self.v = 1
        self.from = from
        self.to = to
        self.t = Int64(Date().timeIntervalSince1970)
        self.rIdx = rIdx
        self.nonce = nonce.base64EncodedString()
        self.ciphertext = ciphertext.base64EncodedString()
        self.sig = "" // Will be set after signing
    }
    
    // Wire format initializer (for received messages)
    init(v: Int, from: String, to: String, t: Int64, rIdx: UInt64,
         nonce: String, ciphertext: String, sig: String) {
        self.v = v
        self.from = from
        self.to = to
        self.t = t
        self.rIdx = rIdx
        self.nonce = nonce
        self.ciphertext = ciphertext
        self.sig = sig
    }
    
    // MARK: - Serialization
    
    func toJSON() -> String? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func fromJSON(_ json: String) -> EncryptedMessage? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(EncryptedMessage.self, from: data)
    }
    
    // MARK: - Signing
    
    func dataForSigning() -> Data? {
        // Create canonical representation for signing
        let parts = [
            String(v),
            from,
            to,
            String(t),
            String(rIdx),
            nonce,
            ciphertext
        ]
        let combined = parts.joined(separator: "|")
        return combined.data(using: .utf8)
    }
    
    // MARK: - Validation
    
    func isValid() -> Bool {
        guard v == 1 else { return false }
        guard !from.isEmpty, !to.isEmpty else { return false }
        guard Data(base64Encoded: nonce) != nil else { return false }
        guard Data(base64Encoded: ciphertext) != nil else { return false }
        guard Data(base64Encoded: sig) != nil else { return false }
        return true
    }
    
    func isTimely(maxAgeSecs: Int64 = 3600) -> Bool {
        let now = Int64(Date().timeIntervalSince1970)
        let age = abs(now - t)
        return age <= maxAgeSecs
    }
}
