//
//  MeshService.swift
//  Beam
//
//  Peer-to-peer mesh networking using MultipeerConnectivity
//

import Foundation
import MultipeerConnectivity

class MeshService: NSObject, ObservableObject {
    static let shared = MeshService()
    
    // Published properties for UI
    @Published var connectedPeers: [MCPeerID] = []
    @Published var nearbyPeers: [MCPeerID] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var pendingContactRequests: [ContactCard] = []
    
    // Queue for offline messages
    private var offlineMessageQueue: [String: [Data]] = [:] // beamId: [messageData]
    private let queueLock = NSLock()
    
    // MultipeerConnectivity components
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    // Service type for Beam
    private let serviceType = "beam-mesh"
    
    // Discovery info with Beam ID
    private var discoveryInfo: [String: String] {
        if let user = DatabaseService.shared.getCurrentUser() {
            return ["beamId": user.beamId]
        }
        return [:]
    }
    
    private let database = DatabaseService.shared
    private let crypto = CryptoService.shared
    private let encryption = EncryptionService.shared
    private let messageService = MessageService.shared
    
    override private init() {
        super.init()
        setupPeerID()
        setupSession()
        setupAdvertiser()
        setupBrowser()
    }
    
    // MARK: - Setup
    
    private func setupPeerID() {
        // Use Beam ID as peer ID if available
        if let user = database.getCurrentUser() {
            peerID = MCPeerID(displayName: user.beamId)
        } else {
            // Fallback to UUID
            peerID = MCPeerID(displayName: UUID().uuidString)
        }
    }
    
    private func setupSession() {
        session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .none // Disable MC encryption, we have E2EE
        )
        session.delegate = self
    }
    
    private func setupAdvertiser() {
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser.delegate = self
    }
    
    private func setupBrowser() {
        browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: serviceType
        )
        browser.delegate = self
    }
    
    // MARK: - Public Methods
    
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
        isAdvertising = true
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
    }
    
    func startBrowsing() {
        browser.startBrowsingForPeers()
        isBrowsing = true
    }
    
    func stopBrowsing() {
        browser.stopBrowsingForPeers()
        isBrowsing = false
    }
    
    func start() {
        startAdvertising()
        startBrowsing()
    }
    
    func stop() {
        stopAdvertising()
        stopBrowsing()
    }
    
    func restart() {
        stop()
        
        // Reinitialize with new peer ID
        setupPeerID()
        setupSession()
        setupAdvertiser()
        setupBrowser()
        
        // Start again
        start()
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ message: Message, to contact: Contact) {
        // Encrypt the message first
        guard let encryptedEnvelope = encryption.encryptMessage(plaintext: message.content, to: contact) else {
            updateMessageStatus(message.id, status: .failed)
            return
        }
        
        // Create encrypted message packet
        let packet: [String: Any] = [
            "type": "message",
            "messageId": message.id,
            "from": encryptedEnvelope.from,
            "to": encryptedEnvelope.to,
            "ciphertext": encryptedEnvelope.ciphertext,
            "nonce": encryptedEnvelope.nonce,
            "signature": encryptedEnvelope.sig,
            "timestamp": message.timestamp.timeIntervalSince1970
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: packet) else {
            updateMessageStatus(message.id, status: .failed)
            return
        }
        
        // Find peer with matching Beam ID
        if let peer = findPeer(for: contact.id) {
            // Peer is ONLINE - send immediately
            do {
                try session.send(data, toPeers: [peer], with: .reliable)
                updateMessageStatus(message.id, status: .delivered)
            } catch let error as NSError {
                // SSLWrite errors (-9806) are common when connections drop temporarily
                if error.domain == "NSOSStatusErrorDomain" && error.code == -9806 {
                    queueOfflineMessage(data, for: contact.id)
                } else {
                    queueOfflineMessage(data, for: contact.id)
                }
            }
        } else {
            // Peer is OFFLINE - queue the message
            queueOfflineMessage(data, for: contact.id)
            updateMessageStatus(message.id, status: .sending)
        }
    }
    
    // MARK: - Offline Message Queue
    
    private func queueOfflineMessage(_ data: Data, for beamId: String) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if offlineMessageQueue[beamId] == nil {
            offlineMessageQueue[beamId] = []
        }
        offlineMessageQueue[beamId]?.append(data)
    }
    
    private func sendQueuedMessages(to beamId: String) {
        queueLock.lock()
        let queuedMessages = offlineMessageQueue[beamId] ?? []
        queueLock.unlock()
        
        guard !queuedMessages.isEmpty else { return }
        guard let peer = findPeer(for: beamId) else { return }
        
        // Clear queue before sending
        queueLock.lock()
        offlineMessageQueue[beamId] = nil
        queueLock.unlock()
        
        for data in queuedMessages {
            do {
                // Extract messageId from the packet to update status
                if let packet = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let messageId = packet["messageId"] as? String {
                    
                    try session.send(data, toPeers: [peer], with: .reliable)
                    updateMessageStatus(messageId, status: .delivered)
                } else {
                    // Fallback: send without status update if can't parse
                    try session.send(data, toPeers: [peer], with: .reliable)
                }
            } catch {
                queueOfflineMessage(data, for: beamId)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func findPeer(for beamId: String) -> MCPeerID? {
        return connectedPeers.first { $0.displayName == beamId }
    }
    
    private func updateMessageStatus(_ messageId: String, status: MessageStatus) {
        DispatchQueue.main.async {
            if var message = self.database.getMessage(by: messageId) {
                message.status = status
                self.database.updateMessage(message)
                // Only reload messages for this specific contact
                self.messageService.loadMessages(for: message.contactId)
            }
        }
    }
    
    // MARK: - Handshake Protocol
    
    private func sendHandshake(to peer: MCPeerID) {
        guard let myCard = crypto.getMyContactCard() else {
            return
        }
        
        // Check if peer is still connected before sending
        guard connectedPeers.contains(peer) else {
            return
        }
        
        // Create handshake packet with our contact card
        let packet: [String: Any] = [
            "type": "handshake_request",
            "contactCard": [
                "beamId": myCard.beamId,
                "displayName": myCard.displayName,
                "signingKeyEd25519": myCard.signingKeyEd25519,
                "keyAgreementX25519": myCard.keyAgreementX25519
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: packet)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            // Silently handle send errors - Multipeer will reconnect
        }
    }
    
    private func handleHandshakeRequest(_ data: Data, from peer: MCPeerID) {
        do {
            guard let packet = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cardDict = packet["contactCard"] as? [String: String],
                  let beamId = cardDict["beamId"],
                  let displayName = cardDict["displayName"],
                  let signingKeyEd25519 = cardDict["signingKeyEd25519"],
                  let keyAgreementX25519 = cardDict["keyAgreementX25519"] else {
                return
            }
            
            // ✅ IGNORE HANDSHAKES FROM OURSELVES (echo prevention)
            if let currentUser = database.getCurrentUser(), beamId == currentUser.beamId {
                return
            }
            
            // Check if we already have this contact
            let existingContact = database.getContacts().first { $0.id == beamId }
            
            if existingContact != nil {
                sendHandshakeAccept(to: peer)
                return
            }
            
            // Create contact card for pending request
            let contactCard = ContactCard(
                displayName: displayName,
                beamId: beamId,
                signingKeyEd25519: signingKeyEd25519,
                keyAgreementX25519: keyAgreementX25519
            )
            
            // Add to pending requests (UI will show notification)
            DispatchQueue.main.async {
                if !self.pendingContactRequests.contains(where: { $0.beamId == beamId }) {
                    self.pendingContactRequests.append(contactCard)
                    
                    // Post notification for UI
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NewContactRequest"),
                        object: nil,
                        userInfo: ["contactCard": contactCard]
                    )
                }
            }
            
        } catch {
            // Silently handle handshake errors
        }
    }
    
    func acceptContactRequest(_ contactCard: ContactCard) {
        // Create contact from card
        let contact = Contact.from(card: contactCard)
        
        database.saveContact(contact)
        
        // No need to initialize session - it will be created automatically on first message
        
        // Remove from pending
        DispatchQueue.main.async {
            self.pendingContactRequests.removeAll { $0.beamId == contactCard.beamId }
        }
        
        // Send acceptance to peer
        if let peer = findPeer(for: contactCard.beamId) {
            sendHandshakeAccept(to: peer)
        }
    }
    
    func rejectContactRequest(_ contactCard: ContactCard) {
        // Remove from pending
        DispatchQueue.main.async {
            self.pendingContactRequests.removeAll { $0.beamId == contactCard.beamId }
        }
        
        // Optionally send rejection to peer
        if let peer = findPeer(for: contactCard.beamId) {
            sendHandshakeReject(to: peer)
        }
    }
    
    // MARK: - Handshake Accept/Reject
    
    private func sendHandshakeAccept(to peer: MCPeerID) {
        guard let myCard = crypto.getMyContactCard() else {
            return
        }
        
        // Check if peer is still connected before sending
        guard connectedPeers.contains(peer) else {
            return
        }
        
        let packet: [String: Any] = [
            "type": "handshake_accept",
            "contactCard": [
                "beamId": myCard.beamId,
                "displayName": myCard.displayName,
                "signingKeyEd25519": myCard.signingKeyEd25519,
                "keyAgreementX25519": myCard.keyAgreementX25519
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: packet)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            // Silently handle send errors - Multipeer will reconnect
        }
    }
    
    private func sendHandshakeReject(to peer: MCPeerID) {
        let packet: [String: Any] = [
            "type": "handshake_reject"
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: packet)
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            // Silently handle send errors
        }
    }
    
    private func handleHandshakeAccept(_ data: Data, from peer: MCPeerID) {
        do {
            guard let packet = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cardDict = packet["contactCard"] as? [String: String],
                  let beamId = cardDict["beamId"],
                  let displayName = cardDict["displayName"],
                  let signingKeyEd25519 = cardDict["signingKeyEd25519"],
                  let keyAgreementX25519 = cardDict["keyAgreementX25519"] else {
                return
            }
            
            // ✅ IGNORE HANDSHAKE ACCEPTS FROM OURSELVES (echo prevention)
            if let currentUser = database.getCurrentUser(), beamId == currentUser.beamId {
                return
            }
            
            // Check if we already have this contact
            if database.getContacts().contains(where: { $0.id == beamId }) {
                return
            }
            
            // Create contact card and save
            let contactCard = ContactCard(
                displayName: displayName,
                beamId: beamId,
                signingKeyEd25519: signingKeyEd25519,
                keyAgreementX25519: keyAgreementX25519
            )
            
            let contact = Contact.from(card: contactCard)
            
            database.saveContact(contact)
            
            // No need to initialize session - it will be created automatically on first message
            
        } catch {
            // Silently handle errors
        }
    }
    
    private func handleHandshakeReject(_ data: Data, from peer: MCPeerID) {
        // Silently handle rejection
    }
    
    private func handlePlaintextMessage(_ packet: [String: Any], from peer: MCPeerID) {
        guard let messageId = packet["messageId"] as? String,
              let from = packet["from"] as? String,
              let to = packet["to"] as? String,
              let content = packet["content"] as? String,
              let timestampInterval = packet["timestamp"] as? TimeInterval else {
            return
        }
        
        // Get current user for validation
        guard let currentUser = database.getCurrentUser() else {
            return
        }
        
        // Validate the message is for us
        guard to == currentUser.beamId else {
            return
        }
        
        // Find contact
        guard let contact = database.getContacts().first(where: { $0.id == from }) else {
            return
        }
        
        // Save received message
        let message = Message(
            id: messageId,
            contactId: contact.id,
            content: content,
            encryptedContent: "",
            isSent: false,
            timestamp: Date(timeIntervalSince1970: timestampInterval),
            status: .delivered,
            isRead: false,
            isEncrypted: false
        )
        
        DispatchQueue.main.async {
            self.database.saveMessage(message)
            // Only reload messages for this specific contact
            self.messageService.loadMessages(for: contact.id)
            
            NotificationCenter.default.post(
                name: NSNotification.Name("NewMessageReceived"),
                object: nil,
                userInfo: ["contactId": contact.id]
            )
        }
    }
    
    private func handleReceivedMessage(_ data: Data, from peer: MCPeerID) {
        do {
            guard let packet = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = packet["type"] as? String else {
                return
            }
            
            // Route based on message type
            switch type {
            case "handshake_request":
                handleHandshakeRequest(data, from: peer)
                return
            case "handshake_accept":
                handleHandshakeAccept(data, from: peer)
                return
            case "handshake_reject":
                handleHandshakeReject(data, from: peer)
                return
            case "plaintext_message":
                handlePlaintextMessage(packet, from: peer)
                return
            case "message":
                break // Continue to handle encrypted message below
            default:
                return
            }
            
            // Handle encrypted message (type == "message")
            guard let messageId = packet["messageId"] as? String,
                  let from = packet["from"] as? String,
                  let to = packet["to"] as? String,
                  let ciphertext = packet["ciphertext"] as? String,
                  let nonce = packet["nonce"] as? String,
                  let sig = packet["signature"] as? String,
                  let timestampInterval = packet["timestamp"] as? TimeInterval else {
                return
            }
            
            // Get current user first for validation
            guard let currentUser = database.getCurrentUser() else {
                return
            }
            
            // ✅ IGNORE MESSAGES FROM OURSELVES (echo prevention)
            if from == currentUser.beamId {
                return
            }
            
            // Validate the message is for us
            guard to == currentUser.beamId else {
                return
            }
            
            // Find contact by Beam ID
            guard let contact = database.getContacts().first(where: { $0.id == from }) else {
                return
            }
            
            // ✅ DOUBLE-CHECK: Contact should not be ourselves (catch database corruption)
            if contact.id == currentUser.beamId {
                database.deleteContact(contact.id)
                return
            }
            
            // Create EncryptedMessage using wire format initializer
            let encryptedMessage = EncryptedMessage(
                v: 1,
                from: from,
                to: to,
                t: Int64(timestampInterval),
                rIdx: 0, // Will be extracted from session during decryption
                nonce: nonce,
                ciphertext: ciphertext,
                sig: sig
            )
            
            // Decrypt the message
            guard let decryptedContent = encryption.decryptMessage(encryptedMessage, from: contact) else {
                return
            }
            
            // Save received message
            let message = Message(
                id: messageId,
                contactId: contact.id,
                content: decryptedContent,
                encryptedContent: ciphertext,
                isSent: false,
                timestamp: Date(timeIntervalSince1970: timestampInterval),
                status: .delivered,
                isRead: false,
                isEncrypted: true
            )
            
            DispatchQueue.main.async {
                self.database.saveMessage(message)
                // Only reload messages for this specific contact
                self.messageService.loadMessages(for: contact.id)
                
                // Post notification for new message
                NotificationCenter.default.post(
                    name: NSNotification.Name("NewMessageReceived"),
                    object: nil,
                    userInfo: ["contactId": contact.id]
                )
            }
            
        } catch {
            // Silently handle errors
        }
    }
}

// MARK: - MCSessionDelegate

extension MeshService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                
                // Send handshake to establish identity
                self.sendHandshake(to: peerID)
                
                // Send any queued offline messages (with delay to ensure connection is stable)
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
                    self.sendQueuedMessages(to: peerID.displayName)
                }
                
            case .connecting:
                break
                
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handleReceivedMessage(data, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MeshService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept ALL invitations - we'll verify identity through QR code exchange
        // Messages can only be sent/received to/from contacts with public keys
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MeshService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Don't add ourselves
        guard peerID != self.peerID else { return }
        
        // Add to nearby peers list (only if not already there)
        DispatchQueue.main.async {
            if !self.nearbyPeers.contains(peerID) {
                self.nearbyPeers.append(peerID)
            }
        }
        
        // Invite the peer to connect
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.nearbyPeers.removeAll { $0 == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.isBrowsing = false
        }
    }
}
