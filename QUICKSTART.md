# Beam - Quick Start Guide

## 🚀 First Time Setup

### 1. Open the Project
```bash
cd /path/to/Beam
open Beam.xcodeproj
```

### 2. Build Configuration
- Select target device: iPhone or iPad simulator
- Ensure deployment target is iOS 15.0+
- Build scheme: Beam

### 3. Run the App
- Press ⌘R or click the Play button
- First launch will:
  - Create SQLite database in Documents/Database/
  - Generate sample contacts (Alice, Bob, Carol)
  - Generate sample messages
  - Create your user profile with unique Beam ID

## 📱 Using the App

### Navigate Between Tabs
- **Chats**: View all conversations
- **Contacts**: View all saved contacts  
- **Settings**: Configure your profile

### Start a Conversation
1. Go to **Chats** tab
2. Tap on any contact (Alice, Bob, or Carol)
3. Type a message in the input bar
4. Tap the send arrow
5. Watch the message status update:
   - ✓ = sent
   - ✓✓ = delivered
   - ✓✓ (blue) = read

### View Your QR Code
1. Go to **Settings** tab
2. Tap "Show My QR Code"
3. Your Beam ID is displayed as a QR code
4. Tap "Copy Beam ID" to copy to clipboard

### Add a Contact (Simulation)
1. Go to **Chats** tab
2. Tap the **+** button
3. Choose "Scan QR Code" (shows camera placeholder)
4. Or choose "Show My QR" to display yours

### Check Connection Status
- Look for the colored dot in the top-right corner:
  - 🟢 Green = Connected to peers
  - 🟠 Orange = DHT fallback mode
  - 🔴 Red = Offline
- Tap the dot to see details

## 🗂️ Sample Data Included

### Contacts
| Name  | Beam ID          | Status              |
|-------|------------------|---------------------|
| Alice | beam_alice_123   | 2 messages          |
| Bob   | beam_bob_456     | 2 messages          |
| Carol | beam_carol_789   | 1 unread message    |

### Your Profile
- Beam ID: Auto-generated (e.g., `beam_user_a1b2c3d4`)
- Display Name: "Me" (editable in Settings)
- Public/Private keys: Auto-generated

## 🔧 Settings Options

### Profile Section
- **Avatar**: Shows initials (tap to change in future)
- **Display Name**: Tap to edit
- **Beam ID**: Your unique identifier (tap to copy)

### Security Settings
- **Enable DHT Relay**: Toggle DHT fallback network
- **Auto-delete messages**: 
  - Enable/disable auto-deletion
  - Choose period: 7, 30, or 90 days

## 🎨 UI Features

### Chat List
- **Search**: Find conversations quickly
- **Unread badges**: Blue dots show unread count
- **Last message preview**: See recent messages
- **Swipe to delete**: Swipe left on any chat

### Chat View
- **Message bubbles**: 
  - Blue = You sent
  - White = You received
- **Timestamps**: Shows time of each message
- **Delivery status**: Checkmarks indicate delivery
- **Encryption badge**: Tap to view security info

## 🔐 Security Info

Each conversation shows encryption details:
1. Tap the **info** icon in chat header
2. View:
   - Contact's Beam ID
   - Public key (truncated)
   - Encryption status
3. Option to verify via QR code

## 📊 Database Location

During development, find your database at:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/
  data/Containers/Data/Application/[APP_ID]/
  Documents/Database/beam.db
```

To inspect the database:
```bash
# Find the app's data directory
xcrun simctl get_app_container booted com.yourcompany.Beam data

# Navigate to database
cd [path]/Documents/Database/

# Open with sqlite3
sqlite3 beam.db

# Query contacts
SELECT name, id FROM contacts;

# Query messages
SELECT content, timestamp FROM messages ORDER BY timestamp;
```

## 🧪 Testing Features

### Test Message Sending
1. Open chat with Alice
2. Send a message: "Hello from Beam!"
3. Watch status change from sending → sent → delivered
4. Message saves to database automatically

### Test Connection Status
- Connection status changes every 5 seconds (simulated)
- Watch the dot color change in the header
- Number of peers varies between 0-10

### Test Search
1. Go to Chats or Contacts
2. Type in search bar
3. Results filter in real-time

## 🛠️ Troubleshooting

### Database not created?
- Check console logs for "Database opened at: [path]"
- Ensure app has write permissions

### No sample data?
- Delete and reinstall the app
- Database initializes on first launch

### UI not updating?
- Check that services are @StateObject
- Verify @Published properties are used
- Ensure views observe the correct services

### Camera not working (QR scanner)?
- QR scanning requires physical device
- Simulator shows placeholder UI only
- Add camera permissions to Info.plist

## 🎯 Next Steps

### Enhance the App
1. **Add real P2P networking**
   - Use MultipeerConnectivity framework
   - Implement actual message relay

2. **Implement camera QR scanning**
   - Add AVFoundation
   - Process QR code data
   - Parse Beam ID from scanned data

3. **Add media support**
   - Photos from library
   - Camera captures
   - Voice messages

4. **Implement notifications**
   - Local notifications for new messages
   - Background fetch for message sync

### Customize the Design
1. Edit `BeamColors.swift` for custom theme
2. Modify avatar colors in `AvatarView.swift`
3. Adjust bubble styles in `ChatView.swift`

## 📚 Learn More

- Check `README.md` for full feature list
- Read `ARCHITECTURE.md` for technical details
- Review service classes for implementation

## 💡 Tips

- **Keyboard shortcuts** (Simulator):
  - ⌘K = Toggle keyboard
  - ⌘⇧H = Home button
  - ⌘R = Rebuild and run

- **View hierarchy**:
  - Debug → View Debugging → Capture View Hierarchy

- **Database browser**:
  - Use [DB Browser for SQLite](https://sqlitebrowser.org/)
  - Open `beam.db` from Documents/Database/

---

**Ready to build decentralized messaging!** 🚀
