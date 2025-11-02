//
//  AvatarView.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    
    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    private var backgroundColor: Color {
        let hash = name.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red]
        return colors[abs(hash) % colors.count]
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.2))
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(backgroundColor)
        }
        .frame(width: size, height: size)
    }
}
