//
//  JID.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-14.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

import Foundation

// Structure encoding an XMPP identifier.
// JID stands for Jabber ID. Jabber is the old name of the XMPP protocol.
// This is considered a client JID so we expect the local part to exist.
public struct JID {
    let local: String
    let server: String
    let resource: String?
    
    // ==================================
    // Create jid with its parts
    public init?(local: String, server: String, resource: String? = nil) {
        // TODO: check server and resource against empty string
        self.local = local
        self.server = server
        self.resource = resource
    }
    
    // ==================================
    // Parse JID from string
    public init?(_ s: String) {
        // Assign resource
        let parts = s.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2 {
            // error: resource part, when present, cannot be empty
            guard parts[1] != "" else { return nil }
            resource = String(parts[1])
        } else {
            resource = nil
        }
        
        // split local and server parts
        let bare = parts[0].split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        
        switch bare.count {
        case 1:
            // No "@" -> This is not a client JID
            // TODO: Need a  way to be able to create service JIDs
            return nil
        case 2:
            guard bare[0] != "" else { return nil }
            local = String(bare[0])
            guard bare[1] != "" else { return nil }
            server = String(bare[1])
        default:
            return nil
        }
    }
    
    public func bare() -> String {
        return "\(local)@\(server)"
    }
    
    public func full() -> String {
        guard let res = resource else { return bare() }
        return "\(local)@\(server)/\(res)"
    }
}

// MARK: JID extensions

extension JID: CustomStringConvertible {
    public var description: String {
        return full()
    }
}

extension JID {
    static var chars: [Character] = {
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".map({ $0 })
    }()
    
    static func makeResource() -> String {
        let length = 13
        var partial: [Character] = []
        
        for _ in 0 ..< length {
            let rand = Int.random(in: 0..<chars.count)
            partial.append(chars[rand])
        }
        
        return String(partial)
    }
}
