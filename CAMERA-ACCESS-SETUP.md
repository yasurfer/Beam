# Camera Access Configuration for Beam

## What We've Set Up

### 1. Info.plist (Beam/Info.plist)
✅ **Added NSCameraUsageDescription:**
```xml
<key>NSCameraUsageDescription</key>
<string>Beam uses the camera to scan QR codes for adding contacts.</string>
```

### 2. Project Configuration (project.pbxproj)
✅ **Set to use custom Info.plist:**
```
GENERATE_INFOPLIST_FILE = NO;
INFOPLIST_FILE = Beam/Info.plist;
```

✅ **Removed conflicting INFOPLIST_KEY_* entries** that were overriding the custom Info.plist

### 3. macOS System Settings
✅ **Camera permission reset** with `tccutil reset Camera getbeam.nl.Beam`

### 4. QR Scanner Code (ScanQRCodeView.swift)
✅ **Added proper authorization checking:**
- Checks `AVCaptureDevice.authorizationStatus(for: .video)`
- Requests permission if not determined
- Shows clear error messages with helper buttons

## How to Test

**Step 1: Rebuild in Xcode**
```bash
Product → Clean Build Folder (Shift+Cmd+K)
Product → Run (Cmd+R)
```

**Step 2: Go to Scan QR Code**
- You should see a camera permission dialog
- Click "OK" or "Allow"

**Step 3: If Still Not Working**

Check if NSCameraUsageDescription made it into the built app:
```bash
# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Beam.app" -path "*/Debug/Beam.app" | grep -v iphonesimulator | head -1)

# Check Info.plist
plutil -p "$APP_PATH/Contents/Info.plist" | grep -i camera
```

Should output:
```
"NSCameraUsageDescription" => "Beam uses the camera to scan QR codes for adding contacts."
```

**Step 4: Verify macOS System Permissions**
```bash
# Open System Settings to Camera
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
```

Make sure "Beam" is checked in the list.

## Troubleshooting

### If camera still doesn't work:

**Option 1: Check TCC database**
```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, auth_value FROM access WHERE service='kTCCServiceCamera' AND client LIKE '%Beam%';"
```

Expected: `kTCCServiceCamera|getbeam.nl.Beam|2` (2 = allowed)

**Option 2: Full reset**
```bash
# Quit Beam
killall Beam

# Reset permissions
tccutil reset Camera getbeam.nl.Beam

# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData/Beam-*

# Rebuild in Xcode
```

**Option 3: Check console logs**
```bash
log stream --predicate 'process == "Beam"' --level debug | grep -i camera
```

Run this while opening the Scan QR Code view to see what's happening.

## Why This Should Work

1. ✅ **Info.plist has NSCameraUsageDescription** - Required by macOS
2. ✅ **Project uses custom Info.plist** - No auto-generation conflicts
3. ✅ **Authorization code checks permissions** - Proper AVFoundation usage
4. ✅ **System permissions reset** - Fresh permission state
5. ✅ **UI shows helpful errors** - User can see what's wrong

## What Happens When It Works

1. App launches → `ensureUserExists()` creates crypto keys
2. User goes to "Scan QR Code"
3. QR scanner checks camera authorization
4. macOS shows dialog: "Beam would like to access the camera"
5. User clicks "OK"
6. Camera activates, shows live preview
7. User scans QR code from other device
8. Contact added with correct Beam ID
9. P2P messaging works!

---

**If camera works but messages don't send**, the next steps are:
1. Both devices show each other with correct `beam_xxxxxxxxxxxxxxxx` format
2. Exchange fresh QR codes
3. Try sending a message
4. Check console for "📤 Attempting to send message" logs

