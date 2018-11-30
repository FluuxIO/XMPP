//
//  Parser.swift
//  XMPP
//
//  Created by Mickaël Rémond on 14/10/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Foundation

typealias dispatcher = (Stanza) -> Void

struct ParsingState {
    var level: Int = 0
    var stanza: Node?
    var parentNode: Node?
    var currentNode: Node?
    var content: String = ""
}

// XMPPParser is an asynchronous parser for XMPP. It parses full stanza into a node structure
// and dispatches the result through the StreamManagerDelegate
class Parser {

    // Communicate XMPP streamID and parsed Stanza back to the manager:
    weak var delegate: StreamManagerDelegate?

    // Sax Parsing
    private var parser: SAXParser?
    private var parsingState: ParsingState
    
    init(delegate smdelegate: StreamManagerDelegate) {
        delegate = smdelegate
        parsingState = ParsingState()
        parser = SAXParser(delegate: self)
    }
    
    func parse(bytes: [UInt8]) {
        // Do not feed keep-alive response to parser
        if parsingState.level == 0 && bytes == [13, 10, 13, 10] {
            // print("Received keep-alive response")
            return
        }
        
        // print("Parsing: \(data)")
        do {
            try parser?.pushData(bytes)
        } catch {
            print("Parsing error \(error)")
        }
    }
}

protocol StreamManagerDelegate: AnyObject {
    var streamID: String { get set }
    func processEvent(_ stanza: Stanza)
}

extension Parser: SAXDelegate {
    func startElementNs(localName: String, prefix: String?, uri _: String?, namespaces: [SAXDelegateNamespace],
                        attributes: [SAXDelegateAttribute]) {
        // ==========================================================
        // Stream open is a special tag for XMPP. Stanzas are child
        // of the root stream open.
        if prefix == "stream" && localName == "stream" {
            for a in attributes {
                if a.localName == "id" {
                    delegate?.streamID = a.value
                }
            }
            parsingState.level = 0
            return
        }
        
        // Extract attributes
        var attrs: [String: String] = [:]
        for a in attributes {
            attrs[a.localName] = a.value
        }
        
        // Extract namespaces
        var ns: [String] = []
        for n in namespaces {
            ns.append(n.uri)
        }
        let node = Stanza(prefix: prefix, localname: localName, namespaces: ns, attrs: attrs)
        
        if parsingState.stanza == nil { parsingState.stanza = node }
        
        // Setup reference to currentNode and parentNode to process at next level
        if let n = parsingState.currentNode {
            node.parentNode = parsingState.currentNode
            n.nodes.append(node)
        }
        parsingState.currentNode = node
        parsingState.level += 1
    }
    
    func characters(_ c: String) {
        // TODO: optimisation: do not accumulate content after tag close
        parsingState.content += c
    }
    
    func endElementNs(localName _: String, prefix _: String?, uri _: String?) {
        parsingState.level -= 1
        if let n = parsingState.currentNode {
            // Only accumulate content on leave nodes
            if n.nodes.count == 0 {
                n.content = parsingState.content
            }
            parsingState.content = ""
            parsingState.currentNode = n.parentNode
        }
        
        if parsingState.level == 0 {
            // Pass the stanza and reset the packetizer state
            if let s = parsingState.stanza {
                delegate?.processEvent(s)
            }
            parsingState.stanza = nil
            parsingState.currentNode = nil
        }
    }
}
