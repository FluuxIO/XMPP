//
//  Auth.swift
//  XMPP
//
//  Created by Mickaël Rémond on 19/10/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Foundation

struct userCredentials {
    let username, password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    // Generate auth string for SASL PLAIN authentication
    func toPlain() -> String? {
        var raw: Data = Data()
        raw.append(0x00)
        let u: [UInt8] = Array(username.utf8)
        raw.append(contentsOf: u)
        raw.append(0x00)
        let p: [UInt8] = Array(password.utf8)
        raw.append(contentsOf: p)
        return String(data: raw.base64EncodedData(), encoding: .utf8)
    }
}
