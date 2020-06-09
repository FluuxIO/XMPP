//
//  IQParser.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-19.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

import Foundation

extension IQ {
    // If the IQ is a bindResult, extract and return the JID.
    public static func bindResultJid(from node: Node) -> JID? {
        guard node.localname == "iq" else { return nil }
        guard node.attrs["type"] == "result" else { return nil }
        
        guard let bind = node.nodes.first(where: { $0.localname == "bind" && $0.namespaces.first == "urn:ietf:params:xml:ns:xmpp-bind" }) else { return nil }
        
        guard let j = bind.nodes.first(where: { $0.localname == "jid" }) else { return nil }

        if let data = j.content, let jid = JID(data) {
            return jid
        } else {
            return nil
        }
    }
}
