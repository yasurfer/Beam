# Connection Status - Green Dot for Peer Discovery

## What Changed

Updated the connection status indicator to show a **green dot when peers are nearby** (discovered via Bonjour/mDNS), not just when fully connected.

## Changes Made

### 1. MeshService.swift
**Added tracking for nearby peers:**
```swift
@Published var nearbyPeers: [MCPeerID] = []
```

**Updated browser delegate to track peer discovery:**
- When a peer is found → Added to `nearbyPeers` list
- When a peer is lost → Removed from `nearbyPeers` list
- Console logs show nearby peer count

### 2. ConnectionStatusView.swift
**Updated status logic:**

**Before:**
- 🟢 Green = Peers connected
- 🔴 Red/Yellow/Orange = No peers connected

**After:**
- 🟢 Green = Peers nearby (discovered)
- 🟢 Green = Peers connected
- 🔴 Red/Yellow/Orange = No peers found

**Status text shows:**
- "Mesh (Connected)" - when peers are connected
- "Mesh (Nearby)" - when peers are discovered but not yet connected
- Shows count: "X connected" or "X nearby"

## How It Works

### Discovery Flow:
1. **Browsing starts** → Looking for peers
2. **Peer found** → 🟢 Green dot appears ("Mesh (Nearby)")
3. **Connection established** → 🟢 Green dot stays ("Mesh (Connected)")
4. **Peer lost** → If no other peers, dot changes to relay status

### Console Logs:
```
📍 Nearby peer found: beam_xxxxx
   Total nearby peers: 1
```

When peer is lost:
```
👋 Lost peer: beam_xxxxx
   Remaining nearby peers: 0
```

## Benefits

1. **Faster Feedback** - Users see green dot as soon as peers are discovered
2. **Better UX** - No waiting for full connection to see status
3. **Clear States** - Distinction between "nearby" and "connected"
4. **Accurate Count** - Shows how many peers are in range

## Testing

1. **Start both devices** (macOS and iOS)
2. **Watch the status dot**:
   - Should turn 🟢 green when peer is discovered
   - Console shows "📍 Nearby peer found"
3. **Click the status dot** to see details:
   - Shows "Mesh (Nearby)" or "Mesh (Connected)"
   - Shows count of peers

## States

| State | Color | Text | Count |
|-------|-------|------|-------|
| Peers nearby (not connected) | 🟢 Green | "Mesh (Nearby)" | "X nearby" |
| Peers connected | 🟢 Green | "Mesh (Connected)" | "X connected" |
| No peers, relay connected | 🟠 Orange | "Connected" | - |
| No peers, DHT fallback | 🟡 Yellow | "DHT Fallback" | - |
| No peers, offline | 🔴 Red | "Offline" | - |

## Implementation Details

### nearbyPeers vs connectedPeers:
- **nearbyPeers** = Discovered via Bonjour (browser found them)
- **connectedPeers** = Full MCSession connection established

A peer moves from `nearbyPeers` discovery to `connectedPeers` when the connection handshake completes.

### Priority:
Green dot shows if ANY peers are nearby, giving immediate feedback that discovery is working.
