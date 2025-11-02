//
//  CryptoService.swift
//  Beam
//
//  Core cryptographic operations for Beam
//  Implements Ed25519, X25519, ChaCha20-Poly1305, HKDF
//

import Foundation
import CryptoKit

class CryptoService: ObservableObject {
    static let shared = CryptoService()
    
    // My identity keys
    private var identityPrivateKey: Curve25519.Signing.PrivateKey?
    private var identityPublicKey: Curve25519.Signing.PublicKey?
    
    // My key agreement keys
    private var keyAgreementPrivateKey: Curve25519.KeyAgreement.PrivateKey?
    private var keyAgreementPublicKey: Curve25519.KeyAgreement.PublicKey?
    
    private init() {
        loadOrGenerateKeys()
    }
    
    // MARK: - Key Management
    
    private func loadOrGenerateKeys() {
        do {
            // Try to load existing keys from keychain
            let identityData = try KeychainService.shared.loadIdentityKey()
            identityPrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: identityData)
            identityPublicKey = identityPrivateKey?.publicKey
            
            let agreementData = try KeychainService.shared.loadKeyAgreementKey()
            keyAgreementPrivateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: agreementData)
            keyAgreementPublicKey = keyAgreementPrivateKey?.publicKey
        } catch {
            // Generate new keys on first launch
            generateAndSaveKeys()
        }
    }
    
    private func generateAndSaveKeys() {
        // Generate Ed25519 signing key pair
        identityPrivateKey = Curve25519.Signing.PrivateKey()
        identityPublicKey = identityPrivateKey?.publicKey
        
        // Generate X25519 key agreement key pair
        keyAgreementPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        keyAgreementPublicKey = keyAgreementPrivateKey?.publicKey
        
        // Save to keychain
        do {
            if let identityKey = identityPrivateKey {
                try KeychainService.shared.saveIdentityKey(identityKey.rawRepresentation)
            }
            if let agreementKey = keyAgreementPrivateKey {
                try KeychainService.shared.saveKeyAgreementKey(agreementKey.rawRepresentation)
            }
        } catch {
            // Failed to save keys
        }
    }
    
    // MARK: - Public Key Access
    
    func getMySigningPublicKey() -> Data {
        return identityPublicKey?.rawRepresentation ?? Data()
    }
    
    func getMyKeyAgreementPublicKey() -> Data {
        return keyAgreementPublicKey?.rawRepresentation ?? Data()
    }
    
    // MARK: - Beam ID Generation
    
    func generateBeamId(from publicKey: Data) -> String {
        let hash = SHA256.hash(data: publicKey)
        let hashBytes = Data(hash)
        let first8 = hashBytes.prefix(8)
        let hex = first8.map { String(format: "%02x", $0) }.joined()
        return "beam_\(hex)"
    }
    
    func getMyBeamId() -> String {
        return generateBeamId(from: getMySigningPublicKey())
    }
    
    func getMyContactCard() -> ContactCard? {
        guard let user = DatabaseService.shared.getCurrentUser() else {
            return nil
        }
        return createContactCard(displayName: user.displayName)
    }
    
    // MARK: - Contact Card Operations
    
    func createContactCard(displayName: String) -> ContactCard? {
        guard let identityKey = identityPrivateKey else { return nil }
        
        let signingKeyBase64 = getMySigningPublicKey().base64EncodedString()
        let keyAgreementBase64 = getMyKeyAgreementPublicKey().base64EncodedString()
        let beamId = getMyBeamId()
        
        var card = ContactCard(
            displayName: displayName,
            beamId: beamId,
            signingKeyEd25519: signingKeyBase64,
            keyAgreementX25519: keyAgreementBase64
        )
        
        // Sign the card
        if let unsignedData = card.unsignedData() {
            let signature = try? identityKey.signature(for: unsignedData)
            card.signature = signature?.base64EncodedString() ?? ""
        }
        
        return card
    }
    
    func verifyContactCard(_ card: ContactCard) -> Bool {
        // Verify type and version
        guard card.type == "beam_contact", card.version == "1.0" else {
            return false
        }
        
        // Verify Beam ID matches public key
        guard let signingKeyData = Data(base64Encoded: card.signingKeyEd25519) else {
            return false
        }
        let computedBeamId = generateBeamId(from: signingKeyData)
        guard card.beamId == computedBeamId else {
            return false
        }
        
        // Verify signature
        guard let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: signingKeyData),
              let unsignedData = card.unsignedData(),
              let signatureData = Data(base64Encoded: card.signature) else {
            return false
        }
        
        return publicKey.isValidSignature(signatureData, for: unsignedData)
    }
    
    // MARK: - Session Establishment
    
    func createSession(with contact: Contact) -> SessionState? {
        guard let myPrivateKey = keyAgreementPrivateKey,
              let theirPublicKeyData = Data(base64Encoded: contact.keyAgreementKey),
              let theirPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: theirPublicKeyData) else {
            return nil
        }
        
        // Static ECDH
        guard let sharedSecret = try? myPrivateKey.sharedSecretFromKeyAgreement(with: theirPublicKey) else {
            return nil
        }
        
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }
        
        // Create context binding
        let myBeamId = getMyBeamId()
        let theirBeamId = contact.id
        let context = createContextBinding(myBeamId: myBeamId, theirBeamId: theirBeamId)
        
        // Derive keys using HKDF
        let salt = context
        let info = "beam:session:v1".data(using: .utf8)!
        
        let derivedKeys = deriveSessionKeys(sharedSecret: sharedSecretData, salt: salt, info: info)
        
        // Swap send/receive chains based on lexicographic order
        // This ensures both devices agree on which chain is for sending vs receiving
        let iAmLower = myBeamId < theirBeamId
        
        return SessionState(
            rootKey: derivedKeys.rootKey,
            sendChainKey: iAmLower ? derivedKeys.chain1 : derivedKeys.chain2,
            receiveChainKey: iAmLower ? derivedKeys.chain2 : derivedKeys.chain1
        )
    }
    
    private func createContextBinding(myBeamId: String, theirBeamId: String) -> Data {
        // Context = SHA256(sorted(beamId1, beamId2) for deterministic derivation)
        // Both devices must derive the same context regardless of who initiates
        let sortedIds = [myBeamId, theirBeamId].sorted()
        let combined = sortedIds.joined(separator: "|")
        let hash = SHA256.hash(data: combined.data(using: .utf8)!)
        return Data(hash)
    }
    
    private func deriveSessionKeys(sharedSecret: Data, salt: Data, info: Data) -> (rootKey: Data, chain1: Data, chain2: Data) {
        // Use HKDF to derive three 32-byte keys
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: sharedSecret),
            salt: salt,
            info: info,
            outputByteCount: 96 // 3 * 32 bytes
        )
        
        let keyData = derivedKey.withUnsafeBytes { Data($0) }
        
        let rootKey = keyData.subdata(in: 0..<32)
        let chain1 = keyData.subdata(in: 32..<64)
        let chain2 = keyData.subdata(in: 64..<96)
        
        return (rootKey, chain1, chain2)
    }
    
    // MARK: - Chain Key Operations
    
    func deriveMessageKey(from chainKey: Data, counter: UInt64) -> Data {
        // mk = HMAC(chainKey, "msg" || counter)
        let message = "msg\(counter)".data(using: .utf8)!
        let key = SymmetricKey(data: chainKey)
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return Data(mac)
    }
    
    func advanceChainKey(_ chainKey: Data) -> Data {
        // ck_next = HMAC(ck, "next")
        let message = "next".data(using: .utf8)!
        let key = SymmetricKey(data: chainKey)
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return Data(mac)
    }
    
    // MARK: - Message Encryption (ChaCha20-Poly1305)
    
    func encryptMessage(plaintext: String, messageKey: Data, additionalData: Data) -> (nonce: Data, ciphertext: Data)? {
        guard let plaintextData = plaintext.data(using: .utf8) else { return nil }
        
        // Generate random 12-byte nonce
        var nonceBytes = [UInt8](repeating: 0, count: 12)
        guard SecRandomCopyBytes(kSecRandomDefault, 12, &nonceBytes) == errSecSuccess else {
            return nil
        }
        let nonce = Data(nonceBytes)
        
        // Encrypt with ChaCha20-Poly1305
        let key = SymmetricKey(data: messageKey)
        
        do {
            let sealedBox = try ChaChaPoly.seal(
                plaintextData,
                using: key,
                nonce: ChaChaPoly.Nonce(data: nonce),
                authenticating: additionalData
            )
            
            // Return ciphertext + tag (NOT including nonce - we return that separately)
            return (nonce: nonce, ciphertext: sealedBox.ciphertext)
        } catch {
            return nil
        }
    }
    
    func decryptMessage(ciphertext: Data, nonce: Data, messageKey: Data, additionalData: Data) -> String? {
        let key = SymmetricKey(data: messageKey)
        
        do {
            // Combine nonce and ciphertext (which includes the auth tag)
            var combined = Data()
            combined.append(nonce)
            combined.append(ciphertext)
            
            // Create sealed box from combined data
            let sealedBox = try ChaChaPoly.SealedBox(combined: combined)
            
            let plaintext = try ChaChaPoly.open(sealedBox, using: key, authenticating: additionalData)
            return String(data: plaintext, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    // MARK: - Message Signing
    
    func signMessage(_ message: EncryptedMessage) -> String? {
        guard let identityKey = identityPrivateKey,
              let dataToSign = message.dataForSigning() else {
            return nil
        }
        
        do {
            let signature = try identityKey.signature(for: dataToSign)
            return signature.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    func verifyMessageSignature(_ message: EncryptedMessage, senderSigningKey: Data) -> Bool {
        guard let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: senderSigningKey),
              let dataToVerify = message.dataForSigning(),
              let signatureData = Data(base64Encoded: message.sig) else {
            return false
        }
        
        return publicKey.isValidSignature(signatureData, for: dataToVerify)
    }
    
    // MARK: - Full Message Encryption Flow
    
    func encryptAndSignMessage(
        plaintext: String,
        to contact: Contact,
        session: inout SessionState
    ) -> EncryptedMessage? {
        // Get message key from session
        let messageKey = session.advanceSendChain()
        
        // Create AAD (Additional Authenticated Data)
        let myBeamId = getMyBeamId()
        let aad = "\(myBeamId)|\(contact.id)".data(using: .utf8)!
        
        // Encrypt
        guard let (nonce, ciphertext) = encryptMessage(
            plaintext: plaintext,
            messageKey: messageKey,
            additionalData: aad
        ) else {
            return nil
        }
        
        // Create message envelope (mutable for signing)
        var envelope = EncryptedMessage(
            v: 1,
            from: myBeamId,
            to: contact.id,
            t: Int64(Date().timeIntervalSince1970 * 1000),
            rIdx: session.sendCounter - 1, // Already advanced
            nonce: nonce.base64EncodedString(),
            ciphertext: ciphertext.base64EncodedString(),
            sig: "" // Will be set below
        )
        
        // Sign
        if let signature = signMessage(envelope) {
            envelope.sig = signature
        }
        
        // Save session state
        try? session.save(for: contact.id)
        
        return envelope
    }
    
    func verifyAndDecryptMessage(
        _ envelope: EncryptedMessage,
        from contact: Contact,
        session: inout SessionState
    ) -> String? {
        // Validate envelope
        guard envelope.isValid() else {
            return nil
        }
        
        // Check timestamp
        guard envelope.isTimely() else {
            return nil
        }
        
        // Verify nonce hasn't been seen
        guard let nonceData = Data(base64Encoded: envelope.nonce) else {
            return nil
        }
        guard session.recordNonce(envelope.nonce) else {
            return nil
        }
        
        // Verify signature
        guard let senderKeyData = Data(base64Encoded: contact.publicKey) else {
            return nil
        }
        guard verifyMessageSignature(envelope, senderSigningKey: senderKeyData) else {
            return nil
        }
        
        // Derive message key
        guard let messageKey = session.advanceReceiveChain(to: envelope.rIdx) else {
            return nil
        }
        
        // Decrypt
        guard let ciphertextData = Data(base64Encoded: envelope.ciphertext) else {
            return nil
        }
        
        let aad = "\(envelope.from)|\(envelope.to)".data(using: .utf8)!
        let plaintext = decryptMessage(
            ciphertext: ciphertextData,
            nonce: nonceData,
            messageKey: messageKey,
            additionalData: aad
        )
        
        // Save session state
        try? session.save(for: contact.id)
        
        return plaintext
    }
    
    // MARK: - Simple Direct Encryption (No Sessions, No Key Agreement)
    
    /// SIMPLE: Encrypt message directly using recipient's public key
    /// No session management, no key agreement - just one-time ECDH
    func encryptDirectly(plaintext: String, to contact: Contact) -> EncryptedMessage? {
        guard let myPrivateKey = keyAgreementPrivateKey,
              let mySigningKey = identityPrivateKey,
              let theirPublicKeyData = Data(base64Encoded: contact.keyAgreementKey),
              let theirPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: theirPublicKeyData) else {
            return nil
        }
        
        // Do one-time ECDH to get shared secret
        guard let sharedSecret = try? myPrivateKey.sharedSecretFromKeyAgreement(with: theirPublicKey) else {
            return nil
        }
        
        // Derive encryption key from shared secret (simple HKDF)
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }
        let salt = "beam-simple-encryption".data(using: .utf8)!
        let info = "message-key".data(using: .utf8)!
        let symmetricKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: sharedSecretData),
            salt: salt,
            info: info,
            outputByteCount: 32
        )
        
        // Random nonce
        var nonceBytes = [UInt8](repeating: 0, count: 12)
        guard SecRandomCopyBytes(kSecRandomDefault, 12, &nonceBytes) == errSecSuccess else {
            return nil
        }
        let nonceData = Data(nonceBytes)
        guard let nonce = try? ChaChaPoly.Nonce(data: nonceData) else {
            return nil
        }
        
        // Encrypt message
        guard let plaintextData = plaintext.data(using: .utf8) else {
            return nil
        }
        
        let aad = "\(getMyBeamId())|\(contact.id)".data(using: .utf8)!
        guard let sealedBox = try? ChaChaPoly.seal(plaintextData, using: symmetricKey, nonce: nonce, authenticating: aad) else {
            return nil
        }
        
        // Sign the ciphertext (includes tag automatically)
        let dataToSign = sealedBox.ciphertext + sealedBox.tag + nonceData
        guard let signature = try? mySigningKey.signature(for: dataToSign) else {
            return nil
        }
        
        // Combine ciphertext + tag for storage
        let combinedCiphertext = sealedBox.ciphertext + sealedBox.tag
        
        // Create encrypted message envelope
        return EncryptedMessage(
            v: 1,
            from: getMyBeamId(),
            to: contact.id,
            t: Int64(Date().timeIntervalSince1970 * 1000),
            rIdx: 0, // Not using index for simple encryption
            nonce: nonceData.base64EncodedString(),
            ciphertext: combinedCiphertext.base64EncodedString(),
            sig: signature.base64EncodedString()
        )
    }
    
    /// SIMPLE: Decrypt message directly using our private key
    func decryptDirectly(envelope: EncryptedMessage, from contact: Contact) -> String? {
        guard let myPrivateKey = keyAgreementPrivateKey,
              let theirPublicKeyData = Data(base64Encoded: contact.keyAgreementKey),
              let theirPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: theirPublicKeyData),
              let theirSigningKeyData = Data(base64Encoded: contact.publicKey),
              let theirSigningKey = try? Curve25519.Signing.PublicKey(rawRepresentation: theirSigningKeyData) else {
            return nil
        }
        
        // Verify signature first
        guard let combinedCiphertextData = Data(base64Encoded: envelope.ciphertext),
              let nonceData = Data(base64Encoded: envelope.nonce),
              let signatureData = Data(base64Encoded: envelope.sig) else {
            return nil
        }
        
        // Split combined ciphertext into ciphertext + tag (last 16 bytes)
        guard combinedCiphertextData.count > 16 else {
            return nil
        }
        let ciphertextData = combinedCiphertextData.dropLast(16)
        let tagData = combinedCiphertextData.suffix(16)
        
        let dataToVerify = ciphertextData + tagData + nonceData
        guard theirSigningKey.isValidSignature(signatureData, for: dataToVerify) else {
            return nil
        }
        
        // Do one-time ECDH to get shared secret
        guard let sharedSecret = try? myPrivateKey.sharedSecretFromKeyAgreement(with: theirPublicKey) else {
            return nil
        }
        
        // Derive same encryption key from shared secret
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }
        let salt = "beam-simple-encryption".data(using: .utf8)!
        let info = "message-key".data(using: .utf8)!
        let symmetricKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: sharedSecretData),
            salt: salt,
            info: info,
            outputByteCount: 32
        )
        
        // Decrypt
        guard let nonce = try? ChaChaPoly.Nonce(data: nonceData) else {
            return nil
        }
        
        let aad = "\(envelope.from)|\(envelope.to)".data(using: .utf8)!
        
        do {
            let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertextData, tag: tagData)
            let decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey, authenticating: aad)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
