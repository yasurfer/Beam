//
//  ChatListView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var database = DatabaseService.shared
    @StateObject private var messageService = MessageService.shared
    @State private var contacts: [Contact] = []
    @State private var searchText = ""
    @State private var showingQRScanner = false
    @State private var showingMyQR = false
    
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
            ZStack {
                Color.beamBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Chat List
                    if filteredContacts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("No conversations yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Scan a QR code to add a contact")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredContacts) { contact in
                                    NavigationLink(destination: ChatView(contact: contact)) {
                                        ChatRowView(contact: contact)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .simultaneousGesture(TapGesture().onEnded {
                                        // Mark as read immediately when tapped on macOS
                                        #if os(macOS)
                                        messageService.markAsRead(contactId: contact.id)
                                        #endif
                                    })
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .onAppear {
                loadContacts()
                messageService.loadMessages()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageReceived"))) { notification in
                // Only reload the specific contact's messages instead of ALL contacts
                if let contactId = notification.userInfo?["contactId"] as? String {
                    messageService.loadMessages(for: contactId)
                }
                loadContacts()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatDeleted"))) { notification in
                loadContacts()
            }
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    ConnectionStatusView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingQRScanner = true }) {
                            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        }
                        Button(action: { showingMyQR = true }) {
                            Label("Show My QR", systemImage: "qrcode")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.beamBlue)
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    ConnectionStatusView()
                }
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button(action: { showingQRScanner = true }) {
                            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        }
                        Button(action: { showingMyQR = true }) {
                            Label("Show My QR", systemImage: "qrcode")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.beamBlue)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingQRScanner) {
                if #available(macOS 13.0, iOS 13.0, *) {
                    ScanQRCodeView(isPresented: $showingQRScanner)
                } else {
                    Text("QR Scanner requires macOS 13.0 or iOS 13.0")
                        .padding()
                }
            }
            .sheet(isPresented: $showingMyQR) {
                MyQRCodeView()
            }
            
            // Default view for iPad
            WelcomeView()
        }
    }
    
    private func loadContacts() {
        contacts = database.getContacts()
    }
}

struct ChatRowView: View {
    let contact: Contact
    @ObservedObject private var database = DatabaseService.shared
    @ObservedObject private var messageService = MessageService.shared
    @State private var refreshTrigger = false
    @State private var currentUnreadCount = 0
    
    var lastMessage: Message? {
        _ = refreshTrigger  // Depend on trigger to force refresh
        return database.getLastMessage(for: contact.id)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: contact.name, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if let last = lastMessage {
                    Text(last.content)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No messages yet")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let last = lastMessage {
                    Text(last.timestamp.timeAgo())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if currentUnreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.beamBlue)
                            .frame(width: 20, height: 20)
                        
                        Text("\(currentUnreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .contentShape(Rectangle())
        .onAppear {
            updateUnreadCount()
        }
        .onChange(of: messageService.messages[contact.id]?.count) { _ in
            refreshTrigger.toggle()
            updateUnreadCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MessagesMarkedAsRead"))) { notification in
            if let contactId = notification.userInfo?["contactId"] as? String, contactId == contact.id {
                updateUnreadCount()
            }
        }
        #if os(macOS)
        // On macOS, force refresh the unread count periodically while the view is visible
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            updateUnreadCount()
        }
        #endif
    }
    
    private func updateUnreadCount() {
        let count = database.getUnreadCount(for: contact.id)
        currentUnreadCount = count
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 80))
                .foregroundColor(.beamBlue)
            
            Text("Welcome to Beam")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select a conversation to start messaging")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.beamBackground.ignoresSafeArea())
    }
}
