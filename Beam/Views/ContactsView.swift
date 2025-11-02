//
//  ContactsView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

struct ContactsView: View {
    var onContactSelected: ((Contact) -> Void)? = nil
    @Binding var isPresented: Bool
    
    @StateObject private var database = DatabaseService.shared
    @StateObject private var messageService = MessageService.shared
    @State private var contacts: [Contact] = []
    @State private var searchText = ""
    @State private var showingQRScanner = false
    @State private var selectedContact: Contact?
    @State private var navigateToChat = false
    @State private var contactToDelete: Contact?
    @State private var showingDeleteConfirmation = false
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        #if os(macOS)
        // macOS version without NavigationView split
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Contacts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingQRScanner = true }) {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.beamBlue)
                }
                .buttonStyle(.plain)
                .help("Scan QR Code")
                
                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search contacts", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Contacts List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredContacts) { contact in
                        ContactRow(contact: contact)
                            .onTapGesture {
                                selectContactAndStartChat(contact)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    contactToDelete = contact
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Contact", systemImage: "trash")
                                }
                            }
                        
                        Divider()
                            .padding(.leading, 74)
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .background(
            NavigationLink(
                destination: selectedContact.map { ChatView(contact: $0) },
                isActive: $navigateToChat
            ) {
                EmptyView()
            }
            .hidden()
        )
        .sheet(isPresented: $showingQRScanner) {
            if #available(macOS 13.0, iOS 13.0, *) {
                ScanQRCodeView(isPresented: $showingQRScanner)
            } else {
                Text("QR Scanner requires macOS 13.0 or iOS 13.0")
                    .padding()
            }
        }
        .onAppear {
            loadContacts()
        }
        .alert("Delete Contact", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let contact = contactToDelete {
                    deleteContact(contact)
                }
            }
        } message: {
            if let contact = contactToDelete {
                Text("Are you sure you want to delete \(contact.name)? This will also delete all messages with this contact.")
            }
        }
        #else
        // iOS version with NavigationView
        NavigationView {
            ZStack {
                Color.beamBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search contacts", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Contacts List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredContacts) { contact in
                                ContactRow(contact: contact)
                                    .onTapGesture {
                                        selectContactAndStartChat(contact)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            contactToDelete = contact
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                
                                Divider()
                                    .padding(.leading, 74)
                            }
                        }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: selectedContact.map { ChatView(contact: $0) },
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if onContactSelected != nil {
                        // Only show back button when presented as a sheet
                        Button(action: { 
                            isPresented = false
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Chats")
                                    .font(.body)
                            }
                            .foregroundColor(.beamBlue)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingQRScanner = true }) {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundColor(.beamBlue)
                    }
                }
            }
            .sheet(isPresented: $showingQRScanner) {
                if #available(macOS 13.0, iOS 13.0, *) {
                    ScanQRCodeView(isPresented: $showingQRScanner)
                } else {
                    Text("QR Scanner requires macOS 13.0 or iOS 13.0")
                        .padding()
                }
            }
            .onAppear {
                loadContacts()
            }
            .alert("Delete Contact", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let contact = contactToDelete {
                        deleteContact(contact)
                    }
                }
            } message: {
                if let contact = contactToDelete {
                    Text("Are you sure you want to delete \(contact.name)? This will also delete all messages with this contact.")
                }
            }
        }
        #endif
    }
    
    private func loadContacts() {
        contacts = database.getContacts()
    }
    
    private func deleteContact(_ contact: Contact) {
        // Delete from database
        database.deleteContact(contact.id)
        database.deleteAllMessages(for: contact.id)
        
        // Remove from messages service
        messageService.messages.removeValue(forKey: contact.id)
        
        // Reload contacts
        loadContacts()
        
        // Clear the contact to delete
        contactToDelete = nil
    }
    
    private func selectContactAndStartChat(_ contact: Contact) {
        // Ensure the contact has a message list (creates empty list if needed)
        if messageService.messages[contact.id] == nil {
            messageService.messages[contact.id] = []
        }
        
        // If we're on macOS and have a callback, use it
        if let onContactSelected = onContactSelected {
            onContactSelected(contact)
        } else {
            // Otherwise use NavigationLink (for iOS)
            selectedContact = contact
            navigateToChat = true
            
            // Close the contacts modal after a brief delay to allow navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: contact.name, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(contact.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        #if os(macOS)
        .background(Color.clear)
        #else
        .background(Color.white)
        #endif
    }
}
