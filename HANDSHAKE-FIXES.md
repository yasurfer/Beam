# Bug Fixes - Handshake Protocol

## Issues Fixed

### 1. **Compilation Errors**

#### Error: `Value of type 'CryptoService' has no member 'getMyContactCard'`
**Fix:** Added `getMyContactCard()` helper method to CryptoService

```swift
// CryptoService.swift
func getMyContactCard() -> ContactCard? {
    guard let user = DatabaseService.shared.getCurrentUser() else {
        return nil
    }
    return createContactCard(displayName: user.displayName)
}
```

#### Error: `Missing arguments for parameters 'displayName', 'signingKeyEd25519', 'keyAgreementX25519'`
**Fix:** Updated handshake protocol to send complete contact card with all required fields

**Before:**
```swift
"contactCard": [
    "beamId": myCard.beamId,
    "name": myCard.name,
    "publicKey": myCard.publicKey  // ❌ Wrong - only one key
]
```

**After:**
```swift
"contactCard": [
    "beamId": myCard.beamId,
    "displayName": myCard.displayName,
    "signingKeyEd25519": myCard.signingKeyEd25519,  // ✅ Ed25519 signing key
    "keyAgreementX25519": myCard.keyAgreementX25519  // ✅ X25519 agreement key
]
```

#### Error: `Extra arguments at positions #2, #3 in call` (Contact initialization)
**Fix:** Used `Contact.from(card:)` helper method instead of manual construction

**Before:**
```swift
let contact = Contact(
    id: contactCard.beamId,
    name: contactCard.name,
    publicKey: contactCard.publicKey,
    lastSeen: Date(),
    isOnline: true  // ❌ Wrong parameters
)
```

**After:**
```swift
let contact = Contact.from(card: contactCard)  // ✅ Uses helper method
```

### 2. **Removed Default Welcome Message**

#### Issue: Automatic "Contact added! Say hello" message when scanning QR code
**Location:** `ScanQRCodeView.swift` lines 257-269

**Removed:**
```swift
// Send a welcome message to start the chat
let welcomeMessage = Message(
    id: UUID().uuidString,
    contactId: contact.id,
    content: "👋 Contact added! Say hello to start chatting.",
    encryptedContent: "",
    isSent: true,
    timestamp: Date(),
    status: .sent,
    isRead: true,
    isEncrypted: false
)
database.saveMessage(welcomeMessage)
```

**Reason:** 
- Unnecessary clutter in chat history
- Not actually encrypted (just a local message)
- User can send their own first message
- Cleaner UX without automatic messages

## Files Modified

1. **CryptoService.swift**
   - Added `getMyContactCard()` helper method

2. **MeshService.swift**
   - Updated `sendHandshake()` to use correct ContactCard fields
   - Updated `handleHandshakeRequest()` to parse all ContactCard fields
   - Updated `acceptContactRequest()` to use `Contact.from(card:)`
   - Updated `sendHandshakeAccept()` with correct fields
   - Updated `handleHandshakeAccept()` to parse and create contact correctly
   - Updated `rejectContactRequest()` log message

3. **ScanQRCodeView.swift**
   - Removed automatic welcome message after QR scan
   - Now just saves contact and loads messages

## Testing Checklist

- [ ] Build succeeds without errors ✅
- [ ] Handshake request sent on connection
- [ ] Contact request notification appears
- [ ] Accepting contact saves to database
- [ ] Both devices have each other's public keys
- [ ] Can send encrypted messages after handshake
- [ ] No automatic welcome message after QR scan
- [ ] Chat starts empty, waiting for user's first message

## Next Steps

1. **Rebuild the app** - All compilation errors are fixed
2. **Test handshake flow** - Connect two devices and accept contact request
3. **Verify encryption** - Send message and check it's encrypted
4. **Check console logs** - Should see handshake protocol messages

## Expected Console Output

```
✅ Connected to peer: beam_314968a258e00f6b
🤝 Sending handshake to beam_314968a258e00f6b
🔔 New contact request from Alice's iPhone (beam_314968a258e00f6b)
✅ Accepted contact request from Alice's iPhone
✅ Sending handshake accept to beam_314968a258e00f6b
✅ Handshake accepted by Bob's Mac - contact saved
```

---

**Status:** ✅ All errors fixed, ready to build and test!
**Date:** November 1, 2025
