//
//  XMPP+CustomStringConvertible.swift
//  XMPP-iOS
//
//  Created by Mickaël Rémond on 01/12/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

extension XMPP: CustomStringConvertible {
    public var description: String {
        return "Networking: \(conn)"
    }
}
