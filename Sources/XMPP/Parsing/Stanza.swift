//
//  Stanza.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-19.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

import Foundation

// We use Stanza for the type of the root stanza node.
public typealias Stanza = Node

// Node is a recursive structure that represent both a stanza (the root) and the XML subelements.
public class Node {
    public let prefix: String?
    public let localname: String
    public let namespaces: [String]
    public var attrs: [String: String] = [:]
    public var nodes: [Node] = []
    public var content: String? = ""
    weak var parentNode: Node?
    
    init(prefix: String? = nil, localname: String, namespaces: [String] = [],
         attrs: [String: String] = [:], content c: String? = nil) {
        self.prefix = prefix
        self.localname = localname
        self.namespaces = namespaces
        self.attrs = attrs
        content = c
    }
    
    // SetChild replace existing node with same prefix:localname or adds it to children
    // list if it does not exist.
    public func setChild(node newNode: Node) {
        var found = false
        var existing = 0
        for (i, node) in nodes.enumerated() {
            if node.prefix == newNode.prefix && node.localname == newNode.localname {
                found = true
                existing = i
                break
            }
        }
        
        if found == true {
            nodes[existing] = newNode
        } else {
            nodes.append(newNode)
        }
    }
    
    public func getChild(node n: Node) -> Node? {
        var found = false
        var existing = 0
        for (i, node) in nodes.enumerated() {
            if node.prefix == n.prefix && node.localname == n.localname {
                found = true
                existing = i
                break
            }
        }
        
        if found == true {
            return nodes[existing]
        }
        return nil
    }
    
    public func deleteChild(prefix: String? = nil, localname: String) {
        var found = false
        var existing = 0
        for (i, node) in nodes.enumerated() {
            if node.prefix == prefix && node.localname == localname {
                found = true
                existing = i
                break
            }
        }
        
        if found == true {
            nodes.remove(at: existing)
        }
    }
    
    public func deleteAttr(name: String) {
        attrs.removeValue(forKey: "name")
    }
}

// TODO: Should probably be pretty printed XML.
// Pretty print requires to add support for level in XMPP formatter.
extension Node: CustomStringConvertible {
    public var description: String {
        var n: String = ""
        for node in nodes {
            n += "\(node)"
        }
        return "\(pfx(prefix))\(localname) \(attrs) \(namespaces) (\(content ?? ""))\n\(n)"
    }
    
    private func pfx(_ prefix: String?) -> String {
        if let p = prefix {
            return p + ":"
        } else { return "" }
    }
}
