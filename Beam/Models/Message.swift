//
//  Message.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

struct Message: Identifiable, Codable {
    let id: String
    let contactId: String
    let content: String
    let encryptedContent: String
    let isSent: Bool // true if sent by me, false if received
    let timestamp: Date
    var status: MessageStatus
    var isRead: Bool
    var isEncrypted: Bool
    
    // Convenience computed property
    var isFromMe: Bool { isSent }
    
    init(id: String = UUID().uuidString,
         contactId: String,
         content: String,
         encryptedContent: String = "",
         isSent: Bool,
         timestamp: Date = Date(),
         status: MessageStatus = .sending,
         isRead: Bool = false,
         isEncrypted: Bool = false) {
        self.id = id
        self.contactId = contactId
        self.content = content
        self.encryptedContent = encryptedContent.isEmpty ? content : encryptedContent
        self.isSent = isSent
        self.timestamp = timestamp
        self.status = status
        self.isRead = isRead
        self.isEncrypted = isEncrypted
    }
    
    // Alternative initializer matching macOS view usage
    init(id: String = UUID().uuidString,
         contactId: String,
         content: String,
         timestamp: Date = Date(),
         isFromMe: Bool,
         status: MessageStatus = .sending,
         isEncrypted: Bool = false) {
        self.id = id
        self.contactId = contactId
        self.content = content
        self.encryptedContent = content
        self.isSent = isFromMe
        self.timestamp = timestamp
        self.status = status
        self.isRead = false
        self.isEncrypted = isEncrypted
    }
}
