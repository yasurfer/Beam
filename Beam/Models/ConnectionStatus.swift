//
//  ConnectionStatus.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation

enum ConnectionStatus {
    case connected(peers: Int)
    case dhtFallback
    case offline
    
    var description: String {
        switch self {
        case .connected(let peers):
            return "\(peers) peers connected"
        case .dhtFallback:
            return "DHT fallback mode"
        case .offline:
            return "Offline"
        }
    }
}
