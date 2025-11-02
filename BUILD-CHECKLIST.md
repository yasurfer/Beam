# 🔧 Build & Run Checklist

## Before Building

### 1. Xcode Project Configuration
- [ ] Open `Beam.xcodeproj` in Xcode 14+
- [ ] Select Beam target (not BeamTests or BeamUITests)
- [ ] Choose a simulator or device:
  - iPhone 14 Pro (recommended)
  - iPhone SE (3rd gen) - for iPhone 6s compatibility test
  - iPad Pro (any) - for iPad layout
  - iPad (10th gen) - for iPad 6 compatibility test

### 2. Build Settings Verification
- [ ] Deployment Target: iOS 15.0 ✅
- [ ] Swift Language Version: Swift 5 ✅
- [ ] Build Configuration: Debug ✅

### 3. File Structure Check
All these files should exist in your project:
```
Beam/
├── Models/
│   ├── Contact.swift ✅
│   ├── Message.swift ✅
│   ├── User.swift ✅
│   └── ConnectionStatus.swift ✅
├── Services/
│   ├── DatabaseService.swift ✅
│   ├── EncryptionService.swift ✅
│   ├── RelayService.swift ✅
│   ├── GossipService.swift ✅
│   └── MessageService.swift ✅
├── Views/
│   ├── ChatListView.swift ✅
│   ├── ChatView.swift ✅
│   ├── ContactsView.swift ✅
│   ├── MyQRCodeView.swift ✅
│   ├── ScanQRCodeView.swift ✅
│   └── SettingsView.swift ✅
├── Components/
│   ├── AvatarView.swift ✅
│   └── ConnectionStatusView.swift ✅
├── Utilities/
│   ├── BeamColors.swift ✅
│   └── DateExtensions.swift ✅
├── BeamApp.swift ✅
└── ContentView.swift ✅
```

## Building the Project

### Method 1: Xcode UI
1. Open Xcode
2. Press `⌘R` (Command + R)
3. Wait for build to complete
4. App launches in simulator

### Method 2: Command Line
```bash
cd /Users/darkis/Desktop/Working/Beam/Beam
xcodebuild -scheme Beam -destination 'platform=iOS Simulator,name=iPhone 14 Pro'
```

## Expected Build Process

### Phase 1: Compilation
```
✅ Compiling Models (4 files)
✅ Compiling Services (5 files)
✅ Compiling Views (7 files)
✅ Compiling Components (2 files)
✅ Compiling Utilities (2 files)
✅ Linking Beam
```

### Phase 2: Code Signing
```
✅ Signing Beam.app
✅ Installing to simulator
```

### Phase 3: Launch
```
✅ Launching Beam
✅ Initializing DatabaseService
✅ Creating beam.db
✅ Loading sample data
✅ Starting RelayService
✅ App ready!
```

## First Launch Checklist

When the app launches, you should see:

### Tab 1: Chats
- [ ] Tab bar at bottom with "Chats" selected
- [ ] Search bar at top
- [ ] 3 chat rows (Alice, Bob, Carol)
- [ ] Each row shows:
  - [ ] Colored avatar with initials
  - [ ] Contact name
  - [ ] Last message preview
  - [ ] Timestamp (e.g., "1h ago")
  - [ ] Unread badge on Carol's chat
- [ ] Connection status dot in top-right
- [ ] + button in top-right

### Tab 2: Contacts
- [ ] Search bar
- [ ] 3 contacts listed
- [ ] QR scanner button in top-right

### Tab 3: Settings
- [ ] User avatar at top
- [ ] Display name: "Me"
- [ ] Beam ID (starts with "beam_user_")
- [ ] "Show My QR Code" button
- [ ] DHT Relay toggle (enabled)
- [ ] Auto-delete toggle (disabled)
- [ ] Version number at bottom

## Testing Core Features

### Test 1: View Messages
1. Tap "Alice" in Chats tab
2. Should see:
   - [ ] Chat header with "Alice"
   - [ ] "Encrypted" badge or last seen
   - [ ] 2 messages (1 received, 1 sent)
   - [ ] Correct bubble colors
   - [ ] Timestamps
   - [ ] Delivery checkmarks

### Test 2: Send Message
1. In Alice's chat, tap input field
2. Type "Test message"
3. Tap send arrow
4. Should see:
   - [ ] Message appears immediately
   - [ ] Blue bubble (sent)
   - [ ] Status changes: ✓ → ✓✓
   - [ ] Timestamp shows current time

### Test 3: View QR Code
1. Go to Settings tab
2. Tap "Show My QR Code"
3. Should see:
   - [ ] Modal sheet opens
   - [ ] Large avatar
   - [ ] Display name
   - [ ] Beam ID
   - [ ] QR code image
   - [ ] "Copy Beam ID" button
   - [ ] "Share QR Code" button
   - [ ] "Done" button

### Test 4: Search
1. Go to Chats tab
2. Tap search bar
3. Type "ali"
4. Should see:
   - [ ] Only Alice's chat shown
   - [ ] Other chats filtered out
5. Clear search
6. Should see:
   - [ ] All 3 chats again

### Test 5: Settings Change
1. Go to Settings
2. Tap display name field
3. Change to "John Doe"
4. Tap elsewhere
5. Should see:
   - [ ] Name updates in avatar
   - [ ] Name saved (check by restarting app)

## Console Output to Look For

### Successful Launch
```
Database opened at: /Users/.../Documents/Database/beam.db
Table created successfully (3 times - users, contacts, messages)
User saved successfully
Contact saved successfully (3 times - Alice, Bob, Carol)
Message saved successfully (5 times)
```

### Message Sending
```
Sending message directly: [message-id]
Message saved successfully
```

## Common Issues & Fixes

### ❌ Build Failed: "No such module 'SQLite3'"
**Fix**: SQLite3 is built into iOS, no import needed
- Check that you're not importing a third-party SQLite library

### ❌ Database Not Created
**Fix**: Check simulator's file system
```bash
xcrun simctl get_app_container booted com.yourcompany.Beam data
cd [path]/Documents/Database/
ls -la  # Should see beam.db
```

### ❌ UI Not Showing
**Fix**: Check that all files are added to target
1. Select each .swift file in Xcode
2. Check "Target Membership" in File Inspector
3. Ensure "Beam" is checked

### ❌ Colors Not Right
**Fix**: Check BeamColors.swift imports
- Verify `import SwiftUI` is present
- Check hex color conversions (RGB/255)

### ❌ App Crashes on Launch
**Fix**: Check console for error
- Look for initialization errors
- Verify all @StateObject initializations
- Check database path permissions

## Performance Benchmarks

After successful build, the app should:
- [ ] Launch in < 2 seconds
- [ ] Display chat list in < 0.5 seconds
- [ ] Open chat view in < 0.3 seconds
- [ ] Send message with instant UI update
- [ ] Scroll smoothly through messages
- [ ] Search filter in real-time

## Database Verification

### Verify Sample Data
```bash
# Find database
xcrun simctl get_app_container booted com.yourcompany.Beam data

# Query database
cd [path]/Documents/Database/
sqlite3 beam.db

# Check contacts
SELECT COUNT(*) FROM contacts;  # Should return 3

# Check messages
SELECT COUNT(*) FROM messages;  # Should return 5

# Check user
SELECT display_name, beam_id FROM users;  # Should return 1 row
```

## Sign-Off Checklist

Before considering build successful:
- [ ] ✅ App launches without crashes
- [ ] ✅ All 3 tabs accessible
- [ ] ✅ Sample data visible
- [ ] ✅ Can send messages
- [ ] ✅ Can navigate between views
- [ ] ✅ QR code displays correctly
- [ ] ✅ Settings save changes
- [ ] ✅ Connection status updates
- [ ] ✅ No console errors
- [ ] ✅ Database created successfully

## Next Steps After Successful Build

1. **Explore the UI**
   - Navigate through all tabs
   - Open each chat
   - Try all buttons

2. **Test Features**
   - Send multiple messages
   - Change settings
   - Search for contacts

3. **Inspect Database**
   - View stored data
   - Check encryption fields
   - Verify timestamps

4. **Read Documentation**
   - README.md for features
   - ARCHITECTURE.md for structure
   - QUICKSTART.md for usage

5. **Customize**
   - Change colors in BeamColors.swift
   - Modify sample data in DatabaseService.swift
   - Add your own features

---

## 🎉 Success Criteria

✅ **The build is successful when:**
1. App launches without errors
2. All tabs are functional
3. Sample chats are visible
4. Messages can be sent
5. Database is created in Documents/Database/
6. QR codes display correctly
7. Settings are editable
8. UI matches the Beam Blue theme (#2B6FFF)

---

**Happy Building! 🚀**

If all checkboxes are checked, you have a fully functional Beam messaging app!
