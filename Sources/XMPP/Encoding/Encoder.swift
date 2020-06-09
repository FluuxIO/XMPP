//
//  Encoder.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-21.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

// Encode a stanza into an XMPP packet.
public class Encoder {
    var encoded: String = ""
    
    public func encode(_ stanza: Stanza) throws -> String {
        encoded = ""
        
        try stanza.encode(to: self)
        return encoded
    }
    
    fileprivate func append(_ s: String) {
        encoded.append(s)
    }
}

extension Stanza {
    public func encode(to encoder: Encoder) throws {
        // Encode attributes
        var encodedAttrs = ""
        for attr in attrs.sorted(by: { $0 < $1 }) {
            encodedAttrs += " \(attr.key)='\(attr.value)'"
        }
        
        // Encode namespaces
        var encodedNS = ""
        for ns in namespaces {
            encodedNS += " xmlns='\(ns)'"
        }
        
        if nodes.isEmpty {
            if let cdata = content {
                encoder.append("<\(localname)\(encodedAttrs)\(encodedNS)>")
                encoder.append("\(cdata)")
            } else {
                encoder.append("<\(localname)\(encodedAttrs)\(encodedNS)/>")
                return
            }
        } else {
            encoder.append("<\(localname)\(encodedAttrs)\(encodedNS)>")
            for node in nodes {
                try node.encode(to: encoder)
            }
        }
        encoder.append("</\(localname)>")
    }
}
