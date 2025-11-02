//
//  MessageService.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation
import Combine

class MessageService: ObservableObject {
    static let shared = MessageService()
    
    @Published var messages: [String: [Message]] = [:] // contactId: [messages]
    
    private let database = DatabaseService.shared
    private let encryption = EncryptionService.shared
    
    private init() {
        loadMessages()
    }
    
    // MARK: - Load Messages
    func loadMessages() {
        DispatchQueue.main.async {
            let contacts = self.database.getContacts()
            for contact in contacts {
                let msgs = self.database.getMessages(for: contact.id)
                self.messages[contact.id] = msgs
            }
            // @Published automatically triggers objectWillChange
        }
    }
    
    // MARK: - Load Messages for Specific Contact (more efficient)
    func loadMessages(for contactId: String) {
        DispatchQueue.main.async {
            let msgs = self.database.getMessages(for: contactId)
            self.messages[contactId] = msgs
            // @Published automatically triggers objectWillChange
        }
    }
    
    // MARK: - Load Messages and Mark as Read (combined)
    func loadAndMarkAsRead(contactId: String) {
        DispatchQueue.main.async {
            self.database.markAllMessagesAsRead(for: contactId)
            self.loadMessages(for: contactId) // Only reload this specific contact
            
            // Post notification to update unread counts
            NotificationCenter.default.post(
                name: NSNotification.Name("MessagesMarkedAsRead"),
                object: nil,
                userInfo: ["contactId": contactId]
            )
        }
    }
    
    // MARK: - Send Message
    func sendMessage(content: String, to contactId: String) {
        guard let contact = database.getContacts().first(where: { $0.id == contactId }) else {
            return
        }
        
        // Encrypt message
        let encryptedContent = encryption.encrypt(message: content, with: contact.publicKey)
        
        // Create message
        let message = Message(
            contactId: contactId,
            content: content,
            encryptedContent: encryptedContent,
            isSent: true,
            timestamp: Date(),
            status: .sending
        )
        
        // Save to database
        database.saveMessage(message)
        
        // Update local messages
        if messages[contactId] == nil {
            messages[contactId] = []
        }
        messages[contactId]?.append(message)
        
        // Send via mesh network (peer-to-peer)
        MeshService.shared.sendMessage(message, to: contact)
    }
    
    // MARK: - Receive Message
    func receiveMessage(_ message: Message) {
        // Decrypt message content
        // let decryptedContent = encryption.decrypt(encryptedMessage: message.encryptedContent, with: privateKey)
        
        // Save to database
        database.saveMessage(message)
        
        // Update local messages
        if messages[message.contactId] == nil {
            messages[message.contactId] = []
        }
        messages[message.contactId]?.append(message)
    }
    
    // MARK: - Update Status
    func updateMessageStatus(messageId: String, status: MessageStatus) {
        for (contactId, msgs) in messages {
            if let index = msgs.firstIndex(where: { $0.id == messageId }) {
                messages[contactId]?[index].status = status
                database.saveMessage(messages[contactId]![index])
            }
        }
    }
    
    // MARK: - Mark as Read
    func markAsRead(contactId: String) {
        DispatchQueue.main.async {
            self.database.markAllMessagesAsRead(for: contactId)
            // Only reload this specific contact, not ALL contacts
            self.loadMessages(for: contactId)
            
            // Post notification to update unread counts
            NotificationCenter.default.post(
                name: NSNotification.Name("MessagesMarkedAsRead"),
                object: nil,
                userInfo: ["contactId": contactId]
            )
        }
    }
}
