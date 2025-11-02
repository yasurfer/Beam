//
//  User.swift
//  Beam
//
//  Created by Beam on 30/10/2025.
//

import Foundation

struct User: Codable {
    let beamId: String
    var displayName: String
    var publicKey: String
    var privateKey: String
    var avatar: String?
    var enableDHTRelay: Bool
    var autoDeleteDays: Int?
    
    init(beamId: String,
         displayName: String,
         publicKey: String,
         privateKey: String,
         avatar: String? = nil,
         enableDHTRelay: Bool = true,
         autoDeleteDays: Int? = nil) {
        self.beamId = beamId
        self.displayName = displayName
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.avatar = avatar
        self.enableDHTRelay = enableDHTRelay
        self.autoDeleteDays = autoDeleteDays
    }
}
