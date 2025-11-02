//
//  BeamApp.swift
//  Beam
//
//  Created by Yas o on 30/10/2025.
//

import SwiftUI

@main
struct BeamApp: App {
    // Initialize services
    @StateObject private var database = DatabaseService.shared
    @StateObject private var messageService = MessageService.shared
    @StateObject private var meshService = MeshService.shared
    
    init() {
        // Ensure user exists with proper Beam ID
        DatabaseService.shared.ensureUserExists()
        
        // Start mesh networking on app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            MeshService.shared.start()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(database)
                .environmentObject(messageService)
                .environmentObject(meshService)
        }
    }
}
