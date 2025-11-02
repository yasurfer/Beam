# Beam 📡

<p align="center">
  <img src="screenshots/beam.png" alt="Beam Logo" width="200"/>
</p>

<p align="center">
  <strong>Decentralized, End-to-End Encrypted Mesh Messaging</strong>
</p>

<p align="center">
  A truly peer-to-peer messaging application built with SwiftUI for iOS and macOS, featuring Signal Protocol encryption, offline capabilities, and decentralized mesh networking via MultipeerConnectivity.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#security">Security</a> •
  <a href="#architecture">Architecture</a>
</p>

---

## Overview

Beam is a revolutionary messaging application that operates without any central servers. Using **Apple's MultipeerConnectivity framework** combined with **Signal Protocol-based encryption**, Beam creates a secure, decentralized mesh network for private communications.

Unlike traditional messaging apps that rely on centralized servers, Beam creates direct device-to-device connections, ensuring your messages are truly private and can be sent even without internet connectivity.

## 🎯 Features

### 🔐 End-to-End Encryption
- **Signal Protocol Implementation**: Uses the Double Ratchet algorithm for forward secrecy
- **Ed25519 Signatures**: Cryptographically signed messages for authenticity verification
- **X25519 Key Agreement**: Elliptic-curve Diffie-Hellman for secure key exchange
- **Zero Trust**: Messages are encrypted on your device and can only be decrypted by the intended recipient

### 📡 Mesh Networking
- **Peer-to-Peer Connections**: Direct device-to-device communication using MultipeerConnectivity
- **No Internet Required**: Messages can be sent over Bluetooth and WiFi-Direct
- **Offline Message Queue**: Messages are queued when contacts are offline and automatically delivered when they come online
- **Network Resilience**: Automatically reconnects and resends failed messages

### 🔄 Multi-Hop Relay (Coming Soon)
- **Gossip Protocol**: Messages can hop through intermediary devices to reach distant peers
- **Extended Range**: Communicate beyond direct Bluetooth/WiFi range through trusted relay nodes

### 🎨 Native Platform Experience
- **SwiftUI**: Modern, native UI for both iOS and macOS
- **Platform-Specific Design**: Tailored experiences optimized for each platform
- **Dark Mode**: Full support for system appearance preferences
- **Real-time Updates**: Instant message delivery and read receipts

### 🔒 Privacy-First
- **No User Accounts**: No email, phone number, or personal information required
- **No Server Storage**: Messages are never stored on any server
- **Cryptographic Identities**: Users identified by Beam IDs (cryptographic public keys)
- **Local Database**: All data encrypted and stored locally using SQLite

## 📸 Screenshots

### iOS

<p align="center">
  <img src="screenshots/ios-chat-list.png" alt="iOS Chat List" width="250"/>
  <img src="screenshots/ios-chat-view.png" alt="iOS Chat View" width="250"/>
  <img src="screenshots/ios-qr-code.png" alt="iOS QR Code" width="250"/>
</p>

<p align="center">
  <em>Chat List • Conversation View • QR Code Sharing</em>
</p>

<p align="center">
  <img src="screenshots/ios-scan-qr.png" alt="iOS QR Scanner" width="250"/>
  <img src="screenshots/ios-contacts.png" alt="iOS Contacts" width="250"/>
  <img src="screenshots/ios-settings.png" alt="iOS Settings" width="250"/>
</p>

<p align="center">
  <em>QR Scanner • Contacts • Settings</em>
</p>

### macOS

<p align="center">
  <img src="screenshots/macos-main-window.png" alt="macOS Main Window" width="800"/>
</p>

<p align="center">
  <em>macOS Main Interface with Side Navigation</em>
</p>

<p align="center">
  <img src="screenshots/macos-qr-modal.png" alt="macOS QR Modal" width="400"/>
  <img src="screenshots/macos-contacts-modal.png" alt="macOS Contacts Modal" width="400"/>
</p>

<p align="center">
  <em>QR Code Modal • Contacts Modal</em>
</p>

---

## 🔧 How It Works

### 1. Cryptographic Identity Generation

When you first launch Beam, the app generates a unique cryptographic identity:

```
- Ed25519 Signing Key Pair (for message authentication)
- X25519 Key Agreement Key Pair (for encryption)
- Beam ID (derived from your public keys)
```

Your **Beam ID** is your unique identifier on the network - no email, phone number, or username required.

### 2. Adding Contacts via QR Code

To start messaging someone:

1. **Show Your QR Code**: Display your QR code containing your Beam ID and public keys
2. **Scan Their QR Code**: Scan your contact's QR code to exchange cryptographic identities
3. **Verify & Add**: The app verifies the cryptographic signature and adds them to your contacts

This ensures you're connecting with the right person through out-of-band verification.

### 3. Peer Discovery & Connection

Beam uses **MultipeerConnectivity** for device discovery:

- **Advertising**: Your device broadcasts its Beam ID over Bluetooth and WiFi
- **Browsing**: Your device scans for nearby peers advertising the Beam service
- **Invitation**: When a peer is found, devices automatically exchange connection invitations
- **Handshake**: After connecting, devices exchange contact cards to verify identities

### 4. Message Encryption (Double Ratchet)

Every message is encrypted using the **Signal Protocol's Double Ratchet Algorithm**:

1. **Session Initialization**: 
   - Uses X25519 Diffie-Hellman key agreement
   - Derives initial chain keys and root key

2. **Message Encryption**:
   - Each message uses a unique symmetric key
   - Keys are derived using HKDF (HMAC-based Key Derivation Function)
   - ChaCha20-Poly1305 AEAD cipher for encryption

3. **Forward Secrecy**:
   - Message keys are deleted immediately after use
   - Even if a key is compromised, past messages remain secure

4. **Authentication**:
   - Each message is signed with Ed25519
   - Prevents message tampering and impersonation

### 5. Message Transmission

**Online Delivery**:
```
You → Encrypt Message → Sign → Send via MultipeerConnectivity → Recipient Verifies → Decrypts → Displays
```

**Offline Queueing**:
```
You → Encrypt Message → Queue Locally → Wait for Peer to Come Online → Auto-Send → Delivered
```

### 6. Message Storage

- **Local SQLite Database**: All messages, contacts, and sessions stored locally
- **Encrypted Storage**: Uses iOS/macOS Keychain for sensitive cryptographic material
- **No Cloud Sync**: Your data never leaves your device

### 7. Future: Multi-Hop Relay (Gossip Protocol)

Beam is implementing a **gossip-based routing protocol** to extend range:

```
You → Intermediate Peer 1 → Intermediate Peer 2 → Recipient
```

- Messages are encrypted end-to-end (intermediaries can't read content)
- Relay nodes only see encrypted packets
- Allows communication across extended distances

## 📁 Project Structure

```
Beam/
├── Models/
│   ├── Contact.swift             # Contact data model
│   ├── ContactCard.swift         # Contact card for QR exchange
│   ├── Message.swift             # Message data model with status
│   ├── EncryptedMessage.swift    # Encrypted message envelope
│   ├── User.swift                # User profile model
│   ├── SessionState.swift        # Double Ratchet session state
│   └── ConnectionStatus.swift    # Network status enum
│
├── Services/
│   ├── DatabaseService.swift     # SQLite database operations
│   ├── EncryptionService.swift   # Double Ratchet encryption
│   ├── CryptoService.swift       # Key generation and management
│   ├── KeychainService.swift     # Secure key storage
│   ├── MeshService.swift         # MultipeerConnectivity P2P
│   ├── MessageService.swift      # Message orchestration
│   ├── RelayService.swift        # Message relay path selection
│   └── GossipService.swift       # Gossip protocol (coming soon)
│
├── Views/
│   ├── ChatListView.swift        # Main chat list (inbox)
│   ├── ChatView.swift            # Individual chat conversation
│   ├── ContactsView.swift        # All contacts list
│   ├── ContactInfoView.swift     # Contact details view
│   ├── MyQRCodeView.swift        # Show user's QR code
│   ├── ScanQRCodeView.swift      # Scan contact QR codes
│   └── SettingsView.swift        # App settings & profile
│
├── Components/
│   ├── AvatarView.swift          # User avatar with initials
│   └── ConnectionStatusView.swift # Network status indicator
│
├── Utilities/
│   ├── BeamColors.swift          # App color scheme
│   └── DateExtensions.swift      # Date formatting helpers
│
└── Database/
    
```

## 🛠️ Installation

### Requirements

- **iOS**: iOS 17.0 or later
- **macOS**: macOS 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later (for building from source)

### Building from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/beam.git
   cd beam
   ```

2. **Open in Xcode**:
   ```bash
   open Beam.xcodeproj
   ```

3. **Configure Signing**:
   - Select your development team in Xcode
   - Update the Bundle Identifier if needed

4. **Build and Run**:
   - Select your target device (iOS Simulator, macOS, or connected device)
   - Press `Cmd + R` to build and run

### App Store (Coming Soon)

Beam will be available on the App Store for both iOS and macOS.

## 📱 Usage

### Getting Started

1. **Launch Beam**: Open the app on your device
2. **Set Display Name**: Choose how you want to appear to contacts
3. **Show QR Code**: Go to Settings → My QR Code
4. **Add Contacts**: Scan a friend's QR code to add them

### Sending Messages

1. **Select Contact**: Tap on a contact from your chat list
2. **Type Message**: Enter your message in the input field
3. **Send**: Press the send button
4. **Delivery Status**: 
   - ⏱️ **Sending** (grey) - Message is being encrypted and sent
   - ✓ **Delivered** (green) - Message successfully delivered to recipient
   - ✗ **Failed** (red) - Delivery failed, will retry automatically

### Connection Status

- **🟢 Online**: Contact is connected and can receive messages immediately
- **🟡 Offline**: Contact is not connected, messages will be queued
- **🔵 Connecting**: Attempting to establish connection

### Managing Contacts

- **View Contact Info**: Tap the info button (ⓘ) in a chat
- **Delete Contact**: Swipe left on a contact in the list
- **Export Contact Card**: Share your QR code for others to scan

## 🔒 Security

### Cryptographic Specifications

| Component | Algorithm | Purpose |
|-----------|-----------|---------|
| **Signing** | Ed25519 | Message authentication and identity verification |
| **Key Agreement** | X25519 (ECDH) | Derive shared secrets for encryption |
| **Encryption** | ChaCha20-Poly1305 | Authenticated encryption with associated data (AEAD) |
| **Key Derivation** | HKDF-SHA256 | Derive message keys from chain keys |
| **Ratcheting** | Double Ratchet (Signal Protocol) | Forward secrecy and future secrecy |

### Threat Model

**Beam Protects Against**:
- ✅ Man-in-the-middle attacks (cryptographic key verification via QR)
- ✅ Message interception (end-to-end encryption)
- ✅ Message tampering (Ed25519 signatures)
- ✅ Replay attacks (nonce-based encryption)
- ✅ Forward compromise (forward secrecy via key deletion)
- ✅ Server breaches (no servers, all data local)

**Beam Does NOT Protect Against**:
- ❌ Compromised device (physical access to unlocked device)
- ❌ Malicious contacts (sending harmful content)
- ❌ Network metadata analysis (peer connection patterns visible)

### Security Best Practices

1. **Verify QR Codes In Person**: Always scan QR codes face-to-face or via trusted video call
2. **Keep Device Secure**: Use biometric locks (Face ID/Touch ID)
3. **Update Regularly**: Keep Beam and iOS/macOS up to date
4. **Backup Carefully**: Beam IDs cannot be recovered if lost

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                        Beam App                              │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                          │
│  ├─ ChatListView                                             │
│  ├─ ChatView                                                 │
│  ├─ ContactsView                                             │
│  ├─ MyQRCodeView / ScanQRCodeView                            │
│  └─ SettingsView                                             │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                               │
│  ├─ MessageService (message management)                      │
│  ├─ MeshService (peer-to-peer networking)                    │
│  ├─ EncryptionService (Double Ratchet)                       │
│  ├─ CryptoService (key management)                           │
│  ├─ DatabaseService (SQLite persistence)                     │
│  ├─ KeychainService (secure key storage)                     │
│  ├─ GossipService (multi-hop relay) [Coming Soon]            │
│  └─ RelayService (routing) [Coming Soon]                     │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  ├─ SQLite Database (messages, contacts, sessions)           │
│  └─ Keychain (cryptographic keys)                            │
├─────────────────────────────────────────────────────────────┤
│  Platform Layer                                              │
│  ├─ MultipeerConnectivity (P2P networking)                   │
│  ├─ CryptoKit (cryptographic primitives)                     │
│  └─ SQLite (persistence)                                     │
└─────────────────────────────────────────────────────────────┘
```

### Message Flow Diagram

```
┌──────────┐                                              ┌──────────┐
│  Sender  │                                              │ Receiver │
└────┬─────┘                                              └────┬─────┘
     │                                                         │
     │ 1. Compose Message                                      │
     ├──────────────────────────────┐                          │
     │                              │                          │
     │ 2. Encrypt with Double       │                          │
     │    Ratchet (ChaCha20-Poly1305)│                         │
     │◄─────────────────────────────┘                          │
     │                                                         │
     │ 3. Sign with Ed25519                                    │
     ├──────────────────────────────┐                          │
     │◄─────────────────────────────┘                          │
     │                                                         │
     │ 4. Send via MultipeerConnectivity                       │
     ├────────────────────────────────────────────────────────►│
     │                                                         │
     │                              5. Verify Signature        │
     │                              ┌──────────────────────────┤
     │                              │                          │◄┐
     │                              └──────────────────────────┤  │
     │                                                         │  │
     │                              6. Decrypt Message         │  │
     │                              ┌──────────────────────────┤  │
     │                              │                          │◄─┘
     │                              └──────────────────────────┤
     │                                                         │
     │                              7. Store in Database       │
     │                              ┌──────────────────────────┤
     │                              └──────────────────────────┤
     │                                                         │
     │                              8. Display to User         │
     │                              ┌──────────────────────────┤
     │                              └──────────────────────────┤
```

### Database Schema

**Users Table**:
```sql
CREATE TABLE users (
    beam_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    created_at TEXT NOT NULL
)
```

**Contacts Table**:
```sql
CREATE TABLE contacts (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    signing_key_ed25519 TEXT NOT NULL,
    key_agreement_x25519 TEXT NOT NULL,
    created_at TEXT NOT NULL
)
```

**Messages Table**:
```sql
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    contact_id TEXT NOT NULL,
    content TEXT NOT NULL,
    encrypted_content TEXT,
    is_sent INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    status TEXT NOT NULL,
    is_read INTEGER NOT NULL,
    is_encrypted INTEGER NOT NULL,
    FOREIGN KEY (contact_id) REFERENCES contacts (id)
)
```

**Sessions Table** (Double Ratchet State):
```sql
CREATE TABLE sessions (
    contact_id TEXT PRIMARY KEY,
    root_key TEXT NOT NULL,
    sending_chain_key TEXT NOT NULL,
    receiving_chain_key TEXT NOT NULL,
    sending_ratchet_key TEXT NOT NULL,
    receiving_ratchet_key TEXT NOT NULL,
    send_counter INTEGER NOT NULL,
    receive_counter INTEGER NOT NULL,
    previous_sending_chain_length INTEGER NOT NULL,
    FOREIGN KEY (contact_id) REFERENCES contacts (id)
)
```

## 🗺️ Roadmap

### ✅ Completed
- [x] Basic peer-to-peer messaging
- [x] End-to-end encryption (Double Ratchet)
- [x] QR code-based contact exchange
- [x] Offline message queueing
- [x] macOS native app
- [x] iOS native app
- [x] Message delivery status
- [x] Read receipts
- [x] Connection status indicators
- [x] Contact management
- [x] Persistent local database

### 🚧 In Progress
- [ ] Gossip protocol for multi-hop relay
- [ ] Performance optimizations
- [ ] Enhanced error handling

### 📋 Planned
- [ ] Message search functionality
- [ ] Group messaging
- [ ] File/image sharing
- [ ] Voice messages
- [ ] Message reactions
- [ ] Custom notification sounds
- [ ] Export/import conversation backups
- [ ] Bridge to other platforms (Signal, Matrix)
- [ ] iPad optimization
- [ ] Disappearing messages
- [ ] Message editing and deletion

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Guidelines

1. **Code Style**: Follow Swift API Design Guidelines
2. **Commits**: Use conventional commits (feat, fix, docs, etc.)
3. **Testing**: Add tests for new features
4. **Documentation**: Update README and inline docs
5. **Security**: Never commit private keys or sensitive data

## 📄 License

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

Copyright (c) 2025 Yass O

**TL;DR**: This is free for noncommercial use only. You can:
- ✅ Use it for personal projects, research, and education
- ✅ Modify and distribute it for noncommercial purposes
- ✅ Study the code and learn from it
- ❌ Use it for commercial purposes without permission

See the [LICENSE](LICENSE) file for full details, or visit https://polyformproject.org/licenses/noncommercial/1.0.0/

## 🙏 Acknowledgments

- **Signal Protocol**: Inspired by Signal's Double Ratchet algorithm
- **MultipeerConnectivity**: Apple's peer-to-peer networking framework
- **CryptoKit**: Apple's cryptography framework
- **The Open Source Community**: For countless libraries and inspiration

## 📞 Contact

- **Project Link**: [https://github.com/yourusername/beam](https://github.com/yourusername/beam)
- **Issues**: [https://github.com/yourusername/beam/issues](https://github.com/yourusername/beam/issues)
- **Discussions**: [https://github.com/yourusername/beam/discussions](https://github.com/yourusername/beam/discussions)

---

<p align="center">
  Made with ❤️ for privacy and decentralization
</p>

<p align="center">
  <strong>⚠️ Security Notice</strong><br>
  Beam is experimental software. While we use industry-standard cryptography,<br>
  this app has not undergone a formal security audit. Use at your own risk.
</p>

<p align="center">
  <strong>No central servers. No data mining. No surveillance.</strong><br>
  <em>Your messages. Your privacy. Your control.</em>
</p>
    └── beam.db               # SQLite database (in Documents)
```

## 🗄️ Database Schema

The app uses SQLite with three main tables:

### Users Table
```sql
CREATE TABLE users (
    beam_id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    public_key TEXT NOT NULL,
    private_key TEXT NOT NULL,
    avatar TEXT,
    enable_dht_relay INTEGER DEFAULT 1,
    auto_delete_days INTEGER
);
```

### Contacts Table
```sql
CREATE TABLE contacts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    public_key TEXT NOT NULL,
    avatar TEXT,
    last_seen TEXT,
    created_at TEXT NOT NULL
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    contact_id TEXT NOT NULL,
    content TEXT NOT NULL,
    encrypted_content TEXT NOT NULL,
    is_sent INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    status TEXT NOT NULL,
    is_read INTEGER DEFAULT 0,
    FOREIGN KEY(contact_id) REFERENCES contacts(id)
);
```

## 🎨 Design System

### Colors
- **Primary**: `#2B6FFF` (Beam Blue)
- **Success**: `#00C853` (Delivered/Read)
- **Background**: `#F8F9FB` (Light Gray)
- **Message Bubbles**: 
  - Sent: Blue gradient
  - Received: White with gray border

### Icons
- All icons use SF Symbols for native iOS look
- Connection status indicator (green/orange/red dot)

## 🔐 Security Features

### Encryption
- **Algorithm**: Curve25519 key agreement (CryptoKit)
- **Key Generation**: Each user has a public/private key pair
- **Beam ID**: SHA256 hash of public key (first 16 chars)
- **Message Encryption**: Messages encrypted with recipient's public key

### Privacy
- No phone numbers required
- No central server storage
- Messages stored only on device
- Optional auto-delete (7/30/90 days)

## 📡 Network Architecture

### Message Relay Paths
1. **Direct**: Peer-to-peer when both online
2. **Gossip**: Broadcast via connected peers (3+ peers)
3. **DHT**: Fallback relay via distributed hash table

### Connection Status
- **Green**: Connected to peers (gossip active)
- **Orange**: DHT fallback mode
- **Red**: Offline (local only)

## 🚀 Getting Started

### Requirements
- Xcode 14 or later
- iOS 15.0+ / iPadOS 15.0+
- iPhone 6s or later / iPad (6th generation) or later

### Installation
1. Open `Beam.xcodeproj` in Xcode
2. Select your target device
3. Build and run (⌘R)

### Sample Data
The app includes sample data for testing:
- 3 sample contacts (Alice, Bob, Carol)
- Sample messages in each conversation
- Pre-configured user profile

## 📱 Usage

### Adding Contacts
1. Tap **+** button in chat list
2. Choose "Scan QR Code" or "Show My QR"
3. Scan friend's QR code or share yours

### Sending Messages
1. Select a contact from chat list
2. Type message in input bar
3. Tap send arrow
4. Watch status: ✓ sent → ✓✓ delivered → ✓✓ (blue) read

### Viewing Encryption Info
1. Open any chat
2. Tap **info** icon in top right
3. View Beam ID and encryption details
4. Option to verify via QR code

### Settings
- **Display Name**: Change your visible name
- **Beam ID**: Copy or view your unique ID
- **DHT Relay**: Toggle DHT fallback network
- **Auto-delete**: Set message retention period

## 🛠️ Services Overview

### DatabaseService
- Manages SQLite database
- CRUD operations for users, contacts, messages
- Persistent storage in app Documents/Database folder
- Sample data initialization

### EncryptionService
- Key pair generation (Curve25519)
- Message encryption/decryption
- Beam ID generation from public key

### RelayService
- Connection status monitoring
- Path selection (Direct/Gossip/DHT)
- Peer connection simulation

### MessageService
- Orchestrates message sending
- Coordinates encryption + relay + storage
- Manages message status updates
- Handles incoming messages

## 🎯 Future Enhancements

- [ ] Actual camera QR scanning (AVFoundation)
- [ ] Real P2P networking (MultipeerConnectivity)
- [ ] Push notifications for background messages
- [ ] Media attachments (photos, videos)
- [ ] Voice messages
- [ ] Group chats
- [ ] Message search
- [ ] Export/backup chats
- [ ] Dark mode support

## 🤝 Contributing

This is a sample project, but suggestions for improvements are welcome!

---

**Built with ❤️ using SwiftUI**
