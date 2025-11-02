//
//  DatabaseService.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation
import SQLite3

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    // Shared date formatter to avoid expensive allocations
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    private var db: OpaquePointer?
    private let dbPath: String
    private let dbQueue = DispatchQueue(label: "nl.getbeam.database", qos: .userInitiated)
    
    init() {
        // Create database folder in app documents
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let databaseFolder = documentsPath.appendingPathComponent("Database")
        
        // Create folder if it doesn't exist
        if !fileManager.fileExists(atPath: databaseFolder.path) {
            try? fileManager.createDirectory(at: databaseFolder, withIntermediateDirectories: true)
        }
        
        dbPath = databaseFolder.appendingPathComponent("beam.db").path
        
        openDatabase()
        createTables()
        
        // Sample data removed for production
        // Users will start with a clean database
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            // Database open failed
        }
    }
    
    private func createTables() {
        // Users table
        let createUsersTable = """
        CREATE TABLE IF NOT EXISTS users (
            beam_id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL,
            public_key TEXT NOT NULL,
            private_key TEXT NOT NULL,
            avatar TEXT,
            enable_dht_relay INTEGER DEFAULT 1,
            auto_delete_days INTEGER
        );
        """
        
        // Contacts table
        let createContactsTable = """
        CREATE TABLE IF NOT EXISTS contacts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            public_key TEXT NOT NULL,
            key_agreement_key TEXT NOT NULL DEFAULT '',
            avatar TEXT,
            last_seen TEXT,
            is_muted INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
        );
        """
        
        // Messages table
        let createMessagesTable = """
        CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            contact_id TEXT NOT NULL,
            content TEXT NOT NULL,
            encrypted_content TEXT NOT NULL,
            is_sent INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            status TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            is_encrypted INTEGER DEFAULT 0,
            FOREIGN KEY(contact_id) REFERENCES contacts(id)
        );
        """
        
        executeSQL(createUsersTable)
        executeSQL(createContactsTable)
        executeSQL(createMessagesTable)
        
        // Migration: Add is_muted column if it doesn't exist
        migrateDatabase()
    }
    
    private func migrateDatabase() {
        // Migration 1: Add is_muted column if it doesn't exist
        if !columnExists(table: "contacts", column: "is_muted") {
            let addMutedColumn = "ALTER TABLE contacts ADD COLUMN is_muted INTEGER DEFAULT 0;"
            executeSQL(addMutedColumn)
        }
        
        // Migration 2: Add key_agreement_key column if it doesn't exist
        if !columnExists(table: "contacts", column: "key_agreement_key") {
            let addKeyAgreementColumn = "ALTER TABLE contacts ADD COLUMN key_agreement_key TEXT NOT NULL DEFAULT '';"
            executeSQL(addKeyAgreementColumn)
        }
    }
    
    private func columnExists(table: String, column: String) -> Bool {
        let sql = "PRAGMA table_info(\(table));"
        var statement: OpaquePointer?
        var exists = false
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let namePtr = sqlite3_column_text(statement, 1) {
                    let columnName = String(cString: namePtr)
                    if columnName == column {
                        exists = true
                        break
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        return exists
    }
    
    private func executeSQL(_ sql: String, ignoreErrors: Bool = false) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Insert Sample Data
    private func insertSampleData() {
        // Check if data already exists
        if getContacts().isEmpty {
            // Insert sample user
            let user = User(
                beamId: "beam_user_" + UUID().uuidString.prefix(8).lowercased(),
                displayName: "Me",
                publicKey: "sample_public_key_12345",
                privateKey: "sample_private_key_67890",
                enableDHTRelay: true,
                autoDeleteDays: nil
            )
            saveUser(user)
            
            // Insert sample contacts with more realistic data
            let sampleContacts = [
                ("Alice Johnson", "Hey! How are you doing?", -3600.0, true),
                ("Bob Smith", "Meeting at 3pm tomorrow?", -7200.0, false),
                ("Carol Williams", "Thanks for the files!", -86400.0, false),
                ("David Brown", "Can you review my PR?", -172800.0, true),
                ("Emma Davis", "Great work on the presentation!", -259200.0, false),
                ("Frank Miller", "See you at the conference", -345600.0, true),
                ("Grace Wilson", "How's the project going?", -432000.0, false),
                ("Henry Moore", "Did you get my email?", -518400.0, true)
            ]
            
            for (index, (name, lastMsg, timeOffset, hasUnread)) in sampleContacts.enumerated() {
                let contact = Contact(
                    id: "beam_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(index)",
                    name: name,
                    publicKey: "pub_key_\(index)",
                    lastSeen: Date().addingTimeInterval(timeOffset)
                )
                saveContact(contact)
                
                // Add extended message history for first contact (50 messages for scrolling test)
                // Add normal message history for other contacts (2-8 messages)
                let messageCount = index == 0 ? 50 : Int.random(in: 2...8)
                
                // Sample conversation messages
                let conversationMessages = [
                    "Hey! How are you doing?",
                    "I'm good, thanks! How about you?",
                    "Doing great! Just finished a big project.",
                    "That's awesome! Congratulations!",
                    "Thanks! It was a lot of work.",
                    "I can imagine. You must be relieved.",
                    "Absolutely! Want to grab coffee later?",
                    "Sure! What time works for you?",
                    "How about 3pm?",
                    "Perfect! See you then 👍",
                    "Great! Looking forward to it",
                    "Me too! By the way, did you see the email?",
                    "Which one? I got a lot today 😅",
                    "The one about the meeting tomorrow",
                    "Oh yes! I'll be there",
                    "Excellent. We have a lot to discuss",
                    "Agreed. I've prepared some notes",
                    "Perfect! Can you share them?",
                    "Sure, I'll send them over now",
                    "Thanks! Really appreciate it",
                    "No problem at all!",
                    "So what's your take on the new proposal?",
                    "I think it has potential",
                    "Same here. Some details need work though",
                    "True. The timeline seems tight",
                    "Yeah, we might need to push back the deadline",
                    "I'll bring it up in the meeting",
                    "Good idea. Better to be realistic",
                    "Exactly. Quality over speed",
                    "Couldn't agree more 💯",
                    "By the way, how's your family?",
                    "They're doing well, thanks for asking!",
                    "That's great to hear 😊",
                    "How about yours?",
                    "All good! Kids are keeping us busy",
                    "I bet! How old are they now?",
                    "5 and 7. Time flies!",
                    "It really does!",
                    "Hey, I need to run. Talk later?",
                    "Of course! Take care",
                    "You too! 👋",
                    "See you at 3pm!",
                    "Don't forget to bring those documents",
                    "Already packed them 📄",
                    "You're so organized!",
                    "Trying my best 😄",
                    "Well it shows!",
                    "Thanks! That means a lot",
                    "Alright, talk soon!",
                    "See you! 🎉"
                ]
                
                for msgIndex in 0..<messageCount {
                    let isLast = msgIndex == messageCount - 1
                    let content: String
                    
                    if index == 0 && msgIndex < conversationMessages.count {
                        content = conversationMessages[msgIndex]
                    } else if isLast {
                        content = lastMsg
                    } else {
                        content = "Sample message \(msgIndex + 1)"
                    }
                    
                    let isSent = msgIndex % 2 == 0
                    let msgTimeOffset = timeOffset + Double(msgIndex * 300)
                    
                    let message = Message(
                        contactId: contact.id,
                        content: content,
                        encryptedContent: "enc_\(content)",
                        isSent: isSent,
                        timestamp: Date().addingTimeInterval(msgTimeOffset),
                        status: isSent ? .delivered : .read,
                        isRead: isSent ? false : !hasUnread || !isLast,
                        isEncrypted: true
                    )
                    saveMessage(message)
                }
            }
        }
    }
    
    // MARK: - User Operations
    
    /// Ensure current user exists with proper crypto-derived Beam ID
    func ensureUserExists() {
        let crypto = CryptoService.shared
        let correctBeamId = crypto.getMyBeamId()
        
        // Check if user already exists
        if let existingUser = getCurrentUser() {
            // Check if the existing Beam ID is in the wrong format (beam_user_xxx)
            if existingUser.beamId.hasPrefix("beam_user_") {
                // Delete old user and create new one with correct Beam ID
                deleteAllUsers()
                
                let newUser = User(
                    beamId: correctBeamId,
                    displayName: existingUser.displayName, // Keep the display name
                    publicKey: "", 
                    privateKey: "",
                    avatar: existingUser.avatar,
                    enableDHTRelay: existingUser.enableDHTRelay,
                    autoDeleteDays: existingUser.autoDeleteDays
                )
                
                saveUser(newUser)
                
                // Restart mesh service to pick up new ID
                DispatchQueue.main.async {
                    MeshService.shared.restart()
                }
                return
            }
            
            // Beam ID is already correct
            return
        }
        
        // Create new user with crypto-derived Beam ID
        let user = User(
            beamId: correctBeamId,
            displayName: "Me",
            publicKey: "",
            privateKey: "",
            enableDHTRelay: true,
            autoDeleteDays: nil
        )
        
        saveUser(user)
    }
    
    func saveUser(_ user: User) {
        dbQueue.sync {
            let sql = """
            INSERT OR REPLACE INTO users (beam_id, display_name, public_key, private_key, avatar, enable_dht_relay, auto_delete_days)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (user.beamId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (user.displayName as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (user.publicKey as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (user.privateKey as NSString).utf8String, -1, nil)
                if let avatar = user.avatar {
                    sqlite3_bind_text(statement, 5, (avatar as NSString).utf8String, -1, nil)
                }
                sqlite3_bind_int(statement, 6, user.enableDHTRelay ? 1 : 0)
                if let days = user.autoDeleteDays {
                    sqlite3_bind_int(statement, 7, Int32(days))
                }
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getCurrentUser() -> User? {
        return dbQueue.sync {
            let sql = "SELECT * FROM users LIMIT 1;"
            var statement: OpaquePointer?
            var user: User?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    let beamId = String(cString: sqlite3_column_text(statement, 0))
                    let displayName = String(cString: sqlite3_column_text(statement, 1))
                    let publicKey = String(cString: sqlite3_column_text(statement, 2))
                    let privateKey = String(cString: sqlite3_column_text(statement, 3))
                    let avatar = sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : nil
                    let enableDHT = sqlite3_column_int(statement, 5) == 1
                    let autoDelete = sqlite3_column_type(statement, 6) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 6)) : nil
                    
                    user = User(beamId: beamId, displayName: displayName, publicKey: publicKey, privateKey: privateKey, avatar: avatar, enableDHTRelay: enableDHT, autoDeleteDays: autoDelete)
                }
            }
            sqlite3_finalize(statement)
            return user
        }
    }
    
    private func deleteAllUsers() {
        dbQueue.sync {
            let sql = "DELETE FROM users;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Contact Operations
    func saveContact(_ contact: Contact) {
        dbQueue.sync {
            let sql = """
            INSERT OR REPLACE INTO contacts (id, name, public_key, key_agreement_key, avatar, last_seen, is_muted, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contact.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (contact.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (contact.publicKey as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (contact.keyAgreementKey as NSString).utf8String, -1, nil)
                if let avatar = contact.avatar {
                    sqlite3_bind_text(statement, 5, (avatar as NSString).utf8String, -1, nil)
                }
                if let lastSeen = contact.lastSeen {
                    sqlite3_bind_text(statement, 6, (Self.dateFormatter.string(from: lastSeen) as NSString).utf8String, -1, nil)
                }
                sqlite3_bind_int(statement, 7, contact.isMuted ? 1 : 0)
                sqlite3_bind_text(statement, 8, (Self.dateFormatter.string(from: contact.createdAt) as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getContacts() -> [Contact] {
        return dbQueue.sync {
            let sql = "SELECT * FROM contacts ORDER BY name;"
            var statement: OpaquePointer?
            var contacts: [Contact] = []
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let name = String(cString: sqlite3_column_text(statement, 1))
                    let publicKey = String(cString: sqlite3_column_text(statement, 2))
                    let keyAgreementKey = sqlite3_column_text(statement, 3) != nil ? String(cString: sqlite3_column_text(statement, 3)) : ""
                    let avatar = sqlite3_column_text(statement, 4) != nil ? String(cString: sqlite3_column_text(statement, 4)) : nil
                    
                    let lastSeenStr = sqlite3_column_text(statement, 5) != nil ? String(cString: sqlite3_column_text(statement, 5)) : nil
                    let lastSeen = lastSeenStr != nil ? Self.dateFormatter.date(from: lastSeenStr!) : nil
                    
                    let isMuted = sqlite3_column_int(statement, 6) == 1
                    
                    let createdAtStr = sqlite3_column_text(statement, 7) != nil ? String(cString: sqlite3_column_text(statement, 7)) : nil
                    let createdAt = createdAtStr != nil ? Self.dateFormatter.date(from: createdAtStr!) : nil
                    
                    contacts.append(Contact(
                        id: id,
                        name: name,
                        publicKey: publicKey,
                        keyAgreementKey: keyAgreementKey,
                        avatar: avatar,
                        lastSeen: lastSeen,
                        createdAt: createdAt ?? Date(),
                        isMuted: isMuted
                    ))
                }
            }
            sqlite3_finalize(statement)
            return contacts
        }
    }
    
    func deleteContact(_ contactId: String) {
        dbQueue.sync {
            let sql = "DELETE FROM contacts WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contactId as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func updateContactMuteStatus(contactId: String, isMuted: Bool) {
        dbQueue.sync {
            let sql = "UPDATE contacts SET is_muted = ? WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, isMuted ? 1 : 0)
                sqlite3_bind_text(statement, 2, (contactId as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Message Operations
    func saveMessage(_ message: Message) {
        dbQueue.sync {
            let sql = """
            INSERT OR REPLACE INTO messages (id, contact_id, content, encrypted_content, is_sent, timestamp, status, is_read, is_encrypted)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (message.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (message.contactId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (message.content as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (message.encryptedContent as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 5, message.isSent ? 1 : 0)
                sqlite3_bind_text(statement, 6, (Self.dateFormatter.string(from: message.timestamp) as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 7, (message.status.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 8, message.isRead ? 1 : 0)
                sqlite3_bind_int(statement, 9, message.isEncrypted ? 1 : 0)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getMessages(for contactId: String) -> [Message] {
        return dbQueue.sync {
            let sql = "SELECT * FROM messages WHERE contact_id = ? ORDER BY timestamp;"
            var statement: OpaquePointer?
            var messages: [Message] = []
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contactId as NSString).utf8String, -1, nil)
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let contactId = String(cString: sqlite3_column_text(statement, 1))
                    let content = String(cString: sqlite3_column_text(statement, 2))
                    let encryptedContent = String(cString: sqlite3_column_text(statement, 3))
                    let isSent = sqlite3_column_int(statement, 4) == 1
                    let timestampStr = String(cString: sqlite3_column_text(statement, 5))
                    let timestamp = Self.dateFormatter.date(from: timestampStr) ?? Date()
                    let statusStr = String(cString: sqlite3_column_text(statement, 6))
                    let status = MessageStatus(rawValue: statusStr) ?? .sent
                    let isRead = sqlite3_column_int(statement, 7) == 1
                    let isEncrypted = sqlite3_column_int(statement, 8) == 1
                    
                    messages.append(Message(id: id, contactId: contactId, content: content, encryptedContent: encryptedContent, isSent: isSent, timestamp: timestamp, status: status, isRead: isRead, isEncrypted: isEncrypted))
                }
            }
            sqlite3_finalize(statement)
            return messages
        }
    }
    
    func getLastMessage(for contactId: String) -> Message? {
        return dbQueue.sync {
            let sql = "SELECT * FROM messages WHERE contact_id = ? ORDER BY timestamp DESC LIMIT 1;"
            var statement: OpaquePointer?
            var message: Message?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contactId as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let contactId = String(cString: sqlite3_column_text(statement, 1))
                    let content = String(cString: sqlite3_column_text(statement, 2))
                    let encryptedContent = String(cString: sqlite3_column_text(statement, 3))
                    let isSent = sqlite3_column_int(statement, 4) == 1
                    let timestampStr = String(cString: sqlite3_column_text(statement, 5))
                    let timestamp = Self.dateFormatter.date(from: timestampStr) ?? Date()
                    let statusStr = String(cString: sqlite3_column_text(statement, 6))
                    let status = MessageStatus(rawValue: statusStr) ?? .sent
                    let isRead = sqlite3_column_int(statement, 7) == 1
                    
                    message = Message(id: id, contactId: contactId, content: content, encryptedContent: encryptedContent, isSent: isSent, timestamp: timestamp, status: status, isRead: isRead)
                }
            }
            sqlite3_finalize(statement)
            return message
        }
    }
    
    func getUnreadCount(for contactId: String) -> Int {
        return dbQueue.sync {
            let sql = "SELECT COUNT(*) FROM messages WHERE contact_id = ? AND is_sent = 0 AND is_read = 0;"
            var statement: OpaquePointer?
            var count = 0
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contactId as NSString).utf8String, -1, nil)
                if sqlite3_step(statement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(statement, 0))
                }
            }
            sqlite3_finalize(statement)
            
            return count
        }
    }
    
    func deleteMessage(id: String) {
        dbQueue.sync {
            let sql = "DELETE FROM messages WHERE id = ?;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func deleteAllMessages(for contactId: String) {
        dbQueue.sync {
            let sql = "DELETE FROM messages WHERE contact_id = ?;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contactId as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Mark All Messages as Read (Direct Database Update)
    func markAllMessagesAsRead(for contactId: String) {
        dbQueue.sync {
            let sql = "UPDATE messages SET is_read = 1 WHERE contact_id = ? AND is_sent = 0 AND is_read = 0;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (contactId as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func getMessage(by messageId: String) -> Message? {
        return dbQueue.sync {
            let sql = "SELECT * FROM messages WHERE id = ?;"
            var statement: OpaquePointer?
            var message: Message?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (messageId as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let contactId = String(cString: sqlite3_column_text(statement, 1))
                    let content = String(cString: sqlite3_column_text(statement, 2))
                    let encryptedContent = String(cString: sqlite3_column_text(statement, 3))
                    let isSent = sqlite3_column_int(statement, 4) == 1
                    let timestampStr = String(cString: sqlite3_column_text(statement, 5))
                    let timestamp = Self.dateFormatter.date(from: timestampStr) ?? Date()
                    let statusStr = String(cString: sqlite3_column_text(statement, 6))
                    let status = MessageStatus(rawValue: statusStr) ?? .sent
                    let isRead = sqlite3_column_int(statement, 7) == 1
                    let isEncrypted = sqlite3_column_int(statement, 8) == 1
                    
                    message = Message(
                        id: id,
                        contactId: contactId,
                        content: content,
                        encryptedContent: encryptedContent,
                        isSent: isSent,
                        timestamp: timestamp,
                        status: status,
                        isRead: isRead,
                        isEncrypted: isEncrypted
                    )
                }
            }
            sqlite3_finalize(statement)
            return message
        }
    }
    
    func updateMessage(_ message: Message) {
        dbQueue.sync {
            let sql = """
            UPDATE messages SET
                content = ?,
                encrypted_content = ?,
                status = ?,
                is_read = ?,
                is_encrypted = ?
            WHERE id = ?;
            """
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (message.content as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (message.encryptedContent as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (message.status.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 4, message.isRead ? 1 : 0)
                sqlite3_bind_int(statement, 5, message.isEncrypted ? 1 : 0)
                sqlite3_bind_text(statement, 6, (message.id as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
}
