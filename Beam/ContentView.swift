//
//  ContentView.swift
//  Beam
//
//  Created by Yas o on 30/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingContactsTab = true
    
    var body: some View {
        #if os(macOS)
        MacOSMainView()
        #else
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Label("Chats", systemImage: "message.fill")
                }
                .tag(0)
            
            ContactsView(isPresented: $showingContactsTab)
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.beamBlue)
        #endif
    }
}

// macOS-specific main view with sidebar
#if os(macOS)
struct MacOSMainView: View {
    @StateObject private var database = DatabaseService.shared
    @StateObject private var messageService = MessageService.shared
    @StateObject private var meshService = MeshService.shared
    @State private var selectedContact: Contact?
    @State private var showingContactInfo = false
    @State private var contacts: [Contact] = []
    @State private var searchText = ""
    @State private var showingQRScanner = false
    @State private var showingMyQR = false
    @State private var showingSettings = false
    @State private var showingContacts = false
    
    var filteredContacts: [Contact] {
        // Only show contacts that have messages
        let contactsWithChats = contacts.filter { contact in
            if let msgs = messageService.messages[contact.id], !msgs.isEmpty {
                return true
            }
            return false
        }
        
        if searchText.isEmpty {
            return contactsWithChats
        } else {
            return contactsWithChats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar with chat list
            VStack(spacing: 0) {
                // Header with title and buttons
                HStack {
                    // App name with peer count
                    HStack(spacing: 8) {
                        Text("Beam")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Peer count badge
                        if meshService.connectedPeers.filter({ peer in
                            let contactIds = Set(database.getContacts().map { $0.id })
                            return contactIds.contains(peer.displayName)
                        }).count > 0 {
                            let count = meshService.connectedPeers.filter({ peer in
                                let contactIds = Set(database.getContacts().map { $0.id })
                                return contactIds.contains(peer.displayName)
                            }).count
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 6, height: 6)
                                Text("0")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    Button(action: { showingMyQR = true }) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("My QR Code")
                    
                    Button(action: { showingQRScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Scan QR Code")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                // Chat List
                List(filteredContacts, id: \.id, selection: $selectedContact) { contact in
                    MacOSChatRowView(contact: contact, messageService: messageService)
                        .tag(contact)
                }
                .listStyle(SidebarListStyle())
                
                Divider()
                
                // Bottom toolbar
                HStack {
                    Button(action: { showingContacts = true }) {
                        Label("Contacts", systemImage: "person.2.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(minWidth: 280, idealWidth: 320)
            
            // Main content area
            if let contact = selectedContact {
                if showingContactInfo {
                    ContactInfoView(contact: contact)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Button(action: { showingContactInfo = false }) {
                                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14))
                                        Text("Back")
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                } else {
                    MacOSChatView(contact: contact, showingContactInfo: $showingContactInfo)
                }
            } else {
                VStack {
                    Image(systemName: "message.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select a chat to start messaging")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .sheet(isPresented: $showingQRScanner) {
            if #available(macOS 13.0, *) {
                ScanQRCodeView(isPresented: $showingQRScanner)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("QR Scanner requires macOS 13.0 or newer")
                        .font(.headline)
                    Text("Your current macOS version doesn't support camera-based QR scanning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("OK") {
                        showingQRScanner = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
                .frame(width: 420, height: 300)
            }
        }
        .sheet(isPresented: $showingMyQR) {
            MyQRCodeView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .frame(minWidth: 600, minHeight: 700)
        }
        .sheet(isPresented: $showingContacts) {
            ContactsView(onContactSelected: { contact in
                // Ensure the contact has messages array
                if messageService.messages[contact.id] == nil {
                    messageService.messages[contact.id] = []
                }
                
                // Select the contact
                selectedContact = contact
                showingContacts = false
                showingContactInfo = false
                
                // Reload contacts to update the sidebar
                contacts = database.getContacts()
            }, isPresented: $showingContacts)
                .frame(minWidth: 500, minHeight: 750)
        }
        .overlay(
            // Contact request notifications
            VStack {
                ForEach(meshService.pendingContactRequests, id: \.beamId) { request in
                    ContactRequestNotification(
                        contactCard: request,
                        onAccept: {
                            meshService.acceptContactRequest(request)
                            contacts = database.getContacts()
                        },
                        onReject: {
                            meshService.rejectContactRequest(request)
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .top)
            , alignment: .top
        )
        .onAppear {
            contacts = database.getContacts()
            messageService.loadMessages()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageReceived"))) { _ in
            messageService.loadMessages()
            contacts = database.getContacts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeselectContact"))) { _ in
            // Deselect contact when chat is deleted
            selectedContact = nil
            showingContactInfo = false
        }
        .onChange(of: selectedContact) { contact in
            // Mark messages as read when opening a chat on macOS
            if let contact = contact {
                messageService.loadAndMarkAsRead(contactId: contact.id)
            }
        }
    }
}

// Contact Request Notification View
struct ContactRequestNotification: View {
    let contactCard: ContactCard
    let onAccept: () -> Void
    let onReject: () -> Void
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contact Request")
                        .font(.headline)
                    Text("\(contactCard.displayName) wants to connect")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Accept button
                Button("Accept") {
                    withAnimation {
                        onAccept()
                        isVisible = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                // Reject button
                Button("Reject") {
                    withAnimation {
                        onReject()
                        isVisible = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }
}

// macOS-specific chat row
struct MacOSChatRowView: View {
    let contact: Contact
    @ObservedObject var messageService: MessageService
    @ObservedObject private var database = DatabaseService.shared
    @State private var currentUnreadCount = 0
    
    private var lastMessage: Message? {
        messageService.messages[contact.id]?.last
    }
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: contact.name, size: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    if let lastMessage = lastMessage {
                        Text(lastMessage.timestamp.timeAgo())
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if let lastMessage = lastMessage {
                        if lastMessage.isFromMe {
                            Image(systemName: lastMessage.status == .read ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Text(lastMessage.content)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    if currentUnreadCount > 0 {
                        Text("\(currentUnreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.beamBlue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            updateUnreadCount()
        }
        .onChange(of: messageService.messages[contact.id]?.count) { _ in
            updateUnreadCount()
        }
    }
    
    private func updateUnreadCount() {
        let count = database.getUnreadCount(for: contact.id)
        currentUnreadCount = count
    }
}

// macOS-specific chat view
struct MacOSChatView: View {
    let contact: Contact
    @Binding var showingContactInfo: Bool
    @StateObject private var messageService = MessageService.shared
    @StateObject private var database = DatabaseService.shared
    @State private var messageText = ""
    @State private var showingEmojiPicker = false
    @State private var messages: [Message] = []
    
    // Common emoji list
    let emojis = ["😀", "😂", "🥰", "😎", "🤔", "👍", "👎", "❤️", "🎉", "🔥", "✅", "❌", "💯", "🙌", "🤝", "💪", "👏", "🙏", "🌟", "⭐️"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                AvatarView(name: contact.name, size: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let lastSeen = contact.lastSeen {
                        Text("Last seen \(lastSeen.timeAgo())")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingContactInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Contact Info")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Emoji picker
            if showingEmojiPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: {
                                messageText += emoji
                            }) {
                                Text(emoji)
                                    .font(.system(size: 28))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .frame(height: 50)
                
                Divider()
            }
            
            // Input Bar
            HStack(spacing: 12) {
                Button(action: { showingEmojiPicker.toggle() }) {
                    Image(systemName: showingEmojiPicker ? "keyboard" : "face.smiling")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(18)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(messageText.isEmpty ? .secondary : .beamBlue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            loadMessages()
        }
        .onChange(of: contact.id) { _ in
            loadMessages()
        }
        .onChange(of: messageService.messages[contact.id]?.count) { _ in
            loadMessages()
            // Mark as read since the chat is currently open
            messageService.markAsRead(contactId: contact.id)
        }
    }
    
    private func loadMessages() {
        // Reload from database to ensure we have latest data - only for this contact
        messageService.loadMessages(for: contact.id)
        messages = messageService.messages[contact.id] ?? []
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        messageService.sendMessage(content: messageText, to: contact.id)
        messageText = ""
        loadMessages()
    }
}
#endif

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
