# Message Receiving Fix

## Problems Found and Fixed

### 1. **Missing rIdx (Ratchet Index) in Message Packet**
   - **Problem**: The original code wasn't sending the `rIdx` field, which is crucial for the Double Ratchet encryption algorithm
   - **Impact**: Receiving device couldn't decrypt messages because it didn't know which key in the chain to use
   - **Fix**: Now sending the complete `encryptedMessage` structure with all fields including `rIdx`

### 2. **Incomplete Message Structure**
   - **Problem**: Only sending `encryptedContent`, `nonce`, and `signature` separately
   - **Impact**: Missing protocol version (`v`), sender (`from`), recipient (`to`), timestamp (`t`), and ratchet index (`rIdx`)
   - **Fix**: Sending the complete `EncryptedMessage` structure as a nested object

### 3. **Better Error Logging**
   - **Added**: Detailed debug logs to help diagnose issues:
     - Connection status with peer counts
     - Byte counts for sent/received data
     - Encryption success with ratchet index
     - Clear error messages with context

## What Changed

### Sending Messages (sendMessage)
**Before:**
```swift
let packet: [String: Any] = [
    "type": "message",
    "messageId": message.id,
    "encryptedContent": encryptedMessage.ciphertext,
    "nonce": encryptedMessage.nonce,
    "signature": encryptedMessage.sig,  // Missing rIdx!
    "timestamp": message.timestamp.timeIntervalSince1970,
    "senderBeamId": peerID.displayName
]
```

**After:**
```swift
let packet: [String: Any] = [
    "type": "message",
    "messageId": message.id,
    "encryptedMessage": [
        "v": encryptedMessage.v,
        "from": encryptedMessage.from,
        "to": encryptedMessage.to,
        "t": encryptedMessage.t,
        "rIdx": encryptedMessage.rIdx,  // ✅ Now included!
        "nonce": encryptedMessage.nonce,
        "ciphertext": encryptedMessage.ciphertext,
        "sig": encryptedMessage.sig
    ],
    "timestamp": message.timestamp.timeIntervalSince1970
]
```

### Receiving Messages (handleReceivedMessage)
**Before:**
```swift
// Only parsed 5 fields, missing rIdx and others
guard let messageId = packet["messageId"] as? String,
      let encryptedContent = packet["encryptedContent"] as? String,
      let nonceBase64 = packet["nonce"] as? String,
      let signatureBase64 = packet["signature"] as? String,
      let timestampInterval = packet["timestamp"] as? TimeInterval,
      let senderBeamId = packet["senderBeamId"] as? String else {
```

**After:**
```swift
// Now properly parses the complete encryptedMessage structure
guard let messageId = packet["messageId"] as? String,
      let encryptedMessageDict = packet["encryptedMessage"] as? [String: Any],
      let timestampInterval = packet["timestamp"] as? TimeInterval else {
    
// Then extracts all 8 required fields including rIdx:
guard let v = encryptedMessageDict["v"] as? Int,
      let from = encryptedMessageDict["from"] as? String,
      let to = encryptedMessageDict["to"] as? String,
      let t = encryptedMessageDict["t"] as? Int64,
      let rIdx = encryptedMessageDict["rIdx"] as? UInt64,  // ✅ Now extracted!
      let nonce = encryptedMessageDict["nonce"] as? String,
      let ciphertext = encryptedMessageDict["ciphertext"] as? String,
      let sig = encryptedMessageDict["sig"] as? String else {
```

## Testing Steps

1. **Build and Run on Both Devices**
   - Clean build on macOS: `Cmd+Shift+K` then `Cmd+B`
   - Clean build on iOS: Same process
   
2. **Check Console Logs**
   When sending a message, you should see:
   ```
   📤 Attempting to send message to [Contact Name] ([Beam ID])
      Connected peers: [list of peers]
   ✅ Found peer: [peer ID]
   ✅ Message encrypted successfully
      rIdx: [number]
   📡 Sending [bytes] bytes to [peer]
   ✅ Sent message to [Contact Name]
   ```

   When receiving a message, you should see:
   ```
   📨 Received [bytes] bytes from peer: [Beam ID]
   📥 Received encrypted message from [Contact Name]
      Version: 1, rIdx: [number]
   ✅ Successfully decrypted message: "[message content]"
   ✅ Received and saved message from [Contact Name]
   ```

3. **Troubleshooting**

   **If you see "Peer not connected":**
   - Check if both devices are on same WiFi/Bluetooth
   - Check the "Connected peers" list in the log
   - Make sure both apps have started the mesh service

   **If you see "Failed to decrypt message":**
   - Check if the rIdx values match on both ends
   - Verify both devices have the same contact (same Beam ID and public key)
   - Try deleting and re-adding the contact on both devices

   **If messages aren't being received at all:**
   - Check if you see the "📨 Received X bytes" log - if not, it's a network issue
   - Verify both devices show each other in connected peers
   - Check firewall/network settings

## Next Steps

1. Test message sending from iPhone to macOS
2. Test message sending from macOS to iPhone
3. Check console logs on both devices
4. If still not working, share the console output from both devices

## Important Notes

- The `rIdx` (ratchet index) is crucial for the Double Ratchet algorithm - each message must include it
- Messages are now properly structured following the `EncryptedMessage` format
- All fields (v, from, to, t, rIdx, nonce, ciphertext, sig) are preserved during transmission
- Better error messages will help diagnose any remaining issues
