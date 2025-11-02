# Camera Permissions Fix

## Issue
Camera access showing "Camera Access Required" even though permission is granted in System Preferences.

## What I Fixed

### 1. Added Proper Authorization Check
The QR scanner now:
- **Checks authorization status** before accessing camera
- **Requests permission** if not yet determined
- **Shows clear error** if denied
- **Provides buttons** to open System Preferences and retry

### 2. Reset Permissions
Ran: `tccutil reset Camera getbeam.nl.Beam` to clear any cached permission state

### 3. Added Helper Buttons
- **"Open System Preferences"** - Opens directly to Camera settings
- **"Try Again"** - Re-initializes the camera after granting permission

## Testing Steps

**1. Rebuild the app:**
   - In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Run (Cmd+R)

**2. When app launches:**
   - Go to "Scan QR Code"
   - You should see a permission request dialog
   - Click **"OK"** or **"Allow"**

**3. If permission was already granted but camera still doesn't work:**
   - Click **"Try Again"** button
   - This will re-initialize the camera session

**4. If you still see an error:**
   - Click **"Open System Preferences"**
   - Make sure **Beam** is checked under Camera
   - Go back to Beam app
   - Click **"Try Again"**

## Expected Console Output

After granting permission:
```
✅ Camera authorized
🎥 Starting QR scanner...
📷 Camera session started
```

If denied:
```
⚠️ Camera access denied
Error: Please enable in System Preferences > Privacy & Security > Camera
```

## Alternative: Manual Permission Grant

If the automatic request doesn't appear:

1. **Quit Beam** completely
2. **Open Terminal** and run:
   ```bash
   tccutil reset Camera getbeam.nl.Beam
   ```
3. **Restart Beam** from Xcode
4. **Go to Scan QR Code** - should now show permission dialog

## Troubleshooting

### Camera permission granted but still shows error:

**Option 1: Check Info.plist**
```bash
/usr/libexec/PlistBuddy -c "Print :NSCameraUsageDescription" ~/Library/Developer/Xcode/DerivedData/Beam-*/Build/Products/Debug/Beam.app/Contents/Info.plist
```

Should show: `"Beam uses the camera to scan QR codes for adding contacts."`

**Option 2: Check TCC database**
```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT service, client, auth_value FROM access WHERE service='kTCCServiceCamera' AND client LIKE '%Beam%';"
```

Should show: `kTCCServiceCamera|getbeam.nl.Beam|2` (2 = allowed)

**Option 3: Full reset**
```bash
# Kill app
killall Beam

# Reset permissions
tccutil reset Camera getbeam.nl.Beam

# Delete database (fresh start)
rm ~/Library/Containers/getbeam.nl.Beam/Data/Documents/Database/beam.db

# Rebuild in Xcode
```

---

**Next:** Once camera is working, scan QR codes to exchange Beam IDs between macOS and iPhone!
