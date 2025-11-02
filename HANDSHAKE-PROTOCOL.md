# Handshake Protocol Implementation

## Overview
Implemented automatic peer discovery with manual contact approval - solving the issue where devices could connect but couldn't exchange messages because public keys weren't in each other's databases.

## Previous Flow (Broken)
```
1. iPhone connects to macOS ❌
2. iPhone sends encrypted message ❌
3. macOS rejects: "Unknown sender" ❌
4. User confused - no way to add contact!
```

## New Flow (Working)
```
1. ✅ Devices discover each other via MultipeerConnectivity
2. ✅ Both accept connection (no restriction)
3. 🤝 Automatic handshake - exchange public keys
4. 🔔 Notification appears: "Alice wants to connect"
5. 👤 User clicks "Accept" or "Reject"
6. ✅ If accepted - contact saved with public key
7. 💬 Can now send encrypted messages!
```

## Protocol Details

### Message Types

#### 1. `handshake_request`
Sent automatically when peer connects.

```json
{
  "type": "handshake_request",
  "contactCard": {
    "beamId": "beam_314968a258e00f6b",
    "name": "Alice's iPhone",
    "publicKey": "base64_encoded_public_key"
  }
}
```

**Receiver behavior:**
- If contact already exists → auto-accept and send `handshake_accept`
- If new contact → add to `pendingContactRequests` → show UI notification

#### 2. `handshake_accept`
Sent when user accepts contact request (or automatically if already have contact).

```json
{
  "type": "handshake_accept",
  "contactCard": {
    "beamId": "beam_7d2a3f1b4c8e9d0a",
    "name": "Bob's Mac",
    "publicKey": "base64_encoded_public_key"
  }
}
```

**Receiver behavior:**
- Save contact to database
- Initialize encryption session
- Can now exchange encrypted messages

#### 3. `handshake_reject`
Sent when user rejects contact request.

```json
{
  "type": "handshake_reject"
}
```

**Receiver behavior:**
- Log rejection
- Connection remains active (can retry later)

#### 4. `message` (existing)
Encrypted message - only works AFTER handshake is accepted.

```json
{
  "type": "message",
  "messageId": "uuid",
  "encryptedMessage": { ... },
  "timestamp": 1699123456.789
}
```

## Code Changes

### MeshService.swift
Added:
- `@Published var pendingContactRequests: [ContactCard]` - For UI to display
- `sendHandshake(to:)` - Automatic on connection
- `handleHandshakeRequest(_:from:)` - Parse and notify user
- `acceptContactRequest(_:)` - Save contact, init encryption
- `rejectContactRequest(_:)` - Remove from pending
- `sendHandshakeAccept(to:)` - Respond with our public key
- `handleHandshakeAccept(_:from:)` - Save peer's contact
- Packet routing in `handleReceivedMessage` to dispatch message types

### ContentView.swift (macOS)
Added:
- `@StateObject private var meshService = MeshService.shared`
- Overlay with `ContactRequestNotification` views
- Animation for sliding notifications from top

### ContactRequestNotification
New SwiftUI view:
- Shows contact name and Beam ID
- Accept button (green, prominent)
- Reject button (gray, bordered)
- Auto-dismisses with animation

## User Experience

### Scenario: iPhone (Alice) wants to message Mac (Bob)

1. **Alice opens Beam on iPhone**
   - Beam advertises: `beam_314968a258e00f6b` (Alice)
   
2. **Bob opens Beam on Mac**
   - Beam advertises: `beam_7d2a3f1b4c8e9d0a` (Bob)
   
3. **Devices discover each other**
   ```
   Mac console: 📍 Nearby peer found: beam_314968a258e00f6b
   Mac console: 🔍 Found new peer - sending invitation
   iPhone console: ✅ Accepting invitation from new peer
   ```

4. **Connection established**
   ```
   Both: ✅ Connected to peer: beam_xxx
   Both: 🤝 Sending handshake to beam_xxx
   ```

5. **Mac shows notification**
   ```
   ┌──────────────────────────────────────────┐
   │ 👤 Contact Request                       │
   │ Alice's iPhone wants to connect          │
   │                    [Accept]   [Reject]   │
   └──────────────────────────────────────────┘
   ```

6. **Bob clicks "Accept"**
   - Mac saves Alice's contact with public key
   - Mac sends `handshake_accept` with Bob's public key
   - iPhone receives and saves Bob's contact
   
7. **Handshake complete!**
   ```
   Mac: ✅ Accepted contact request from Alice's iPhone
   iPhone: ✅ Handshake accepted by Bob's Mac - contact saved
   ```

8. **Alice sends message**
   - iPhone encrypts with Bob's public key
   - Mac decrypts with Bob's private key
   - Message appears in chat! 💬

## Security Model

### Connection Layer (Open)
- **Any peer can connect** via MultipeerConnectivity
- No authentication required
- Just transport mechanism

### Handshake Layer (Manual Approval)
- **User must approve** each contact
- Public keys exchanged over encrypted MCSession
- Prevents spam/unwanted contacts

### Message Layer (Encrypted)
- **Double Ratchet encryption** with approved contacts only
- Messages rejected if sender not in contacts database
- End-to-end encrypted, forward secret

## Advantages

1. **No QR scanning required** for initial connection
2. **Works locally** - no internet, no relay servers
3. **User control** - explicit approval for each contact
4. **Automatic discovery** - devices find each other when nearby
5. **Spam protection** - can reject unknown peers
6. **Persistent contacts** - saved to database after approval

## Future Enhancements

- [ ] Contact request timeout (auto-reject after 5 minutes)
- [ ] Nickname customization before accepting
- [ ] Block list for rejected contacts
- [ ] Re-send request option if rejected
- [ ] Group handshakes for multiple peers
- [ ] QR code as backup (for out-of-band verification)

## Testing

To test the handshake:

1. **Reset both devices**
   ```bash
   # Delete databases to start fresh
   rm ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db
   ```

2. **Start Mac app**
   ```
   Console should show:
   📡 Started advertising Beam ID: beam_xxx
   🔍 Started browsing for peers
   ```

3. **Start iPhone app**
   ```
   Should discover Mac and connect automatically
   ```

4. **Check Mac screen**
   ```
   Notification should appear at top:
   "iPhone wants to connect [Accept] [Reject]"
   ```

5. **Click Accept**
   ```
   Contact should appear in sidebar
   Can now send messages!
   ```

## Troubleshooting

**"Not in connected state" errors:**
- These are normal during connection setup
- MultipeerConnectivity establishing channels
- Handshake will work once connection stable

**No notification appears:**
- Check `meshService.pendingContactRequests` in debugger
- Verify `NewContactRequest` NotificationCenter post
- Check console for "🔔 New contact request" log

**Messages still rejected:**
- Ensure handshake was accepted on BOTH sides
- Check `database.getContacts()` includes peer
- Verify public keys are stored (not empty strings)

**Handshake sent multiple times:**
- This is fine - only first one matters
- Duplicates are ignored (check by beamId)
- Accept button only shows once

---

**Status:** ✅ Implemented and ready for testing
**Date:** November 1, 2025
**Impact:** Critical - enables actual P2P messaging without QR scanning!
