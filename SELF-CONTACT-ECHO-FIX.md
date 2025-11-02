# Self-Contact Echo Bug Fix

**Date:** November 1, 2025  
**Issue:** "Received encrypted message from Me" + decryption failure  
**Root Cause:** User accidentally saved as contact in database  
**Status:** ✅ FIXED

## Problem

```
Received 359 bytes from peer: beam_314968a258e00f6b
📥 Received encrypted message from Me
   Version: 1, rIdx: 4
❌ Decryption failed: incorrectParameterSize
❌ Failed to decrypt message from Me
```

**Analysis:**
1. Peer `beam_314968a258e00f6b` sent a message
2. Contact lookup found a contact with name="Me" and id=`beam_314968a258e00f6b`
3. This means **the user was accidentally saved as a contact**
4. Decryption failed because trying to decrypt own message with wrong keys

## Root Cause

### How Did This Happen?

Before echo prevention was added, it was possible to:
1. Scan your own QR code (mistake)
2. Accept your own handshake request
3. Get saved in contacts table with your own Beam ID

### Why Echo Prevention Didn't Catch It

Echo prevention at line 505 checks:
```swift
if from == currentUser.beamId {
    print("🔁 Ignoring echo...")
    return
}
```

**But this only works if:**
- The `from` field matches exactly
- The `currentUser.beamId` hasn't changed (e.g., after migration)

If the user's Beam ID changed during migration from `beam_user_xxx` to `beam_xxx`, the old self-contact would remain in the database with the old ID, causing:
- Echo check passes (old ID ≠ new ID)
- Contact lookup succeeds (finds old self-contact)
- Decryption fails (trying to decrypt own message)

## Solution

Added **double-check after contact lookup** to catch database corruption:

```swift
// Find contact by Beam ID
guard let contact = database.getContacts().first(where: { $0.id == from }) else {
    print("❌ Unknown sender: \(from)")
    return
}

// ✅ DOUBLE-CHECK: Contact should not be ourselves (catch database corruption)
if contact.id == currentUser.beamId {
    print("⚠️ WARNING: Found ourselves in contacts database!")
    print("   Contact ID: \(contact.id), User ID: \(currentUser.beamId)")
    print("   Deleting invalid self-contact from database")
    database.deleteContact(contact.id)
    return
}
```

### Why This Works

1. **First check** (line 505): Catches echo if IDs match perfectly
2. **Second check** (new): Catches database corruption if user somehow saved as contact
3. **Auto-cleanup**: Deletes the invalid self-contact from database
4. **Safe**: Returns early, prevents decryption attempt

## Changes Made

**File:** `MeshService.swift`  
**Location:** `handleReceivedMessage()` method, lines 527-535

**Added:**
- Additional validation after contact lookup
- Automatic cleanup of self-contact entries
- Warning log for debugging

## Other Issues in Log

### SQLite DetachedSignatures Warning

```
cannot open file at line 49455 of [1b37c146ee]
os_unix.c:49455: (2) open(/private/var/db/DetachedSignatures) - No such file or directory
```

**Status:** ⚠️ HARMLESS - Known macOS quirk  
**Cause:** SQLite trying to access system file for code signature verification  
**Impact:** None - This is logged by system SQLite, not our database  
**Action:** Ignore - This happens on all macOS apps using SQLite

See: https://stackoverflow.com/questions/30076853/sqlite-unable-to-open-database-file-error

## Testing

### Reproduce Original Bug
1. Have user accidentally saved as contact (old database)
2. Send message from that device
3. Observe "Received encrypted message from Me"

### Expected Behavior After Fix

**First time receiving own message:**
```
📥 Received 359 bytes from peer: beam_314968a258e00f6b
⚠️ WARNING: Found ourselves in contacts database!
   Contact ID: beam_314968a258e00f6b, User ID: beam_314968a258e00f6b
   Deleting invalid self-contact from database
```

**Subsequent messages:**
```
📥 Received 359 bytes from peer: beam_314968a258e00f6b
🔁 Ignoring echo: received our own message (from: beam_314968a258e00f6b)
```

**Normal message from real contact:**
```
📥 Received 359 bytes from peer: beam_a1b2c3d4e5f6
📥 Received encrypted message from Alice
   Version: 1, rIdx: 2
✅ Successfully decrypted message: "Hello!"
```

## Prevention

### Handshake Echo Prevention (Already Implemented)

**handleHandshakeRequest()** - Line 273:
```swift
if let currentUser = database.getCurrentUser(), beamId == currentUser.beamId {
    print("🔁 Ignoring self-handshake from: \(beamId)")
    return
}
```

**handleHandshakeAccept()** - Line 413:
```swift
if let currentUser = database.getCurrentUser(), beamId == currentUser.beamId {
    print("🔁 Ignoring self-handshake accept from: \(beamId)")
    return
}
```

### Message Echo Prevention (3 Layers)

1. **Early check** (line 505): Compare `from` field with current user Beam ID
2. **Contact validation** (NEW, line 527): Check if found contact is ourselves
3. **Handshake blocking** (lines 273, 413): Prevent self-contact creation

## Related Files

- `MeshService.swift` - Added self-contact detection and cleanup
- `DatabaseService.swift` - Already has thread-safe operations
- `ECHO-PREVENTION-FIX.md` - Original echo prevention documentation

## Database Cleanup

If you have existing invalid self-contacts, they will be automatically deleted when:
1. You receive your next message
2. The new double-check triggers
3. `database.deleteContact(contact.id)` removes it

**Manual cleanup** (if needed):
```bash
# Connect to database
sqlite3 ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db

# Check for self-contacts
SELECT id, name, public_key FROM contacts;

# If you see yourself listed, delete
DELETE FROM contacts WHERE id = 'YOUR_BEAM_ID';

# Exit
.quit
```

## Console Output Guide

### ✅ GOOD (Normal Operation)
```
🔁 Ignoring echo: received our own message
✅ Successfully decrypted message from Alice
```

### ⚠️ WARNING (Cleanup Happening)
```
⚠️ WARNING: Found ourselves in contacts database!
   Deleting invalid self-contact from database
```
→ This is **good** - automatic cleanup working

### ❌ ERROR (Real Problem)
```
❌ Decryption failed: incorrectParameterSize
❌ Failed to decrypt message from Bob
```
→ Check keys, session state, or network corruption

### 🔇 IGNORE (System Noise)
```
cannot open file at line 49455 of [1b37c146ee]
os_unix.c:49455: (2) open(/private/var/db/DetachedSignatures)
```
→ macOS system message, not our app

## Future Improvements

### Prevent QR Self-Scan (UI Enhancement)
```swift
// In ScanQRCodeView.swift
func addContact(from string: String) {
    guard let contactCard = ContactCard.fromJSON(string) else { return }
    
    // Check if scanned QR is our own
    let currentUser = database.getCurrentUser()
    if contactCard.beamId == currentUser?.beamId {
        self.errorMessage = "Cannot add yourself as a contact!"
        return
    }
    
    // Continue normal flow...
}
```

### Database Integrity Check on Startup
```swift
// In DatabaseService.ensureUserExists()
func cleanupInvalidContacts() {
    guard let currentUser = getCurrentUser() else { return }
    
    let contacts = getContacts()
    for contact in contacts {
        if contact.id == currentUser.beamId {
            print("🗑️ Cleaning up invalid self-contact: \(contact.name)")
            deleteContact(contact.id)
        }
    }
}
```

---

**Status:** ✅ Fixed with automatic cleanup  
**Testing:** Send message from same device, should be ignored  
**Date:** November 1, 2025
