//
//  PresenceEncoder.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-31.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.
//

// TODO: Add support for generating default id on Node class (for nodes that do
// not have parents).
// TODO: Add support for handling xml:lang attribute on Node.
// TODO: We probably need to have Stanza and Nonza inherit from Node and have id, to, from, lang, etc only on stanzas. Presence should inherit from Stanza.
// TODO: subelement: error, delay, c, caps ?
// TODO: attribute: from. Probably To, From, id, lang should be in an extension of Stanza.
public class Presence: Stanza {
    public enum XMPPType: String {
        case none = ""
        case subscribe
        case subscribed
        case unavailable
        case unsubscribe
        case unsubscribed
        case error
    }
    
    public enum Show: String {
        case none = ""
        case away
        case chat
        case dnd
        case xa
    }
    
    public init(type t: XMPPType = .none, to jid: JID? = nil) {
        super.init(localname: "presence")
        attrs["to"] = jid?.full()
        if t != .none {
            attrs["type"] = t.rawValue
        }
    }
    
    var to: JID? {
        set {
            attrs["to"] = newValue?.full()
        }
        get {
            guard let t = attrs["to"] else { return nil }
            return JID(t)
        }
    }
    
    // TODO: type should be read-only, as consistent of subelements depends on the type.
    var type: XMPPType {
        set {
            guard newValue != .none else { return }
            attrs["type"] = newValue.rawValue
        }
        get {
            guard let rawType = attrs["type"] else { return .none }
            guard let t = XMPPType(rawValue: rawType) else { return .none }
            return t
        }
    }
    
    var show: Show {
        set {
            guard newValue != .none else { return }
            let node = Node(localname: "show", content: newValue.rawValue)
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "show")) else { return .none }
            guard let rawShow = n.content else { return .none }
            guard let s = Show(rawValue: rawShow) else { return .none }
            return s
        }
    }
    
    // TODO: Multiple instances of the <status/> element MAY be included, but only if each instance possesses an 'xml:lang' attribute with a distinct language value
    var status: String? {
        set {
            guard let s = newValue else {
                deleteChild(localname: "status")
                return
            }
            guard !s.isEmpty else {
                deleteChild(localname: "status")
                return
            }
            let node = Node(localname: "status", content: newValue)
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "status")) else { return nil }
            return n.content
        }
    }
    
    var priority: Int8 {
        set {
            guard newValue != 0 else {
                deleteChild(localname: "priority")
                return
            }
            let node = Node(localname: "priority", content: String(describing: newValue))
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "priority")) else { return 0 }
            guard let p = n.content else { return 0 }
            guard let prio = Int8(p) else { return 0 }
            return prio
        }
    }
}
