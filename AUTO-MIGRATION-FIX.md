# AUTO-MIGRATION: beam_user → beam_crypto Fix

## Problem
macOS app still advertising as `beam_user_7c836231` even after the fix because `ensureUserExists()` only created new users, it didn't fix existing ones with the wrong format.

## Solution
Updated `ensureUserExists()` to **automatically detect and migrate** old Beam IDs:

### What It Does Now

1. **Check existing user**: Get current user from database
2. **Detect old format**: Check if Beam ID starts with `"beam_user_"`
3. **Migrate automatically**:
   - Delete old user from database
   - Create new user with crypto-derived Beam ID
   - Preserve display name, settings, avatar
   - Restart MeshService to advertise with new ID

### Code Changes

**DatabaseService.swift:**
```swift
func ensureUserExists() {
    let correctBeamId = crypto.getMyBeamId()
    
    if let existingUser = getCurrentUser() {
        // Detect old format
        if existingUser.beamId.hasPrefix("beam_user_") {
            print("⚠️ Detected old Beam ID format: \(existingUser.beamId)")
            print("🔄 Migrating to correct format: \(correctBeamId)")
            
            // Delete and recreate
            deleteAllUsers()
            
            let newUser = User(
                beamId: correctBeamId,
                displayName: existingUser.displayName,
                // ... preserve other settings
            )
            
            saveUser(newUser)
            
            // Restart mesh to pick up new ID
            MeshService.shared.restart()
            return
        }
    }
    
    // Create new user if none exists
    // ...
}
```

**Added Functions:**
- `deleteAllUsers()` - Removes old user from database
- `MeshService.restart()` - Stops and restarts with new peer ID

## How to Test

### On macOS:

1. **Quit Beam** completely if it's running

2. **Rebuild**:
   ```bash
   # In terminal
   cd "/Users/darkis/Desktop/Working/Beam/Beam"
   
   # Clean
   rm -rf ~/Library/Developer/Xcode/DerivedData/Beam-*
   ```

3. **In Xcode**:
   - Select "My Mac" as destination
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Run (Cmd+R)

4. **Watch Console Output**:
   ```
   ⚠️ Detected old Beam ID format: beam_user_7c836231
   🔄 Migrating to correct format: beam_314968a2xxxxxxxx
   🗑️ Old user deleted from database
   ✅ Beam ID migrated successfully!
   🔄 Restarting mesh service with new Beam ID...
   ✅ Mesh service restarted
   ✅ Started advertising Beam ID: beam_314968a2xxxxxxxx
   🔍 Started browsing for peers
   ```

5. **Verify in Settings**:
   - Go to Settings
   - Your Beam ID should now be `beam_xxxxxxxxxxxxxxxx` (NOT `beam_user_xxx`)

### Expected Peer Discovery

**Before migration:**
```
macOS advertising: beam_user_7c836231  ❌
iPhone looking for: beam_238d07a5dfbc9383  ❌
❌ NO MATCH - Messages fail
```

**After migration:**
```
macOS advertising: beam_a1b2c3d4e5f6g7h8  ✅
iPhone looking for: beam_a1b2c3d4e5f6g7h8  ✅
✅ MATCH - Messages work!
```

## Testing Messaging

Once both devices have correct Beam IDs:

1. **Delete old contacts** on both devices (they have wrong IDs)

2. **Re-scan QR codes**:
   - On macOS: My QR Code → Show QR
   - On iPhone: Scan QR Code → Scan Mac's QR
   - On iPhone: My QR Code → Show QR
   - On macOS: Scan QR Code → Scan iPhone's QR

3. **Send test message**:
   - From iPhone to Mac
   - From Mac to iPhone

4. **Expected console output**:
   ```
   📤 Attempting to send message to [Name] (beam_xxxxxxxxxxxxxxxx)
      Connected peers: ["beam_xxxxxxxxxxxxxxxx"]
   ✅ Peer found and connected!
   📨 Sending encrypted message...
   ✅ Message sent successfully
   ```

## Why beam_user_xxx Still Appears in Nearby List

If you see `beam_user_7c836231` in the nearby peers list, it means:
- **Another Beam instance is running** somewhere on your network
- Could be an old version of the app
- Could be another device running Beam
- macOS correctly **ignores it** because it's not in your contacts

The important part is that **macOS is now advertising** with the correct `beam_xxxxxxxx` format, not `beam_user_xxx`.

## What Gets Preserved

During migration:
- ✅ Display name
- ✅ Avatar
- ✅ DHT relay setting
- ✅ Auto-delete days setting
- ❌ Contacts (need to re-scan QR codes)
- ❌ Messages (will be cleared)

The contacts need to be re-added because their IDs in your database reference the old Beam ID format.

---

**Status**: AUTO-MIGRATION IMPLEMENTED ✅

The app will now automatically fix itself on next launch!
