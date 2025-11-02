# 📂 Beam Project File Tree

```
Beam/
│
├── 📱 Beam/                                    # Main app target
│   │
│   ├── 🎯 BeamApp.swift                        # App entry point
│   │   └── Initializes: DatabaseService, MessageService, RelayService
│   │
│   ├── 📄 ContentView.swift                    # Main TabView container
│   │   └── Tabs: Chats, Contacts, Settings
│   │
│   ├── 📦 Models/                              # Data models
│   │   ├── Contact.swift                       # Contact with Beam ID & keys
│   │   ├── Message.swift                       # Message with encryption & status
│   │   ├── User.swift                          # User profile with settings
│   │   └── ConnectionStatus.swift              # Network status enum
│   │
│   ├── ⚙️ Services/                            # Business logic layer
│   │   ├── DatabaseService.swift               # SQLite management ⭐
│   │   │   ├── Creates: beam.db in Documents/Database/
│   │   │   ├── Tables: users, contacts, messages
│   │   │   ├── Sample data initialization
│   │   │   └── Full CRUD operations
│   │   │
│   │   ├── EncryptionService.swift             # E2E encryption ⭐
│   │   │   ├── Curve25519 key generation
│   │   │   ├── Message encryption/decryption
│   │   │   └── Beam ID generation (SHA256)
│   │   │
│   │   ├── RelayService.swift                  # Message relay logic
│   │   │   ├── Path selection: Direct/Gossip/DHT
│   │   │   ├── Connection status monitoring
│   │   │   └── Peer simulation
│   │   │
│   │   ├── GossipService.swift                 # Gossip protocol
│   │   │   ├── Peer management
│   │   │   └── Message broadcasting
│   │   │
│   │   └── MessageService.swift                # Message orchestration ⭐
│   │       ├── Sending/receiving coordination
│   │       ├── Status updates
│   │       └── Read receipts
│   │
│   ├── 🖼️ Views/                               # SwiftUI views
│   │   ├── ChatListView.swift                  # Main inbox ⭐
│   │   │   ├── Search bar
│   │   │   ├── Chat rows with previews
│   │   │   ├── Unread badges
│   │   │   └── + button (Scan/Show QR)
│   │   │
│   │   ├── ChatView.swift                      # Individual chat ⭐
│   │   │   ├── Message bubbles (sent/received)
│   │   │   ├── Delivery status checkmarks
│   │   │   ├── Timestamps
│   │   │   ├── Input bar with send button
│   │   │   └── Encryption info modal
│   │   │
│   │   ├── ContactsView.swift                  # Contacts list
│   │   │   ├── Search bar
│   │   │   ├── Contact rows
│   │   │   └── Add via QR button
│   │   │
│   │   ├── MyQRCodeView.swift                  # Show QR code
│   │   │   ├── QR code generation
│   │   │   ├── Beam ID display
│   │   │   ├── Copy ID button
│   │   │   └── Share button
│   │   │
│   │   ├── ScanQRCodeView.swift                # Scan QR code
│   │   │   ├── Camera preview (placeholder)
│   │   │   ├── Scan border animation
│   │   │   └── Manual entry option
│   │   │
│   │   └── SettingsView.swift                  # Settings & profile
│   │       ├── Profile section (avatar, name, ID)
│   │       ├── DHT Relay toggle
│   │       ├── Auto-delete toggle
│   │       └── About section
│   │
│   ├── 🧩 Components/                          # Reusable UI components
│   │   ├── AvatarView.swift                    # Avatar with initials
│   │   │   ├── Colored background
│   │   │   └── Initials from name
│   │   │
│   │   └── ConnectionStatusView.swift          # Network indicator
│   │       ├── Colored dot (green/orange/red)
│   │       └── Tap for details
│   │
│   ├── 🎨 Utilities/                           # Helper utilities
│   │   ├── BeamColors.swift                    # Color scheme
│   │   │   ├── Beam Blue (#2B6FFF)
│   │   │   ├── Success Green (#00C853)
│   │   │   └── Background Gray (#F8F9FB)
│   │   │
│   │   └── DateExtensions.swift                # Date formatting
│   │       ├── timeAgo() - "1h ago"
│   │       └── formatted() - "3:45 PM"
│   │
│   ├── 🖼️ Assets.xcassets/                     # App assets
│   │   ├── AccentColor.colorset/               # Beam Blue
│   │   └── AppIcon.appiconset/                 # App icon
│   │
│   ├── 🔐 Beam.entitlements                    # App capabilities
│   │
│   └── 👁️ Preview Content/                     # SwiftUI previews
│       └── Preview Assets.xcassets/
│
├── 🧪 BeamTests/                               # Unit tests
│   └── BeamTests.swift
│
├── 🤖 BeamUITests/                             # UI tests
│   ├── BeamUITests.swift
│   └── BeamUITestsLaunchTests.swift
│
├── 📋 Beam.xcodeproj/                          # Xcode project
│   ├── project.pbxproj
│   └── project.xcworkspace/
│
├── 📚 Documentation/                           # Project docs (created)
│   ├── README.md                               # Main documentation ⭐
│   ├── ARCHITECTURE.md                         # Technical diagrams
│   ├── QUICKSTART.md                           # Getting started guide
│   ├── BUILD-CHECKLIST.md                      # Build verification
│   ├── INFO-PLIST-NOTES.md                     # Configuration notes
│   └── IMPLEMENTATION-SUMMARY.md               # Complete summary ⭐
│
└── 🗄️ Database/ (Runtime - in app Documents)   # Created at runtime
    └── beam.db                                 # SQLite database ⭐
        ├── users table (1 user)
        ├── contacts table (3 contacts)
        └── messages table (5 sample messages)
```

---

## 📊 File Statistics

### Code Files
| Category      | Count | Purpose                          |
|---------------|-------|----------------------------------|
| Models        | 4     | Data structures                  |
| Services      | 5     | Business logic                   |
| Views         | 7     | User interface                   |
| Components    | 2     | Reusable UI elements             |
| Utilities     | 2     | Helper functions                 |
| Core          | 2     | App entry & main view            |
| **Total**     | **22**| **Swift files**                  |

### Documentation Files
| File                          | Lines | Purpose                    |
|-------------------------------|-------|----------------------------|
| README.md                     | ~250  | Project overview           |
| ARCHITECTURE.md               | ~350  | Technical details          |
| QUICKSTART.md                 | ~400  | Getting started            |
| BUILD-CHECKLIST.md            | ~350  | Build verification         |
| INFO-PLIST-NOTES.md           | ~150  | Configuration              |
| IMPLEMENTATION-SUMMARY.md     | ~450  | Complete summary           |
| **Total**                     |**~1950**| **Documentation lines** |

---

## 🔍 Key Files Breakdown

### ⭐ Most Important Files

#### 1. `BeamApp.swift` - Entry Point
```swift
Purpose: App initialization
Initializes: DatabaseService, MessageService, RelayService
Sets up: Environment objects for dependency injection
```

#### 2. `DatabaseService.swift` - Data Persistence
```swift
Purpose: SQLite database management
Creates: beam.db in Documents/Database/
Tables: users, contacts, messages
Operations: Full CRUD + queries
Sample Data: 1 user, 3 contacts, 5 messages
```

#### 3. `MessageService.swift` - Core Logic
```swift
Purpose: Message orchestration
Coordinates: Encryption → Storage → Relay
Manages: Message status updates, read receipts
Published: messages dictionary for reactive UI
```

#### 4. `ChatListView.swift` - Main UI
```swift
Purpose: Primary app interface
Features: Search, chat rows, unread badges
Navigation: To ChatView, QR views
Actions: Add contact, view connection status
```

#### 5. `ChatView.swift` - Messaging UI
```swift
Purpose: Individual conversation interface
Features: Message bubbles, input bar, status indicators
Design: WhatsApp-like with Beam Blue theme
Actions: Send messages, view encryption info
```

---

## 🎯 File Relationships

### Data Flow
```
User Action (View)
    ↓
MessageService (Orchestration)
    ↓
┌─────────┬─────────────┬─────────────┐
│         │             │             │
Encryption  DatabaseService  RelayService
    ↓           ↓             ↓
Encrypted   SQLite DB    Network
  Payload    Persistence   Broadcast
```

### View Hierarchy
```
ContentView (TabView)
├── ChatListView
│   ├── ChatRowView (ForEach)
│   └── → ChatView
├── ContactsView
│   ├── ContactRow (ForEach)
│   └── → ScanQRCodeView
└── SettingsView
    └── → MyQRCodeView
```

### Service Dependencies
```
MessageService
├── uses → DatabaseService
├── uses → EncryptionService
└── uses → RelayService
         └── uses → GossipService
```

---

## 📦 Target Membership

### Beam Target (Main App)
- All .swift files in Beam/ folder
- Assets.xcassets
- Beam.entitlements

### BeamTests Target
- BeamTests.swift
- Access to Beam module

### BeamUITests Target
- BeamUITests.swift
- BeamUITestsLaunchTests.swift

---

## 🗂️ Xcode Groups (Suggested)

To organize in Xcode:
```
Beam
├── 📱 App
│   ├── BeamApp.swift
│   └── ContentView.swift
├── 📦 Models
├── ⚙️ Services
├── 🖼️ Views
│   ├── Chat/
│   │   ├── ChatListView.swift
│   │   └── ChatView.swift
│   ├── Contacts/
│   │   └── ContactsView.swift
│   ├── QR/
│   │   ├── MyQRCodeView.swift
│   │   └── ScanQRCodeView.swift
│   └── Settings/
│       └── SettingsView.swift
├── 🧩 Components
├── 🎨 Utilities
└── 🗂️ Resources
    ├── Assets.xcassets
    └── Beam.entitlements
```

---

## 💾 Runtime File Locations

### Simulator Paths
```
App Bundle:
/Users/.../CoreSimulator/Devices/[UUID]/data/Containers/Bundle/Application/[UUID]/Beam.app

App Data (Documents):
/Users/.../CoreSimulator/Devices/[UUID]/data/Containers/Data/Application/[UUID]/Documents/

Database Location:
[App Data]/Documents/Database/beam.db
```

### Finding Your Database
```bash
# Get app data path
xcrun simctl get_app_container booted com.yourcompany.Beam data

# Navigate to database
cd [path]/Documents/Database/

# Open database
sqlite3 beam.db
```

---

## 🏗️ Build Products

After building:
```
Build/
└── Products/
    └── Debug-iphonesimulator/
        └── Beam.app/
            ├── Beam (executable)
            ├── Assets.car
            ├── Info.plist
            └── Frameworks/
```

---

## 📝 Import Map

### Which files import what:
```
BeamApp.swift
└── import SwiftUI

Models/
├── Contact.swift → Foundation
├── Message.swift → Foundation
├── User.swift → Foundation
└── ConnectionStatus.swift → Foundation

Services/
├── DatabaseService.swift → Foundation, SQLite3
├── EncryptionService.swift → Foundation, CryptoKit
├── RelayService.swift → Foundation, Combine
├── GossipService.swift → Foundation
└── MessageService.swift → Foundation, Combine

Views/
├── ChatListView.swift → SwiftUI
├── ChatView.swift → SwiftUI
├── ContactsView.swift → SwiftUI
├── MyQRCodeView.swift → SwiftUI, CoreImage
├── ScanQRCodeView.swift → SwiftUI, AVFoundation
└── SettingsView.swift → SwiftUI

Components/
├── AvatarView.swift → SwiftUI
└── ConnectionStatusView.swift → SwiftUI

Utilities/
├── BeamColors.swift → SwiftUI
└── DateExtensions.swift → Foundation
```

---

## ✅ Verification Checklist

Use this to verify your project structure:

- [ ] All 22 Swift files exist
- [ ] All files in correct folders
- [ ] All files added to Beam target
- [ ] Assets.xcassets present
- [ ] Documentation files created
- [ ] No duplicate files
- [ ] No missing imports
- [ ] All paths are correct

---

**This tree shows the complete Beam project structure!** 🌳
