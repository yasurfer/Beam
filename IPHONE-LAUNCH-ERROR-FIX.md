# iPhone 6s Launch Error - "Executable path required"

## Error
```
An executable path on the remote device is required for launching.
Domain: IDEDebugSessionErrorDomain
Code: 3
```

## What This Means
The app **built successfully** but failed to **install or launch** on the iPhone 6s. Xcode can't find the executable on the device.

## Most Likely Causes

### 1. Info.plist Change Requires Clean Install
We just changed from auto-generated Info.plist to custom Info.plist. This can confuse Xcode's incremental builds.

### 2. Code Signing Issues
The new entitlements files might have code signing problems.

### 3. Device Trust Issues
The iPhone 6s might need to re-establish trust with your Mac.

## Fix Steps (Try in Order)

### Step 1: Delete App from iPhone
1. On iPhone 6s, **long press the Beam app icon**
2. **Delete** the app completely
3. **Restart the iPhone** (important!)

### Step 2: Clean Everything in Xcode
1. **Product > Clean Build Folder** (Shift+Cmd+K)
2. **Close Xcode completely**
3. **Delete DerivedData**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Beam-*
   ```
4. **Reopen Xcode**

### Step 3: Verify iPhone 6s Connection
1. **Window > Devices and Simulators** (Shift+Cmd+2)
2. Find your iPhone 6s in the list
3. Check if it shows **"Ready"** status
4. If it shows **"Preparing"** or **error**, disconnect/reconnect the device
5. You may need to **"Trust This Computer"** again on iPhone

### Step 4: Check Code Signing
1. Select **Beam** project in Project Navigator
2. Select **Beam** target
3. Go to **Signing & Capabilities** tab
4. Make sure:
   - ✅ **"Automatically manage signing"** is checked
   - ✅ **Team** is set to "Yassine Oussi (Personal Team)"
   - ✅ **Bundle Identifier** is `getbeam.nl.Beam`
   - ✅ **Signing Certificate** shows a valid certificate
   - ✅ No red error messages

### Step 5: Rebuild for iPhone 6s
1. Select **iPhone 6s** as destination (top bar)
2. **Product > Build** (Cmd+B)
3. Wait for build to complete successfully
4. **Product > Run** (Cmd+R)

### Step 6: Watch the Console
During install, watch for errors in the console:
- ✅ Good: "Installing..." → "Installed" → "Launching..."
- ❌ Bad: Code signing errors, provisioning profile errors

## Alternative: Install Manually

If automatic install fails, try manual install:

1. **Build the app**:
   - Product > Build (Cmd+B)

2. **Find the .app file**:
   - In Xcode: Product > Show Build Folder in Finder
   - Navigate to: `Products/Debug-iphoneos/Beam.app`

3. **Install via Devices window**:
   - Window > Devices and Simulators
   - Select iPhone 6s
   - Click **"+"** button under "Installed Apps"
   - Select the `Beam.app` file
   - Click **Open**

4. **Launch manually**:
   - Tap the Beam icon on iPhone 6s

## Common Issues

### "Untrusted Developer"
If iPhone shows "Untrusted Developer" when launching:
1. Settings > General > VPN & Device Management
2. Tap on your developer account
3. Tap **"Trust"**

### "Local Network" Permission
On first launch, iOS **MUST** show local network permission dialog:
- Tap **"Allow"** - without this, MultipeerConnectivity won't work

### Wireless Debugging Issues
The error shows `"device_isWireless" = 1`, meaning you're using wireless debugging. This can be flaky:

**Try wired connection:**
1. Disconnect iPhone from WiFi/wireless
2. Connect iPhone via **USB cable**
3. In Xcode Devices window, uncheck **"Connect via network"**
4. Try building again

## Verify Build Settings

Check that these are correct in project settings:

**General tab:**
- Bundle Identifier: `getbeam.nl.Beam`
- Deployment Target: iOS 15.0
- Supported Destinations: iPhone, iPad

**Build Settings tab:**
- Code Signing Identity: Apple Development
- Code Signing Style: Automatic
- Development Team: Yassine Oussi (Personal Team)
- Product Bundle Identifier: getbeam.nl.Beam
- **INFOPLIST_FILE**: `Beam/Info.plist` ← CRITICAL
- **GENERATE_INFOPLIST_FILE**: `NO` ← CRITICAL

## Nuclear Option: Create New Scheme

If nothing works, create a fresh scheme:

1. Product > Scheme > Manage Schemes
2. Click **"-"** to delete current "Beam" scheme
3. Click **"+"** to create new scheme
4. Name it "Beam"
5. Check **"Show"**
6. Click **Close**
7. Clean and rebuild

## Success Indicators

When it works, you'll see:
```
Build succeeded
Installing...
Installed
Launching Beam
✅ Started advertising Beam ID: [your-id]
🔍 Started browsing for peers
```

---

**Most Likely Solution**: Delete app from iPhone, clean DerivedData, restart iPhone, and rebuild. The Info.plist change requires a completely fresh install.
