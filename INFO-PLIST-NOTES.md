# Info.plist Configuration

To enable camera access for QR code scanning, add the following to your Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>Beam needs camera access to scan QR codes for adding contacts</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Beam needs photo library access to share QR codes</string>
```

## Privacy Permissions Required

### Camera (Required for QR Scanning)
- **Key**: `NSCameraUsageDescription`
- **Purpose**: Scan contact QR codes
- **Usage**: ScanQRCodeView

### Photo Library (Optional)
- **Key**: `NSPhotoLibraryUsageDescription`
- **Purpose**: Save and share QR codes
- **Usage**: MyQRCodeView (share functionality)

## App Capabilities

The app requires these capabilities (automatically handled by Xcode):

- **App Sandbox**: NO (for full device access)
- **Outgoing Connections**: YES (for P2P/DHT networking)
- **Incoming Connections**: YES (for receiving messages)

## Background Modes

For production, consider enabling:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

This allows the app to:
- Receive messages in background
- Update connection status
- Sync with peers when offline

## Security

The app uses:
- **CryptoKit**: For encryption (built into iOS 15+)
- **SQLite**: For local database (built-in)
- **Keychain**: For storing private keys (recommended enhancement)

### Recommended: Move Private Key to Keychain

For production, move the private key from SQLite to iOS Keychain:

```swift
import Security

// Store private key
let keyData = privateKey.data(using: .utf8)!
let query: [String: Any] = [
    kSecClass as String: kSecClassKey,
    kSecAttrApplicationTag as String: "com.beam.privatekey",
    kSecValueData as String: keyData
]
SecItemAdd(query as CFDictionary, nil)

// Retrieve private key
let searchQuery: [String: Any] = [
    kSecClass as String: kSecClassKey,
    kSecAttrApplicationTag as String: "com.beam.privatekey",
    kSecReturnData as String: true
]
var result: AnyObject?
SecItemCopyMatching(searchQuery as CFDictionary, &result)
```

## Database Location

The SQLite database is stored at:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/Database/beam.db
```

To view the database during development:
```bash
# Find the database path
sqlite3 [path_to_beam.db]

# View tables
.tables

# Query messages
SELECT * FROM messages;

# Query contacts
SELECT * FROM contacts;
```

## Build Settings

### Minimum Deployment Target
- **iOS**: 15.0
- **iPadOS**: 15.0
- **macOS**: 12.0 (future)

### Supported Devices
- iPhone 6s and later
- iPad (6th generation) and later
- All iPad Pro models

### Swift Version
- Swift 5.5 or later (for async/await support in future enhancements)
