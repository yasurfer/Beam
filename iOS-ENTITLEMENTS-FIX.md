# iOS Network Error -72008 Fix

## Problem
iPhone 6s shows error -72008 when trying to start MultipeerConnectivity browsing and advertising:
```
[MCNearbyServiceBrowser] NSNetServiceBrowser did not search with error dict [{
    NSNetServicesErrorCode = "-72008";
    NSNetServicesErrorDomain = 10;
}]
```

## Root Cause
The shared `Beam.entitlements` file contains **macOS-specific sandbox entitlements** that conflict with iOS:
- `com.apple.security.app-sandbox` - macOS only
- `com.apple.security.network.client` - macOS sandbox permission
- `com.apple.security.network.server` - macOS sandbox permission
- `com.apple.security.device.camera` - macOS sandbox permission

iOS doesn't use the App Sandbox model. It relies on **Info.plist** permissions instead.

## Solution
Create **separate entitlement files** for iOS and macOS:

### Files Created
1. **Beam-iOS.entitlements** - Minimal iOS entitlements
2. **Beam-macOS.entitlements** - Full macOS sandbox entitlements

### Steps to Configure in Xcode

#### 1. Add Entitlement Files to Project
1. Open Xcode project
2. In the Project Navigator, you should see the new files:
   - `Beam-iOS.entitlements`
   - `Beam-macOS.entitlements`
3. If they're not visible, drag them from Finder into the Beam folder in Xcode

#### 2. Configure Build Settings for iOS
1. Select the **Beam** project in Project Navigator
2. Select the **Beam** target
3. Click on **Build Settings** tab
4. Search for "code sign entitlements"
5. Find **Code Signing Entitlements** setting
6. Click on the value for "Debug" configuration
7. Click the **+** button to add platform-specific settings
8. For **iOS** platform: set value to `Beam/Beam-iOS.entitlements`
9. For **macOS** platform: set value to `Beam/Beam-macOS.entitlements`
10. Repeat for "Release" configuration

**Alternative Method (Faster):**
1. In Build Settings, filter to show only **iOS** configurations
2. Set Code Signing Entitlements to: `Beam/Beam-iOS.entitlements`
3. Filter to show only **macOS** configurations  
4. Set Code Signing Entitlements to: `Beam/Beam-macOS.entitlements`

#### 3. Verify Configuration
1. Select iOS target in scheme dropdown
2. Build Settings should show: `Beam/Beam-iOS.entitlements`
3. Select macOS target in scheme dropdown
4. Build Settings should show: `Beam/Beam-macOS.entitlements`

#### 4. Clean and Rebuild
```bash
# Clean build folder
Product > Clean Build Folder (Shift+Cmd+K)

# Rebuild for iOS
# Select iPhone 6s as destination
# Product > Build (Cmd+B)
```

### What Each Entitlement File Contains

**Beam-iOS.entitlements** (minimal):
```xml
<dict>
    <!-- iOS doesn't need any special entitlements for MultipeerConnectivity -->
    <!-- All permissions come from Info.plist (NSLocalNetworkUsageDescription, NSBonjourServices) -->
</dict>
```
- **Empty dict** - No entitlements needed for free Apple Developer accounts
- **No sandbox keys** - iOS doesn't need them
- Relies on Info.plist for all permissions (camera, local network, Bonjour)
- **Note**: Multipath networking requires paid Apple Developer Program membership

**Beam-macOS.entitlements** (sandbox required):
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.device.camera</key>
<true/>
```
- macOS **requires** App Sandbox for distribution
- Network client/server permissions for MultipeerConnectivity
- Camera permission for QR code scanning

## Why This Fixes Error -72008

iOS interprets the macOS sandbox entitlements as requesting **restricted capabilities** that don't exist on iOS. This causes the network services to fail initialization with error -72008.

By using iOS-specific entitlements (with no sandbox keys), the app correctly relies on Info.plist permissions which iOS already grants based on:
- `NSLocalNetworkUsageDescription` - For local network access
- `NSBonjourServices` - For service discovery (_beam-mesh._tcp/udp)
- `NSCameraUsageDescription` - For QR scanning

## Testing
After applying these changes and rebuilding for iPhone 6s, you should see:
```
✅ Started advertising Beam ID: [your-id]
🔍 Started browsing for peers
```

Without any -72008 errors.

## Original Beam.entitlements
The old shared `Beam.entitlements` file can be **deleted** after confirming both platforms work with their respective new files.
