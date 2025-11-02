# Beam Architecture Overview

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer (SwiftUI)                       │
├─────────────┬─────────────┬─────────────┬──────────────────────┤
│ ChatListView│  ChatView   │ContactsView │  SettingsView        │
│             │             │             │  MyQRCodeView        │
│             │             │             │  ScanQRCodeView      │
└─────────────┴─────────────┴─────────────┴──────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                               │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ MessageService│RelayService │GossipService │EncryptionService  │
│              │              │              │                   │
│ • sendMsg()  │ • Direct     │ • broadcast()│ • encrypt()       │
│ • receiveMsg│ • Gossip     │ • addPeer()  │ • decrypt()       │
│ • markRead() │ • DHT        │ • forward()  │ • genKeys()       │
└──────────────┴──────────────┴──────────────┴───────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Data Layer (SQLite)                           │
├──────────────────────┬────────────────────┬────────────────────┤
│  DatabaseService     │  Database Schema   │   Storage          │
│                      │                    │                    │
│  • saveMessage()     │  • users           │  Documents/        │
│  • getMessages()     │  • contacts        │  Database/         │
│  • saveContact()     │  • messages        │  beam.db           │
│  • getContacts()     │                    │                    │
└──────────────────────┴────────────────────┴────────────────────┘
```

## 🔄 Message Flow

```
User Types Message
       ↓
ChatInputBar (UI)
       ↓
MessageService.sendMessage()
       ├─→ EncryptionService.encrypt() → encrypted payload
       ├─→ DatabaseService.saveMessage() → local storage
       ├─→ RelayService.sendMessage() → choose path
       │       ├─→ Direct (P2P)
       │       ├─→ Gossip (multi-hop)
       │       └─→ DHT (fallback)
       └─→ Update UI (status: sending → sent → delivered)
```

## 📥 Incoming Message Flow

```
Network Layer (Gossip/DHT)
       ↓
RelayService.receiveMessage()
       ↓
EncryptionService.decrypt()
       ↓
MessageService.receiveMessage()
       ├─→ DatabaseService.saveMessage()
       └─→ Update UI (@Published messages)
       ↓
ChatView auto-refreshes
```

## 🗂️ Data Models

### Contact
```swift
{
  id: "beam_abc123...",        // Beam ID (SHA256 of pubkey)
  name: "Alice",
  publicKey: "base64...",
  avatar: "base64 or path",
  lastSeen: Date,
  createdAt: Date
}
```

### Message
```swift
{
  id: UUID,
  contactId: "beam_abc123...",
  content: "Hello!",           // plaintext (local only)
  encryptedContent: "xyz...",  // encrypted (for relay)
  isSent: true,                // direction
  timestamp: Date,
  status: .delivered,          // sending, sent, delivered, read
  isRead: false
}
```

### User (Self)
```swift
{
  beamId: "beam_xyz789...",
  displayName: "Me",
  publicKey: "base64...",
  privateKey: "base64...",     // stored locally, never sent
  enableDHTRelay: true,
  autoDeleteDays: 7
}
```

## 🔐 Encryption Flow

### Key Generation
```
User First Launch
    ↓
EncryptionService.generateKeyPair()
    ├─→ Private Key (Curve25519) → stored in SQLite (local only)
    └─→ Public Key → shared via QR code
    ↓
Beam ID = SHA256(publicKey).prefix(16)
```

### Message Encryption
```
Plaintext Message
    ↓
Recipient's Public Key (from contacts table)
    ↓
Curve25519 Key Agreement
    ↓
Encrypted Payload (Base64)
    ↓
Store both plaintext (local) + encrypted (for relay)
```

## 📡 Network Topology

```
        [Your Device]
             │
             ├─ Direct P2P ──────────→ [Friend's Device]
             │
             ├─ Gossip Protocol
             │      ├→ [Peer 1] ──→ [Peer 2] ──→ [Friend]
             │      └→ [Peer 3] ──→ [Peer 4] ──→ [Friend]
             │
             └─ DHT Fallback
                    └→ [DHT Node] ──→ [Relay] ──→ [Friend]
```

## 🎨 UI Component Hierarchy

```
ContentView (TabView)
├── Tab 0: ChatListView
│   ├── SearchBar
│   ├── ScrollView
│   │   └── ForEach Contact
│   │       └── ChatRowView
│   │           ├── AvatarView
│   │           ├── Name + Last Message
│   │           └── Timestamp + Unread Badge
│   └── FloatingActionButton (+)
│       ├── Scan QR
│       └── Show My QR
│
├── Tab 1: ContactsView
│   ├── SearchBar
│   └── ScrollView
│       └── ForEach Contact
│           └── ContactRow
│
└── Tab 2: SettingsView
    ├── Profile Section
    │   ├── Avatar
    │   ├── Display Name
    │   └── Beam ID (copyable)
    ├── Settings Toggles
    │   ├── Enable DHT Relay
    │   └── Auto-delete Messages
    └── About Section
```

## 🔄 State Management

```
@StateObject (Singleton Services)
├── DatabaseService.shared
├── MessageService.shared
├── RelayService.shared
└── EncryptionService.shared

@Published Properties (Reactive UI)
├── MessageService.messages: [String: [Message]]
├── RelayService.connectionStatus: ConnectionStatus
└── RelayService.connectedPeers: Int

@State (Local View State)
├── selectedContact
├── messageText
├── searchText
└── showingModal
```

## 🧪 Sample Data

The app pre-loads sample data for testing:

**Contacts:**
- Alice (beam_alice_123)
- Bob (beam_bob_456)
- Carol (beam_carol_789)

**Messages:**
- Alice: 2 messages (1 received, 1 sent)
- Bob: 2 messages (conversation)
- Carol: 1 unread message

**User:**
- Beam ID: auto-generated on first launch
- Display Name: "Me"
- Public/Private keys: generated

## 🛣️ Navigation Flow

```
Launch App
    ↓
ContentView (TabView)
    ├─→ Chats Tab
    │    ├─→ Tap Chat → ChatView
    │    ├─→ Tap + → Menu
    │    │    ├─→ Scan QR → ScanQRCodeView
    │    │    └─→ Show QR → MyQRCodeView
    │    └─→ Tap Info → EncryptionInfoView
    │
    ├─→ Contacts Tab
    │    ├─→ Tap Contact → ChatView
    │    └─→ Tap + → ScanQRCodeView
    │
    └─→ Settings Tab
         ├─→ Show My QR → MyQRCodeView
         └─→ Edit Profile → inline
```

## 📱 Platform Adaptations

### iPhone
- Tab-based navigation (bottom)
- Single-column layout
- Modal sheets for QR codes

### iPad
- Split view (ChatList | ChatView)
- Two-column layout
- Popovers for QR codes

### macOS (future)
- Sidebar navigation
- Toolbar controls
- Native macOS window chrome
