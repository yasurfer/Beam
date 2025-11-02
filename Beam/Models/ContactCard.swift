//
//  ContactCard.swift
//  Beam
//
//  Contact card for QR code encoding
//

import Foundation

struct ContactCard: Codable {
    let type: String
    let version: String
    var displayName: String
    var beamId: String
    var signingKeyEd25519: String // Base64 encoded public key
    var keyAgreementX25519: String // Base64 encoded public key
    var createdAt: String // ISO8601 timestamp
    var signature: String // Base64 encoded signature
    
    init(displayName: String,
         beamId: String,
         signingKeyEd25519: String,
         keyAgreementX25519: String,
         createdAt: Date = Date()) {
        self.type = "beam_contact"
        self.version = "1.0"
        self.displayName = displayName
        self.beamId = beamId
        self.signingKeyEd25519 = signingKeyEd25519
        self.keyAgreementX25519 = keyAgreementX25519
        
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.string(from: createdAt)
        
        // Signature will be set separately
        self.signature = ""
    }
    
    // MARK: - Verification
    
    func verify() -> Bool {
        guard type == "beam_contact" else { return false }
        guard version == "1.0" else { return false }
        
        // Verify beamId matches signingKey
        guard let keyData = Data(base64Encoded: signingKeyEd25519) else { return false }
        let computedBeamId = CryptoService.shared.generateBeamId(from: keyData)
        guard beamId == computedBeamId else { return false }
        
        // Verify signature
        return CryptoService.shared.verifyContactCard(self)
    }
    
    // MARK: - Encoding for QR
    
    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func fromJSON(_ json: String) -> ContactCard? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(ContactCard.self, from: data)
    }
    
    // MARK: - Unsigned Data for Signing
    
    func unsignedData() -> Data? {
        // Create a copy without signature for signing
        var unsigned = self
        unsigned.signature = ""
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(unsigned)
    }
}
