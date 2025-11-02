//
//  ChatView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

struct ChatView: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    @StateObject private var messageService = MessageService.shared
    @State private var messageText = ""
    @State private var showingEmojiPicker = false
    @State private var showingContactInfo = false
    
    init(contact: Contact) {
        self.contact = contact
    }
    
    // Directly access messages from messageService - @Published will handle updates
    private var messages: [Message] {
        return messageService.messages[contact.id] ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                .background(Color.beamBackground)
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Bar
            ChatInputBar(
                messageText: $messageText,
                showingEmojiPicker: $showingEmojiPicker,
                onSend: sendMessage
            )
        }
        .navigationTitle(contact.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(contact.name)
                        .font(.headline)
                    
                    if let lastSeen = contact.lastSeen {
                        Text("Last seen \(lastSeen.timeAgo())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Encrypted")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingContactInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.beamBlue)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button(action: { showingContactInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.beamBlue)
                }
            }
            #endif
        }
        .sheet(isPresented: $showingContactInfo) {
            ContactInfoView(contact: contact)
        }
        .onAppear {
            messageService.loadAndMarkAsRead(contactId: contact.id)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewMessageReceived"))) { notification in
            if let contactId = notification.userInfo?["contactId"] as? String, contactId == contact.id {
                loadMessages()
                // Mark as read after a short delay to avoid rapid updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.messageService.markAsRead(contactId: self.contact.id)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatDeleted"))) { notification in
            if let contactId = notification.userInfo?["contactId"] as? String,
               contactId == contact.id {
                // This chat was deleted
                // Wait for the sheet to fully dismiss before popping navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    dismiss()
                }
            }
        }
    }
    
    private func loadMessages() {
        // Reload from database for THIS contact only
        // The @Published messages property will automatically trigger view update
        messageService.loadMessages(for: contact.id)
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

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isSent {
                Spacer()
            }
            
            VStack(alignment: message.isSent ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isSent ? Color.beamBlue : Color.gray.opacity(0.15))
                    .foregroundColor(message.isSent ? .white : .primary)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 4) {
                    Text(message.timestamp.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if message.isSent {
                        Image(systemName: message.status == .read ? "checkmark.circle.fill" :
                                message.status == .delivered ? "checkmark.circle" :
                                message.status == .sent ? "checkmark" : "clock")
                            .font(.caption)
                            .foregroundColor(message.status == .read ? .beamSuccess : .secondary)
                    }
                }
            }
            .frame(maxWidth: 280, alignment: message.isSent ? .trailing : .leading)
            
            if !message.isSent {
                Spacer()
            }
        }
    }
}

struct ChatInputBar: View {
    @Binding var messageText: String
    @Binding var showingEmojiPicker: Bool
    let onSend: () -> Void
    
    // Common emoji list
    let emojis = ["😀", "😂", "🥰", "😎", "🤔", "👍", "👎", "❤️", "🎉", "🔥", "✅", "❌", "💯", "🙌", "🤝", "💪", "👏", "🙏", "🌟", "⭐️"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Emoji picker
            if showingEmojiPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: {
                                messageText += emoji
                            }) {
                                Text(emoji)
                                    .font(.system(size: 32))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.white)
                .frame(height: 60)
                
                Divider()
            }
            
            HStack(spacing: 12) {
                Button(action: { showingEmojiPicker.toggle() }) {
                    Image(systemName: showingEmojiPicker ? "keyboard" : "face.smiling")
                        .font(.title2)
                        .foregroundColor(.beamBlue)
                }
                
                HStack {
                    TextField("Message", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(20)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .gray : .beamBlue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}
