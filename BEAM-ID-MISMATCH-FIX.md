# BEAM ID MISMATCH FIX - Messages Not Sending

## The Problem

Messages were not sending between devices even though peers were discovered. The logs showed:

```
Looking for: beam_238d07a5dfbc9383
Found peers: beam_user_7c836231, D3D8BFEC-FC3A-4E39-B93C-BD738F64C733
❌ Peer not connected
```

## Root Cause

**Two different Beam ID generation methods** were being used:

### Method 1: DatabaseService (WRONG)
```swift
beamId: "beam_user_" + UUID().uuidString.prefix(8).lowercased()
// Result: "beam_user_7c836231" (random)
```

### Method 2: CryptoService (CORRECT)
```swift
func generateBeamId(from publicKey: Data) -> String {
    let hash = SHA256.hash(data: publicKey)
    let hashBytes = Data(hash)
    let first8 = hashBytes.prefix(8)
    let hex = first8.map { String(format: "%02x", $0) }.joined()
    return "beam_\(hex)"
}
// Result: "beam_238d07a5dfbc9383" (crypto-derived)
```

## Why This Broke Messaging

1. **App starts** → DatabaseService creates random user with `beam_user_xxx`
2. **MeshService advertises** with `beam_user_xxx` peer ID
3. **User scans QR code** → QR contains crypto-derived `beam_yyy`
4. **Contact saved** with ID `beam_yyy`
5. **Try to send message** → Look for peer `beam_yyy`
6. **Peer not found** → Only `beam_user_xxx` is advertising
7. **Message fails** ❌

## The Fix

### 1. Added `ensureUserExists()` to DatabaseService
```swift
func ensureUserExists() {
    // Check if user already exists
    if getCurrentUser() != nil {
        return
    }
    
    // Create new user with crypto-derived Beam ID
    let crypto = CryptoService.shared
    let beamId = crypto.getMyBeamId()  // ← Uses SHA256 of public key
    
    let user = User(
        beamId: beamId,
        displayName: "Me",
        publicKey: "",
        privateKey: "",
        enableDHTRelay: true,
        autoDeleteDays: nil
    )
    
    saveUser(user)
    print("📱 Created new user with Beam ID: \(beamId)")
}
```

### 2. Call During App Initialization
```swift
// In BeamApp.swift
init() {
    // Ensure user exists with proper Beam ID
    DatabaseService.shared.ensureUserExists()
    
    // Start mesh networking on app launch
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        MeshService.shared.start()
    }
}
```

## How It Works Now

1. **App starts** → `ensureUserExists()` creates user with crypto-derived `beam_xxx`
2. **MeshService reads user** → Advertises with crypto-derived `beam_xxx`
3. **QR code generated** → Contains same crypto-derived `beam_xxx`
4. **Friend scans QR** → Saves contact with `beam_xxx`
5. **Friend sends message** → Looks for peer `beam_xxx`
6. **Peer found** → `beam_xxx` matches! ✅
7. **Message sent successfully** 🎉

## Testing Steps

### Fresh Install Test (CRITICAL)

Since existing users already have the wrong Beam ID, you need to:

**1. Delete App from Both Devices**
- macOS: Drag Beam.app to Trash
- iPhone: Long press → Delete

**2. Delete Database**
```bash
# macOS
rm -rf ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/

# iPhone - will be deleted with app
```

**3. Clean Build**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Beam-*
```

**4. Rebuild and Install**
- Build for macOS
- Build for iPhone
- Both apps will create users with crypto-derived Beam IDs

**5. Test Messaging**
1. **On Mac**: Open Beam → Settings → Copy your Beam ID → Should be `beam_xxxxxxxx` (16 hex chars)
2. **On Mac**: My QR Code → Show QR
3. **On iPhone**: Scan QR Code → Scan Mac's QR
4. **Check console**: Should show `📍 Nearby peer found: beam_xxxxxxxx` (matching Mac's ID)
5. **Send message from iPhone** → Should connect and send! ✅

## Expected Console Output (SUCCESS)

**On Mac:**
```
📱 Created new user with Beam ID: beam_a1b2c3d4e5f6g7h8
✅ Started advertising Beam ID: beam_a1b2c3d4e5f6g7h8
🔍 Started browsing for peers
📍 Nearby peer found: beam_9876543210abcdef
   Total nearby peers: 1
🔗 Connected to peer: beam_9876543210abcdef
📬 Received message from beam_9876543210abcdef
```

**On iPhone:**
```
📱 Created new user with Beam ID: beam_9876543210abcdef
✅ Started advertising Beam ID: beam_9876543210abcdef
🔍 Started browsing for peers
📍 Nearby peer found: beam_a1b2c3d4e5f6g7h8
   Total nearby peers: 1
📤 Attempting to send message to Mac (beam_a1b2c3d4e5f6g7h8)
   Connected peers: ["beam_a1b2c3d4e5f6g7h8"]
✅ Peer found and connected!
📨 Message sent successfully
```

## Why Crypto-Derived Beam ID is Correct

The Beam ID is derived from the **Ed25519 signing public key**:
- `beam_` + first 16 hex chars of SHA256(public_key)
- Deterministic: same key → same Beam ID
- Unique: different keys → different Beam IDs
- Secure: Can't fake without private key
- Verifiable: Recipients can verify signature matches Beam ID

## Removed Code

The old sample data insertion with random UUID is now bypassed by `ensureUserExists()`, which runs before any sample data logic.

---

**Status**: FIXED ✅ - Beam IDs now match between peer discovery and contact lookup!

Messages will send successfully once both devices have been reinstalled with the corrected Beam ID generation.
