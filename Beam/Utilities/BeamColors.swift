//
//  BeamColors.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

extension Color {
    static let beamBlue = Color(red: 43/255, green: 111/255, blue: 255/255) // #2B6FFF
    static let beamSuccess = Color(red: 0, green: 200/255, blue: 83/255) // #00C853
    static let beamBackground = Color(red: 248/255, green: 249/255, blue: 251/255) // #F8F9FB
    static let beamMessageSent = LinearGradient(
        colors: [Color.beamBlue, Color.beamBlue.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
