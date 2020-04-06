//
//  Parser.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-14.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.
//

import Foundation

#if os(Linux)
import FoundationXML
#endif

typealias dispatcher = (Stanza) -> Void

struct ParsingState {
    var level: Int = 0
    var stanza: Node?
    var parentNode: Node?
    var currentNode: Node?
    var content: String = ""
}


protocol StreamManagerDelegate: AnyObject {
    var streamID: String { get set }
    func processEvent(_ stanza: Stanza)
}

final class SAXDelegate: NSObject, XMLParserDelegate {
    private var parsingState: ParsingState
    // Communicate XMPP streamID and parsed Stanza back to the manager:
    var delegate: StreamManagerDelegate?

    init(delegate: StreamManagerDelegate) {
        parsingState = ParsingState()
        super.init()
        self.delegate = delegate
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        print("Delegate start")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("Delegate end")
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print("Did start element: \(elementName) \(namespaceURI ?? "") \(qName ?? "") \(attributeDict)")
        // ==========================================================
        // Stream open is a special tag for XMPP. Stanzas are child
        // of the root stream open.
        if elementName == "stream:stream" {
            for (k, v) in attributeDict {
                if k == "id" {
                    delegate?.streamID = v
                }
            }
            parsingState.level = 0
            return
        }
        
        // Extract namespaces
        var ns: [String] = []
        // Attributes without namespaces
        var attrs: [String: String] = [:]
        for (k, v) in attributeDict {
            if k == "xmlns" {
                ns.append(v)
            } else {
                attrs[k] = v
            }
        }
        if let namespace = namespaceURI {
             ns.append(namespace)
        }
        
        let eltParts = elementName.split(separator: ":", maxSplits: 2)
        var prefix = ""
        var localName = ""
        if eltParts.count == 2 {
            prefix = String(eltParts[0])
            localName = String(eltParts[1])
        } else {
            localName = String(eltParts[0])
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
        
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        print("CData: \(CDATABlock)")
        if let str = String(data: CDATABlock, encoding: .utf8) {
            parsingState.content += str
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print("Characters: \(string)")
        parsingState.content += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("Endelement: \(elementName) \(namespaceURI) \(qName)")
        
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

class Parser: InputStream {
    // Communicate XMPP streamID and parsed Stanza back to the manager:
    // var smdelegate: StreamManagerDelegate?

    private var _parser: XMLParser?
    private var _delegate: SAXDelegate
    private var _queue: DispatchQueue
    private let semaphore = DispatchSemaphore(value: 1)
    private var _data: Data?
    
    // TODO Set custom XMPP delegate
    
    init(delegate smdelegate: StreamManagerDelegate) {
        //self.smdelegate = smdelegate
        _delegate = SAXDelegate(delegate: smdelegate)
        _queue = DispatchQueue(label: "net.processone.XMPPParsing")
        super.init(data: Data())
        _parser = XMLParser(stream: self)
        _parser?.delegate = _delegate
        
        _queue.async {
            // For now, a queue thread is locked during the whole XMPP session,
            // because of https://bugs.swift.org/browse/SR-11608
            // Once this is solved, we can remore the semaphore and the reliance
            // InputStream methods
            self._parser?.parse()
        }
    }
    
    func parseData(_ data: Data) {
        self._data = data
        semaphore.signal()
    }
    
    func streamEnd() {
        self._data = nil
        semaphore.signal()
    }
    
    // MARK: InputStream
    override func open() {
        semaphore.wait()
        print("Open Called")
        return
    }
    
    override func close() {
        print("Close Called")
        return
    }
    
    // Return 0 when the underlying stream is closed. Should be blocking
    // otherwise
    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        print("Read before semaphore")
        
        // Wiating for data to be available
        semaphore.wait()
        print("Read after semaphore")
        if let data = _data {
            data.copyBytes(to: buffer, count: data.count)
            return data.count
        }
        return 0
    }
    
    override var hasBytesAvailable: Bool {
        print("HadBytesAvailable closed")
        return true
    }
    
    override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        return false
    }
}
