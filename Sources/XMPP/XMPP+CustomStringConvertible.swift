//
//  XMPP+CustomStringConvertible.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-12-01.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

extension XMPP: CustomStringConvertible {
    public var description: String {
        return "Networking: \(conn)"
    }
}
