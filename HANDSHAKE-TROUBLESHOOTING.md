# Handshake Troubleshooting Guide

**Date:** November 1, 2025  
**Issue:** Messages failing to decrypt between devices  
**Root Cause:** Handshake not completed, contact not saved

## Symptoms

### Console Output
```
📥 Received encrypted message from Me
   Version: 1, rIdx: 8
❌ Decryption failed: incorrectParameterSize
```

### What This Means

**NOT an echo bug!** The message is from a different device:
- Sender: `beam_314968a258e00f6b` (iPhone)
- Receiver: `beam_238d07a5dfbc9383` (macOS)

The contact name "Me" is misleading - it's actually from another device that you haven't properly added as a contact.

## Root Cause

**Missing handshake completion** - The devices are connected via Multipeer but haven't exchanged crypto keys through the handshake protocol.

### Why Decryption Fails

1. **Device A** (iPhone) encrypts message with Device B's public key
2. **Device B** (macOS) receives encrypted message
3. **Device B** looks up sender in contacts database
4. **❌ Contact not found** - No public keys stored
5. **Decryption fails** - Can't decrypt without sender's keys

## Verification

### Check Contacts Database

**macOS:**
```bash
sqlite3 ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db \
  "SELECT id, name, public_key FROM contacts;"
```

**Expected:** Should show the iPhone's Beam ID and public keys  
**Actual:** Empty (no contacts)

### Check Console Logs

Look for handshake messages:
```
✅ Connected to peer: beam_xxx
🤝 Sending handshake to beam_xxx
🔔 New contact request from [Name] (beam_xxx)
```

**If missing:** Handshake was never sent or received

## Solution: Complete the Handshake

### Method 1: QR Code Exchange (Recommended)

**On Device A (iPhone):**
1. Open Beam app
2. Tap "My QR Code"
3. Show QR code to Device B

**On Device B (macOS):**
1. Open Beam app
2. Click "Scan QR Code"
3. Scan Device A's QR code
4. Wait for contact request notification
5. Click "Accept"

**Expected Result:**
```
✅ QR code scanned successfully: [Name] (beam_xxx)
🤝 Sending handshake to beam_xxx
🔔 New contact request from [Name]
[User clicks Accept]
✅ Accepted contact request from [Name]
✅ Handshake accepted by [Name] - contact saved
```

### Method 2: Manual Contact Request

If already connected:
1. Check for pending contact request notification
2. Click "Accept" if notification appears
3. If no notification, handshake was never initiated

### Method 3: Force Handshake (Debug)

**Disconnect and reconnect:**
1. Stop advertising/browsing on both devices
2. Start again
3. When connected, handshake should auto-send
4. Accept contact request on both sides

## Verification After Fix

### Check Contacts Again

```bash
sqlite3 ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db \
  "SELECT id, name FROM contacts;"
```

**Expected:**
```
beam_314968a258e00f6b|iPhone
beam_238d07a5dfbc9383|macOS
```

### Send Test Message

1. Select the contact
2. Send "test"
3. Check console for:

```
✅ Message encrypted successfully
📡 Sending 361 bytes to beam_xxx
✅ Sent message to [Contact]
```

**On receiving device:**
```
📨 Received 361 bytes from peer: beam_xxx
📥 Received encrypted message from [Contact]
✅ Successfully decrypted message: "test"
```

## Common Issues

### Issue: No Contact Request Notification

**Causes:**
1. Handshake never sent (connection dropped before handshake)
2. Handshake received but echo prevention blocked it (old bug, now fixed)
3. QR scan didn't trigger handshake

**Solution:**
- Restart both apps
- Ensure devices are connected (check connection status)
- Manually trigger by scanning QR code again

### Issue: Contact Request Stuck in Pending

**Causes:**
- User never clicked "Accept"
- Acceptance message failed to send (connection dropped)

**Solution:**
- Click "Accept" on the pending request
- Check console for `✅ Sending handshake accept`
- If nothing happens, contact may be corrupted - delete and re-add

### Issue: Contact Saved But Decryption Still Fails

**Causes:**
1. Wrong public keys stored (from incomplete handshake)
2. Key mismatch (devices using different keys than exchanged)
3. Session state corruption

**Solution:**
```bash
# Delete the contact
sqlite3 ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db \
  "DELETE FROM contacts WHERE id = 'beam_xxx';"

# Re-do handshake from scratch
# 1. Scan QR code
# 2. Accept contact request
# 3. Try sending message again
```

### Issue: "Me" as Contact Name

**Causes:**
- Test data from development
- Contact added with wrong display name

**Solution:**
```bash
# Check all contacts
sqlite3 ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db \
  "SELECT id, name FROM contacts;"

# Update contact name
sqlite3 ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db \
  "UPDATE contacts SET name = 'iPhone' WHERE id = 'beam_314968a258e00f6b';"
```

## Prevention

### Ensure Clean Handshake Flow

1. **Connect** - Devices discover each other via Multipeer
2. **Handshake Sent** - Auto-sent when connected
3. **Request Appears** - UI shows contact request notification
4. **User Accepts** - Click "Accept" button
5. **Keys Exchanged** - Both devices save contact with public keys
6. **Ready** - Can now send encrypted messages

### Verify Each Step

**After connection:**
```
✅ Connected to peer: beam_xxx
🤝 Sending handshake to beam_xxx
```

**On receiving device:**
```
🔔 New contact request from [Name] (beam_xxx)
```

**After accepting:**
```
✅ Accepted contact request from [Name]
✅ Sending handshake accept to beam_xxx
```

**On other device:**
```
✅ Handshake accepted by [Name] - contact saved
```

## Error Messages Guide

| Error | Meaning | Solution |
|-------|---------|----------|
| `❌ Unknown sender: beam_xxx` | Contact not in database | Complete handshake |
| `❌ Decryption failed: incorrectParameterSize` | Wrong/missing keys | Delete contact, re-add |
| `🔁 Ignoring echo` | Message from yourself | Normal, working correctly |
| `❌ Message not for us` | Message meant for different device | Ignore |
| `⚠️ WARNING: Found ourselves in contacts` | Database corruption | Auto-deleted, re-add properly |

## Testing Checklist

- [ ] Both devices connected (check connection status)
- [ ] Handshake sent on both sides (check console)
- [ ] Contact request received (check UI notifications)
- [ ] Contact request accepted (click Accept)
- [ ] Contact saved in database (check with sqlite3)
- [ ] Test message sent (check console for "Sent message")
- [ ] Test message received (check for "Successfully decrypted")
- [ ] Messages appear in chat UI

## Console Output Reference

### ✅ Successful Handshake
```
✅ Connected to peer: beam_314968a258e00f6b
🤝 Sending handshake to beam_314968a258e00f6b
🔔 New contact request from iPhone (beam_314968a258e00f6b)
[User clicks Accept]
✅ Accepted contact request from iPhone
✅ Sending handshake accept to beam_314968a258e00f6b
✅ Handshake accepted by iPhone - contact saved
```

### ❌ Failed Handshake
```
✅ Connected to peer: beam_314968a258e00f6b
🤝 Sending handshake to beam_314968a258e00f6b
[Nothing happens - handshake never received]
```

### 📨 Successful Message Flow
```
📤 Attempting to send message to iPhone
✅ Message encrypted successfully
📡 Sending 361 bytes to beam_314968a258e00f6b
✅ Sent message to iPhone

[On receiving device:]
📨 Received 361 bytes from peer: beam_238d07a5dfbc9383
📥 Received encrypted message from macOS
✅ Successfully decrypted message: "Hello!"
```

### ❌ Failed Message (No Contact)
```
📨 Received 361 bytes from peer: beam_314968a258e00f6b
❌ Unknown sender: beam_314968a258e00f6b
⚠️  You need to complete the handshake with this device first!
   Scan their QR code or accept their contact request.
```

---

**Summary:** The "Received encrypted message from Me" error is actually a message from another device that hasn't completed the handshake. Complete the handshake flow (QR scan + accept) to fix!

**Date:** November 1, 2025  
**Status:** Documented and resolved
