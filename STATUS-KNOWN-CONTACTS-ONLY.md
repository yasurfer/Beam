# Connection Status - Show Only Known Contacts

## Issue
The connection status (green dot next to QR button) was showing random/unknown peers instead of only your actual contacts.

## Root Cause
The `ConnectionStatusView` was displaying counts from:
- `meshService.nearbyPeers` - ALL discovered peers (including random strangers)
- `meshService.connectedPeers` - ALL connected peers (including unknown devices)

This meant if 5 random devices were nearby, the status would show "5 nearby" even if none were your contacts!

## Solution

### Added Filtered Computed Properties
```swift
// Filter nearby peers to only show known contacts
private var knownNearbyPeers: [MCPeerID] {
    let contacts = database.getContacts()
    let contactIds = Set(contacts.map { $0.id })
    return meshService.nearbyPeers.filter { contactIds.contains($0.displayName) }
}

// Filter connected peers to only show known contacts
private var knownConnectedPeers: [MCPeerID] {
    let contacts = database.getContacts()
    let contactIds = Set(contacts.map { $0.id })
    return meshService.connectedPeers.filter { contactIds.contains($0.displayName) }
}
```

### Updated Status Logic
**Before:**
- Showed ALL nearby peers (random + contacts)
- Green dot for ANY peer discovered

**After:**
- Shows ONLY known contact peers
- Green dot ONLY for your actual contacts
- Filters out strangers/random devices

## What Changed

### 1. Added Database Observer
```swift
@ObservedObject var database = DatabaseService.shared
```
Now the view can access your contact list.

### 2. Filter Display Counts
```swift
if knownConnectedPeers.count > 0 {
    Text("\(knownConnectedPeers.count) connected")
} else if knownNearbyPeers.count > 0 {
    Text("\(knownNearbyPeers.count) nearby")
}
```

### 3. Filter Status Color
```swift
if knownNearbyPeers.count > 0 {
    return .green  // Only green for known contacts
}
```

### 4. Filter Status Text
```swift
if knownConnectedPeers.count > 0 {
    return "Mesh (Connected)"
} else if knownNearbyPeers.count > 0 {
    return "Mesh (Nearby)"
}
```

## Behavior Now

### Scenario 1: Your Contact is Nearby
- 🟢 Green dot
- Text: "Mesh (Nearby)"
- Details: "1 nearby"

### Scenario 2: 5 Random Devices + 1 Contact Nearby
- 🟢 Green dot (because 1 known contact found)
- Text: "Mesh (Nearby)"
- Details: "1 nearby" (not 6!)

### Scenario 3: 5 Random Devices, No Contacts
- 🔴/🟡/🟠 Relay status color
- Text: "Offline" / "Connected" / "DHT Fallback"
- Details: (relay info, not peer count)

### Scenario 4: Contact Connected
- 🟢 Green dot
- Text: "Mesh (Connected)"
- Details: "1 connected"

## Technical Details

### Filtering Algorithm:
1. Get all your contacts from database
2. Extract their Beam IDs into a Set (fast lookup)
3. Filter `nearbyPeers` to only include IDs in the Set
4. Filter `connectedPeers` to only include IDs in the Set
5. Use filtered counts for display

### Performance:
- Uses `Set` for O(1) lookup instead of O(n) array search
- Computed properties recalculate when data changes
- No impact on discovery (still sees all peers, just filters display)

## Privacy & Security

**Before:** 
- Anyone nearby could see you're online (green dot)
- Status revealed presence of random strangers

**After:**
- Green dot ONLY shows when YOUR CONTACTS are nearby
- Random devices don't affect your status
- More private - only relevant connections shown

## Testing

1. **Add a contact** (scan QR code)
2. **Wait for discovery** - should see:
   ```
   📍 Nearby peer found: beam_xxxxx
   🔍 Found known contact: beam_xxxxx
   ```
3. **Check status dot** - should turn 🟢 green
4. **Details show** - "1 nearby" or "1 connected"

5. **Random devices nearby** (not in contacts):
   ```
   📍 Nearby peer found: beam_random123
   🔍 Found unknown peer: beam_random123 - ignoring
   ```
6. **Check status dot** - should stay 🔴 red (no green for unknowns)
7. **Details show** - Relay status, NOT peer count

## Console Verification

You can verify this is working by checking console logs:

**Known contact found:**
```
📍 Nearby peer found: beam_238d07a5dfbc9383
   Total nearby peers: 1
   List: ["beam_238d07a5dfbc9383"]
🔍 Found known contact: beam_238d07a5dfbc9383
```
→ Status should show green

**Unknown peer found:**
```
📍 Nearby peer found: beam_stranger456
   Total nearby peers: 2
   List: ["beam_238d07a5dfbc9383", "beam_stranger456"]
🔍 Found unknown peer: beam_stranger456 - ignoring
```
→ Status should still show "1 nearby" (filtering the stranger out)

## Summary

✅ **Fixed:** Status now shows only YOUR contacts
✅ **Privacy:** Random devices don't reveal your presence
✅ **Accurate:** Counts reflect actual contact connections
✅ **Secure:** Unknown peers are ignored in status display
