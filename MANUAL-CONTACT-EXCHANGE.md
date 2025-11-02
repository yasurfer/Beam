# Manual Contact Exchange (Debug Mode)

**Date:** November 1, 2025  
**Purpose:** Workaround for camera issues on macOS  
**Status:** ✅ Ready to use

## Problem

Camera on macOS not working for QR code scanning, preventing handshake completion.

## Solution

Use **debug mode** to manually copy/paste contact cards between devices.

---

## Step-by-Step Instructions

### On iPhone (Source Device)

1. **Open Beam app**
2. **Tap "My QR Code"**
3. **Tap "Copy Contact Card (Debug)"** button (orange button)
4. **Check Xcode console** - You'll see:

```
================================================================================
📇 CONTACT CARD (Copy this to manually add contact)
================================================================================
{"beamId":"beam_314968a258e00f6b","displayName":"iPhone","signingKeyEd25519":"...","keyAgreementX25519":"...","sig":"..."}
================================================================================

To manually add this contact on another device:
1. Copy the JSON above
2. On the other device, run in Xcode console:
   po MeshService.shared.addContactFromJSON("PASTE_JSON_HERE")
================================================================================
```

5. **Copy the JSON** (the long string between the === lines)

### On macOS (Target Device)

1. **Open Xcode** with Beam project
2. **Run the app** in debug mode
3. **Open Debug Console** (View → Debug Area → Show Debug Area)
4. **Click in the console** at the bottom
5. **Type this command:**

```
po MeshService.shared.addContactFromJSON("PASTE_YOUR_JSON_HERE")
```

**Example:**
```
po MeshService.shared.addContactFromJSON("{\"beamId\":\"beam_314968a258e00f6b\",\"displayName\":\"iPhone\",\"signingKeyEd25519\":\"...\",\"keyAgreementX25519\":\"...\",\"sig\":\"...\"}")
```

6. **Press Enter**

### Expected Output

```
✅ Manually added contact: iPhone (beam_314968a258e00f6b)
   You can now send encrypted messages to this contact!
```

### Verify Contact Was Added

```
po DatabaseService.shared.getContacts()
```

**Expected:**
```
1 contact(s):
- iPhone (beam_314968a258e00f6b)
```

---

## Reverse Direction (macOS → iPhone)

### On macOS

1. **Click "My QR Code"** in Beam app
2. **Click "Copy Contact Card (Debug)"** (orange button)
3. **Check console** for the JSON
4. **Copy the JSON**

### On iPhone

1. **Open Xcode** console while iPhone is connected
2. **Type in console:**

```
po MeshService.shared.addContactFromJSON("PASTE_JSON_HERE")
```

3. **Press Enter**

---

## Testing Message Exchange

### After Both Contacts Added

**On macOS:**
1. Open Beam app
2. Click on "iPhone" contact
3. Type a message
4. Send

**Expected Console Output (macOS):**
```
📤 Attempting to send message to iPhone
✅ Message encrypted successfully
📡 Sending 361 bytes to beam_314968a258e00f6b
✅ Sent message to iPhone
```

**Expected Console Output (iPhone):**
```
📨 Received 361 bytes from peer: beam_238d07a5dfbc9383
📥 Received encrypted message from macOS
✅ Successfully decrypted message: "Hello!"
```

---

## Troubleshooting

### Error: "Invalid contact card JSON"

**Cause:** JSON string malformed or incomplete

**Solution:**
1. Make sure you copied the ENTIRE JSON string
2. Check for missing quotes or braces
3. The JSON should start with `{` and end with `}`

### Error: "Contact card signature verification failed"

**Cause:** JSON was corrupted during copy/paste

**Solution:**
1. Copy the JSON again from source device
2. Use "Copy Contact Card" button, don't manually copy from console
3. Paste carefully without extra characters

### Error: "Contact already exists"

**Cause:** Contact was already added

**Solution:**
- This is fine! Contact is already in database
- You can verify with: `po DatabaseService.shared.getContacts()`

### No Contacts Showing in App

**Cause:** Database not refreshed in UI

**Solution:**
1. Close and reopen the app
2. Or navigate away and back to Contacts tab
3. Contacts should appear after refresh

### Messages Still Not Decrypting

**Possible causes:**
1. Contact added on only one side (need both sides)
2. Devices not connected via Multipeer
3. Wrong contact card copied

**Solution:**
1. Verify both devices have each other as contacts
2. Check connection status in console
3. Re-copy and re-add contact cards

---

## Console Commands Reference

### Add Contact from JSON
```
po MeshService.shared.addContactFromJSON("JSON_HERE")
```

### List All Contacts
```
po DatabaseService.shared.getContacts()
```

### Get Current User
```
po DatabaseService.shared.getCurrentUser()
```

### Check Connected Peers
```
po MeshService.shared.connectedPeers
```

### Delete Contact (if needed)
```
po DatabaseService.shared.deleteContact("beam_XXXXXXX")
```

---

## UI Features Added

### My QR Code View

**macOS & iOS:**
- ✅ "Copy Beam ID" button (blue) - Copies just the Beam ID
- ✅ "Copy Contact Card (Debug)" button (orange) - Copies full contact card JSON + prints to console

### Button Colors
- **Blue:** Normal user action (Copy Beam ID)
- **Orange:** Debug/advanced action (Copy Contact Card)

---

## Security Note

**The contact card JSON contains your PUBLIC keys only - it's safe to share!**

What's included:
- ✅ Beam ID (public identifier)
- ✅ Display Name (your chosen name)
- ✅ Signing Public Key Ed25519
- ✅ Key Agreement Public Key X25519
- ✅ Cryptographic Signature

What's NOT included:
- ❌ Private keys (always stay in keychain)
- ❌ Messages
- ❌ Session state

The signature ensures the contact card hasn't been tampered with.

---

## Example Workflow

### Complete Setup Between Two Devices

**Device A (iPhone):**
1. Open "My QR Code"
2. Click "Copy Contact Card (Debug)"
3. Send JSON to Device B via:
   - AirDrop the JSON file
   - Paste in Messages/Slack/Email
   - Or manually type in Xcode console

**Device B (macOS):**
1. Receive JSON from Device A
2. Run in Xcode console:
   ```
   po MeshService.shared.addContactFromJSON("JSON_FROM_A")
   ```
3. Open "My QR Code"
4. Click "Copy Contact Card (Debug)"
5. Send JSON back to Device A

**Device A (iPhone):**
1. Receive JSON from Device B
2. Run in Xcode console:
   ```
   po MeshService.shared.addContactFromJSON("JSON_FROM_B")
   ```

**Result:**
- Both devices have each other as contacts
- Can send encrypted messages
- No QR scanning needed!

---

## When to Use This

✅ **Use manual exchange when:**
- Camera not working on macOS
- Testing in simulator
- Debugging handshake issues
- Adding many contacts quickly
- Remote setup (sending JSON over internet)

❌ **Use QR code scanning for:**
- Production use
- Better UX
- In-person exchanges
- Non-technical users

---

## Production Note

This debug feature should be **disabled in production** by:
1. Removing the orange "Copy Contact Card" button
2. Or hiding it behind a debug flag
3. QR code is the intended user flow

But for development and testing, this is perfect! 🎉

---

**Created:** November 1, 2025  
**Status:** ✅ Ready to use  
**Testing:** Copy contact card from iPhone, paste on macOS, verify messaging works
