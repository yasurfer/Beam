//
//  DateExtensions.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            if day == 1 {
                return "Yesterday"
            } else if day < 7 {
                return "\(day) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: self)
            }
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
    
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
