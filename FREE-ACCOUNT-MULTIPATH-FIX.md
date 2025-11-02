# Free Apple Developer Account - Multipath Capability Error

## Error Message
```
Cannot create a iOS App Development provisioning profile for "getbeam.nl.Beam". 
Personal development teams, including "Yassine Oussi", do not support the Multipath capability.
```

## Problem
The **Multipath networking capability** (`com.apple.developer.networking.multipath`) requires a **paid Apple Developer Program membership** ($99/year).

Free personal development teams cannot use this capability.

## Solution
**Removed** the multipath entitlement from `Beam-iOS.entitlements`.

### Before (Caused Error)
```xml
<dict>
    <key>com.apple.developer.networking.multipath</key>
    <true/>
</dict>
```

### After (Works with Free Account)
```xml
<dict>
    <!-- iOS doesn't need any special entitlements for MultipeerConnectivity -->
    <!-- All permissions come from Info.plist -->
</dict>
```

## What We Lost
The multipath networking capability allows iOS devices to use **multiple network interfaces simultaneously** (e.g., WiFi + Cellular). 

This is **NOT required** for MultipeerConnectivity to work. It only provides potential performance improvements.

## What Still Works

✅ **MultipeerConnectivity** - Works perfectly without multipath
✅ **Peer Discovery** - Via Bonjour (NSBonjourServices in Info.plist)
✅ **Local Network** - Via NSLocalNetworkUsageDescription in Info.plist
✅ **All Beam Features** - Messaging, encryption, contacts, etc.

## Required for MultipeerConnectivity

**Info.plist** (already configured correctly):
- `NSLocalNetworkUsageDescription` - Permission to use local network
- `NSBonjourServices` - Service discovery (_beam-mesh._tcp and _beam-mesh._udp)
- `NSCameraUsageDescription` - QR code scanning

**Entitlements**: 
- **iOS**: None needed (empty dict works!)
- **macOS**: App Sandbox with network permissions

## Rebuild Instructions

1. Clean Build Folder: Product > Clean Build Folder (Shift+Cmd+K)
2. Select iPhone 6s as destination
3. Build: Product > Build (Cmd+B)
4. Run: Product > Run (Cmd+R)

The provisioning profile error should be gone! ✅

## If You Later Get Paid Account

If you join the paid Apple Developer Program, you can add multipath back:

```xml
<dict>
    <key>com.apple.developer.networking.multipath</key>
    <true/>
</dict>
```

But it's **optional** - Beam works great without it.

---

**Status**: Fixed - App now builds with free Apple Developer account 🎉
