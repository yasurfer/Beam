//
//  ConnectionStatusView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI
import MultipeerConnectivity

struct ConnectionStatusView: View {
    @ObservedObject var meshService: MeshService
    @ObservedObject var database: DatabaseService
    @State private var showingDetails = false
    
    // Default initializer using shared instances (for iOS)
    init(meshService: MeshService = MeshService.shared,
         database: DatabaseService = DatabaseService.shared) {
        self.meshService = meshService
        self.database = database
    }
    
    // Filter nearby peers to only show known contacts
    private var knownNearbyPeers: [MCPeerID] {
        let contacts = database.getContacts()
        let contactIds = Set(contacts.map { $0.id })
        let filtered = meshService.nearbyPeers.filter { contactIds.contains($0.displayName) }
        
        return filtered
    }
    
    // Filter connected peers to only show known contacts
    private var knownConnectedPeers: [MCPeerID] {
        let contacts = database.getContacts()
        let contactIds = Set(contacts.map { $0.id })
        let filtered = meshService.connectedPeers.filter { contactIds.contains($0.displayName) }
        
        return filtered
    }
    
    var body: some View {
        Button(action: {
            showingDetails.toggle()
        }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                #if os(macOS)
                // Always show peer count on macOS
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if knownConnectedPeers.count > 0 {
                        Text("\(knownConnectedPeers.count) online")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else if knownNearbyPeers.count > 0 {
                        Text("\(knownNearbyPeers.count) nearby")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Text("No peers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                #else
                // iOS: show details only when tapped
                if showingDetails {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if knownConnectedPeers.count > 0 {
                            Text("\(knownConnectedPeers.count) online")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else if knownNearbyPeers.count > 0 {
                            Text("\(knownNearbyPeers.count) nearby")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                #endif
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        // Green if known contact peers are connected
        if knownConnectedPeers.count > 0 {
            return .green
        }
        // Orange if peers nearby but not connected
        if knownNearbyPeers.count > 0 {
            return .orange
        }
        // Red if offline
        return .gray
    }
    
    private var statusText: String {
        if knownConnectedPeers.count > 0 {
            return "Mesh (Connected)"
        } else if knownNearbyPeers.count > 0 {
            return "Mesh (Nearby)"
        }
        return "Offline"
    }
}
