//
//  Contact.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation

struct Contact: Identifiable, Codable, Hashable {
    let id: String // Beam ID (SHA256 of public key)
    var name: String
    var publicKey: String // Ed25519 signing public key (base64)
    var keyAgreementKey: String // X25519 key agreement public key (base64)
    var avatar: String? // Base64 encoded or path
    var lastSeen: Date?
    var createdAt: Date
    var isMuted: Bool
    
    init(id: String, 
         name: String, 
         publicKey: String, 
         keyAgreementKey: String = "",
         avatar: String? = nil, 
         lastSeen: Date? = nil, 
         createdAt: Date = Date(), 
         isMuted: Bool = false) {
        self.id = id
        self.name = name
        self.publicKey = publicKey
        self.keyAgreementKey = keyAgreementKey.isEmpty ? publicKey : keyAgreementKey
        self.avatar = avatar
        self.lastSeen = lastSeen
        self.createdAt = createdAt
        self.isMuted = isMuted
    }
    
    // Create from contact card
    static func from(card: ContactCard) -> Contact {
        return Contact(
            id: card.beamId,
            name: card.displayName,
            publicKey: card.signingKeyEd25519,
            keyAgreementKey: card.keyAgreementX25519,
            createdAt: ISO8601DateFormatter().date(from: card.createdAt) ?? Date()
        )
    }
}
