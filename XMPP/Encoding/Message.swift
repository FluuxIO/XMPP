//
//  Message.swift
//  XMPP
//
//  Created by Mickaël Rémond on 21/10/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

// TODO: Generate message id and threadID
public class Message: Stanza {
    public enum XMPPType: String {
        case chat
    }
    
    public init(type t: XMPPType, to j: JID, body text: String? = nil) {
        super.init(localname: "message")
        attrs["type"] = t.rawValue
        // TODO: Only send to bare JID if sending to our domain. Other host could need a full JID (like for example chatrooms)
        attrs["to"] = j.full()
        if let body = text {
            nodes.append(Node(localname: "body", content: body))
        }
    }
    
    // TODO: XML escape the message ? Maybe better to just provide a separate util function
    // for the lib user, to avoid double escaping.
    public func addBody(_ text: String) {
        let body = Node(localname: "body", content: text)
        nodes.append(body)
    }
}
