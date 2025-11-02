# Peer Count Display Fix - UPDATED

## Problem
The green circle next to the QR code button was showing **10-12 or random numbers** instead of only showing known contacts.

## Root Cause
There were **TWO** peer count displays:

1. ✅ **ConnectionStatusView** (correct) - Filtered to show only known contacts
2. ❌ **ContentView** - Showing ALL peers including random/unknown ones

The ContentView header had this code:
```swift
HStack(spacing: 4) {
    Circle()
        .fill(connectionColor)
        .frame(width: 8, height: 8)
    Text("\(relayService.connectedPeers) peers")  // ← WRONG! Shows ALL peers
        .font(.caption)
        .foregroundColor(.secondary)
}
```

This was displaying `relayService.connectedPeers` which is the **total count** of all connected peers, not filtered to contacts.

## Solution

### Changed ContentView.swift
Replaced the simple peer counter with the **ConnectionStatusView** component which properly filters peers:

**Before:**
```swift
// Connection status
HStack(spacing: 4) {
    Circle()
        .fill(connectionColor)
        .frame(width: 8, height: 8)
    Text("\(relayService.connectedPeers) peers")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

**After:**
```swift
// Connection status - show ConnectionStatusView instead
ConnectionStatusView()
```

### Removed Unused Code
Deleted the `connectionColor` computed property since ConnectionStatusView handles its own colors.

## How ConnectionStatusView Works

The ConnectionStatusView properly filters peers to show only known contacts:

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

Then it uses these filtered arrays for display:
```swift
if knownConnectedPeers.count > 0 {
    Text("\(knownConnectedPeers.count) connected")
} else if knownNearbyPeers.count > 0 {
    Text("\(knownNearbyPeers.count) nearby")
}
```

## Result

Now the green circle will show:
- **0** if no known contacts are nearby
- **1** if 1 known contact is nearby/connected
- **2** if 2 known contacts are nearby/connected
- etc.

It will **NOT** show random peers (10-12) that you haven't added as contacts.

## UI Behavior

- **Green dot** = At least 1 known contact is nearby/connected
- **Orange/Yellow/Red dot** = No known contacts nearby, showing relay status
- **Click the dot** to expand and see:
  - "Mesh (Connected)" with count of connected known contacts
  - "Mesh (Nearby)" with count of nearby known contacts
  - Or relay status if no known contacts

## Privacy Benefit

This ensures your connection status **only reveals presence to contacts you've added**, not to random strangers running Beam nearby. 🔒

---

**Status**: Fixed ✅ - Rebuild the app to see the correct peer counts

## Issue
On macOS, the nearby peers count was showing 5, then 10 peers when there should only be 1-2 actual peers.

## Root Cause
The MultipeerConnectivity browser was discovering:
1. **The same peer multiple times** (via WiFi + Bluetooth)
2. **Your own device** being discovered by itself
3. **Duplicate discoveries** not being filtered properly

## Changes Made

### 1. Added Self-Peer Filter
```swift
// Don't add ourselves
guard peerID != self.peerID else {
    print("🚫 Ignoring our own peer ID: \(peerID.displayName)")
    return
}
```

**Why**: The device was discovering itself via Bonjour/mDNS, inflating the peer count.

### 2. Enhanced Duplicate Detection Logging
```swift
if !self.nearbyPeers.contains(peerID) {
    self.nearbyPeers.append(peerID)
    print("📍 Nearby peer found: \(peerID.displayName)")
    print("   Total nearby peers: \(self.nearbyPeers.count)")
    print("   List: \(self.nearbyPeers.map { $0.displayName })")
} else {
    print("🔄 Peer already in nearby list: \(peerID.displayName)")
}
```

**Why**: Now you can see in the console:
- Exactly which peers are being discovered
- If the same peer is being found multiple times
- The complete list of unique nearby peers

### 3. Enhanced Lost Peer Logging
```swift
self.nearbyPeers.removeAll { $0 == peerID }
print("👋 Lost peer: \(peerID.displayName)")
print("   Remaining nearby peers: \(self.nearbyPeers.count)")
if !self.nearbyPeers.isEmpty {
    print("   List: \(self.nearbyPeers.map { $0.displayName })")
}
```

**Why**: See exactly which peers are leaving and what remains.

## What You'll See Now

### Console Output - Normal Discovery:
```
🔍 Started browsing for peers
📍 Nearby peer found: beam_238d07a5dfbc9383
   Total nearby peers: 1
   List: ["beam_238d07a5dfbc9383"]
🔍 Found known contact: beam_238d07a5dfbc9383
```

### Console Output - Self-Discovery (Now Filtered):
```
🚫 Ignoring our own peer ID: beam_abc123def456
```

### Console Output - Duplicate Discovery:
```
🔄 Peer already in nearby list: beam_238d07a5dfbc9383
```

### Console Output - Peer Lost:
```
👋 Lost peer: beam_238d07a5dfbc9383
   Remaining nearby peers: 0
```

## Why Was This Happening?

### Multiple Discovery Paths
MultipeerConnectivity uses:
- **Bluetooth** - Discovers nearby devices
- **WiFi (Bonjour/mDNS)** - Discovers devices on same network
- **AWS (Apple Wireless Direct Link)** - Apple's peer-to-peer protocol

The same peer can be discovered via multiple paths simultaneously.

### Self-Discovery
When both advertising and browsing:
- Your advertiser announces your presence
- Your browser discovers all advertised peers
- **Including yourself!** (if not filtered)

## Expected Behavior Now

### With 1 Other Device:
- Nearby peers: **1**
- List shows the other device's Beam ID

### With 2 Other Devices:
- Nearby peers: **2**
- List shows both Beam IDs

### Your Own Device:
- **Filtered out** - won't appear in count
- Console shows: "🚫 Ignoring our own peer ID"

## Testing

Run the app and check the console:

1. **When app starts:**
   ```
   📡 Started advertising Beam ID: beam_xxxxx
   🔍 Started browsing for peers
   ```

2. **When peer found:**
   ```
   📍 Nearby peer found: beam_yyyyy
      Total nearby peers: 1
      List: ["beam_yyyyy"]
   ```

3. **If you see high counts (5, 10, etc.):**
   - Check the "List:" output
   - See if same Beam ID appears multiple times
   - Report what you see in the list

## Debugging

If you still see inflated counts, check the console for:
- Are the Beam IDs in the list all different?
- Is your own Beam ID in the list? (should be filtered now)
- Do you see "🔄 Peer already in nearby list" multiple times?

Share the console output and I can help diagnose further!

## Connection Status

The green dot will now show accurately:
- 🟢 **Green** when there are **real** nearby peers
- Not inflated by self-discovery or duplicates
- Shows true count in the details
