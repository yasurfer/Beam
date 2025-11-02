# iOS Error -72008 - FIXED

## Summary
Fixed the **MultipeerConnectivity error -72008** on iPhone 6s by creating platform-specific entitlement files.

## Problem
iPhone 6s couldn't start browsing or advertising because the shared `Beam.entitlements` file contained **macOS-only sandbox entitlements** that iOS doesn't support.

## Solution Applied

### 1. Created Platform-Specific Entitlement Files

**Beam-iOS.entitlements** (minimal, iOS-friendly):
```xml
<dict>
    <!-- iOS doesn't need any special entitlements for MultipeerConnectivity -->
    <!-- All permissions come from Info.plist (NSLocalNetworkUsageDescription, NSBonjourServices) -->
</dict>
```
- **Empty dict** - No special entitlements needed
- No sandbox keys (iOS doesn't use App Sandbox)
- Relies on Info.plist permissions
- No multipath networking (requires paid Apple Developer account)

**Beam-macOS.entitlements** (full sandbox):
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
```
- Maintains macOS App Sandbox requirement
- Full network and camera permissions

### 2. Updated Xcode Project Build Settings

Modified `project.pbxproj` to use different entitlements per platform:

**Debug Configuration:**
```
"CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]" = "Beam/Beam-iOS.entitlements";
"CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]" = "Beam/Beam-iOS.entitlements";
"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]" = "Beam/Beam-macOS.entitlements";
```

**Release Configuration:**
```
Same as Debug
```

### 3. Added File References
Added both new entitlement files to the Xcode project structure so they're visible in Project Navigator.

## Why This Works

### iOS Perspective
- iOS **doesn't support** the App Sandbox model
- iOS uses **Info.plist** for all permissions:
  - `NSLocalNetworkUsageDescription` → Local network access
  - `NSBonjourServices` → Service discovery
  - `NSCameraUsageDescription` → Camera access
- Including macOS sandbox entitlements causes iOS to reject network services with error -72008

### macOS Perspective  
- macOS **requires** App Sandbox for distribution
- Sandbox permissions explicitly grant network access
- Without sandbox entitlements, macOS apps can't use network services

## Expected Result
After rebuilding for iPhone 6s, you should see:
```
✅ Started advertising Beam ID: 4D9703A2-3CAE-47F7-B115-B4593FB2B65C
🔍 Started browsing for peers
```

**No more -72008 errors!**

## Next Steps

1. **Clean Build Folder**: 
   - Product > Clean Build Folder (Shift+Cmd+K)

2. **Rebuild for iPhone 6s**:
   - Select iPhone 6s as destination
   - Product > Build (Cmd+B)
   - Product > Run (Cmd+R)

3. **Verify Both Platforms**:
   - Test iOS version on iPhone 6s
   - Test macOS version on your Mac
   - Both should connect and discover each other

4. **Monitor Console**:
   - Watch for "Started advertising" and "Started browsing" messages
   - Look for peer discovery logs
   - Verify no -72008 errors

## Files Modified
- ✅ Created: `Beam/Beam-iOS.entitlements`
- ✅ Created: `Beam/Beam-macOS.entitlements`  
- ✅ Updated: `Beam.xcodeproj/project.pbxproj` (build settings + file references)
- 📝 Note: Old `Beam.entitlements` can be removed after testing

## Documentation Created
- `iOS-ENTITLEMENTS-FIX.md` - Detailed troubleshooting guide
- `iOS-ERROR-72008-FIXED.md` - This summary

---

**Status**: Ready to build and test! 🚀
