# Network Error -72008 Fix

## Problem
Error code `-72008` (NSNetServicesErrorDomain) means **Local Network permission is denied** or the app is missing required network entitlements.

## What I Fixed

### 1. **Info.plist - Fixed Bonjour Service Name**
Changed from `_beam._tcp` to `_beam-mesh._tcp` to match your actual service type.

**Before:**
```xml
<key>NSBonjourServices</key>
<array>
    <string>_beam._tcp</string>
</array>
```

**After:**
```xml
<key>NSBonjourServices</key>
<array>
    <string>_beam-mesh._tcp</string>
    <string>_beam-mesh._udp</string>
</array>
```

### 2. **Beam.entitlements - Added Network Permissions**
Added the required network client and server entitlements.

**Added:**
```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

## Steps to Fix

### Step 1: Clean Build
1. In Xcode, press **Cmd+Shift+K** (Clean Build Folder)
2. Wait for it to complete
3. Press **Cmd+B** to rebuild

### Step 2: Reset Local Network Permission
The macOS app might have been denied local network permission. To reset:

1. **Quit the Beam app completely**
2. Open **System Settings** (or System Preferences)
3. Go to **Privacy & Security** → **Local Network**
4. Find **Beam** in the list and toggle it OFF then ON
5. If Beam is not in the list, that's okay - it will appear after next run

### Step 3: Delete and Reinstall (Important!)
Since entitlements changed, you need to delete the old app:

1. **Quit Beam** if running
2. Go to `/Applications` (or wherever the app is installed)
3. **Delete Beam.app** completely
4. Empty Trash (Optional but recommended)
5. In Xcode, **Product → Clean Build Folder** (Cmd+Shift+K)
6. **Build and Run** (Cmd+R)

### Step 4: Grant Permission
When you first run the app after these changes:

1. macOS will show a dialog: **"Beam" would like to find and connect to devices on your local network**
2. Click **OK** or **Allow**
3. Check the console logs - you should see:
   ```
   📡 Started advertising Beam ID: [your-beam-id]
   🔍 Started browsing for peers
   ```

## Verification

### Success Indicators:
- ✅ No error `-72008` in console
- ✅ "Started advertising" appears without errors
- ✅ "Started browsing" appears without errors
- ✅ On iOS, scan the macOS QR code
- ✅ Console shows: "🔍 Found known contact: [beam-id]"
- ✅ Console shows: "✅ Connected to peer: [beam-id]"

### If Still Not Working:

1. **Check Console Logs** for both devices
2. **Ensure both devices are on the same WiFi network**
3. **Disable firewall temporarily** (System Settings → Network → Firewall)
4. **Check WiFi isolation** - some WiFi networks block device-to-device communication

## iOS Setup (if needed)

For iOS, also check that Info.plist has:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Beam uses local network to discover and communicate with nearby peers for decentralized messaging.</string>

<key>NSBonjourServices</key>
<array>
    <string>_beam-mesh._tcp</string>
    <string>_beam-mesh._udp</string>
</array>
```

iOS will show a permission dialog the first time the app tries to use local network.

## Common Issues

### Issue: Still getting -72008 after rebuild
**Solution:** Delete the app completely and reinstall. Entitlement changes require a fresh install.

### Issue: No permission dialog appears
**Solution:** The permission might be cached. Reset by:
1. Settings → Privacy & Security → Local Network
2. Toggle Beam OFF and ON

### Issue: Peers not finding each other
**Solution:** 
- Both devices must be on the same WiFi
- WiFi network must not have "AP Isolation" enabled
- Try disabling VPN if active
- Check that Bonjour/mDNS is not blocked by firewall

## Technical Details

### Error -72008 Means:
- Missing local network entitlements in sandbox
- User denied local network permission
- Bonjour service name mismatch in Info.plist
- Firewall blocking Bonjour/mDNS

### Required for MultipeerConnectivity:
- `com.apple.security.network.client` - To connect to peers
- `com.apple.security.network.server` - To accept connections
- `NSBonjourServices` - Must match service type exactly
- `NSLocalNetworkUsageDescription` - User-facing permission text

### Service Name Format:
Your code uses: `"beam-mesh"`
Info.plist needs: `"_beam-mesh._tcp"` and `"_beam-mesh._udp"`

The underscore prefix and protocol suffix are required by Bonjour specification.
