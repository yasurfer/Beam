# iPhone 6s Debugging Setup Guide

## Issue
iPhone 6s not appearing in Xcode for debugging.

## Current Configuration
- **Deployment Target**: iOS 15.0 ✅ (iPhone 6s supports up to iOS 15.8)
- **Supported Platforms**: iOS, macOS ✅

## Troubleshooting Steps

### 1. Check iPhone 6s Connection

**Physical Connection:**
1. Connect iPhone 6s to Mac via Lightning cable
2. Make sure you're using an **Apple-certified cable**
3. Try a different USB port if available
4. Check if iPhone appears in **Finder** sidebar

**Trust the Computer:**
1. When you connect, iPhone should show: **"Trust This Computer?"**
2. Tap **"Trust"** on iPhone
3. Enter iPhone passcode if prompted
4. On Mac, a popup may appear - click **"Trust"**

### 2. Enable Developer Mode (iOS 16+)

iPhone 6s runs iOS 15 maximum, so **skip this step** - Developer Mode is only for iOS 16+.

### 3. Check Xcode Device Window

1. In Xcode, go to **Window → Devices and Simulators** (Cmd+Shift+2)
2. Select **"Devices"** tab
3. Your iPhone 6s should appear in the left sidebar
4. Check the status:
   - ✅ **Green dot** = Ready for debugging
   - 🟡 **Yellow dot** = Preparing/syncing
   - 🔴 **Red dot** = Not ready (see error)
   - ⚠️ **Paired but locked** = Unlock your iPhone

### 4. If iPhone Shows "Preparing..."

This can take a few minutes the first time:
1. Keep iPhone **unlocked** and **connected**
2. Wait for Xcode to process symbols
3. Don't disconnect during this process

### 5. Check iPhone Settings

**On iPhone 6s:**
1. Go to **Settings → General → VPN & Device Management**
2. Look for your **Apple ID** or **Developer Profile**
3. Trust the certificate if needed

### 6. Reset Trust Settings

If device won't trust:

**On iPhone:**
1. Settings → General → Transfer or Reset iPhone
2. **Reset → Reset Location & Privacy**
3. Reconnect and trust again

**On Mac:**
```bash
# Remove trust cache
rm -rf ~/Library/Developer/Xcode/iOS\ Device\ Logs/
```

### 7. Restart Everything

Sometimes a simple restart fixes it:
1. **Disconnect iPhone**
2. **Quit Xcode** completely
3. **Restart iPhone** (Hold power + home button)
4. **Restart Mac** (if needed)
5. **Reconnect iPhone**
6. **Launch Xcode**

### 8. Check Device in Finder

**macOS Catalina+ (no iTunes):**
1. Open **Finder**
2. iPhone should appear in sidebar under "Locations"
3. Click iPhone and click **"Trust"** if needed
4. Make sure **"Show this iPhone when on WiFi"** is checked for wireless debugging

**macOS Mojave or earlier:**
1. Open **iTunes**
2. iPhone should appear
3. Click **"Trust This Computer"**

### 9. Verify Xcode Can See the Device

1. In Xcode, at the top toolbar, click the **device selector** (next to scheme)
2. Look under **"iOS Device"** section
3. Your iPhone 6s should appear with its name

If you see:
- **"iPhone (Unavailable)"** - Device is locked or not trusted
- **"iPhone (Preparing...)"** - Wait for processing
- **Nothing** - Device not detected

### 10. Check Cable and Port

iPhone 6s debugging issues are often cable-related:
- Try a **different Lightning cable**
- Try a **different USB port** (preferably USB 3.0)
- Avoid using **USB hubs**
- Try a **direct Mac port**

### 11. Update Software

Make sure everything is up to date:
- **Xcode**: Latest version
- **macOS**: Latest compatible version
- **iOS**: iPhone 6s should be on iOS 15.x (latest available)

### 12. Check System Report

To verify Mac sees the device:
1. Click **Apple Menu → About This Mac**
2. Click **"System Report"**
3. Under **Hardware → USB**, look for **"iPhone"**
4. Should show manufacturer: Apple Inc.

### 13. Wireless Debugging (Alternative)

If cable debugging won't work, try WiFi debugging:

**Requirements:**
- Both devices on same WiFi network
- iPhone connected via cable initially

**Setup:**
1. Connect iPhone via cable
2. Xcode → Window → Devices and Simulators
3. Select your iPhone
4. Check **"Connect via network"**
5. Wait for network icon to appear next to device
6. Disconnect cable
7. iPhone should stay available wirelessly

## Common Issues

### "iPhone is locked"
- Unlock iPhone and enter passcode
- Keep iPhone unlocked during debugging

### "iPhone is busy"
- Xcode is processing symbols
- Wait a few minutes

### "Could not locate device support files"
- Update Xcode to latest version
- Or manually download device support files

### "An error was encountered while enabling development on this device"
- Reset Location & Privacy on iPhone
- Reconnect and trust again

### "This device is no longer connected"
- Check cable connection
- Try different cable/port
- Restart both devices

## iOS 15 Support for iPhone 6s

iPhone 6s specifications:
- **Maximum iOS**: iOS 15.8
- **Release**: September 2015
- **Still supported**: Yes, for iOS 15

Your app targets iOS 15.0, which is **perfect** for iPhone 6s! ✅

## Final Checklist

Before debugging:
- [ ] iPhone connected via good cable
- [ ] iPhone unlocked
- [ ] Trusted computer on iPhone
- [ ] iPhone appears in Xcode device selector
- [ ] Green dot in Devices and Simulators window
- [ ] Correct scheme selected (Beam → iPhone)

## Running on iPhone 6s

Once device appears:
1. Select **"iPhone 6s"** or your device name in the scheme selector
2. Click **Run** (Cmd+R)
3. Xcode will build and install on device
4. First time: Enter iPhone passcode to allow installation
5. If "Untrusted Developer": Settings → General → VPN & Device Management → Trust

## Need Help?

If iPhone 6s still doesn't appear after trying all steps:
1. Check Console logs (in Xcode Console while device is connected)
2. Post the error message you see
3. Check if iPhone appears in Finder sidebar
4. Try connecting to a different Mac if available
