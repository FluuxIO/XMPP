//
//  SerializerTests.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 01/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import XCTest
@testable import XMPP

final class SerializerTests: XCTestCase {
    func testEmptyPresence() {
        let encoder = Encoder()
        
        let pres = Presence()
        let XML = try! encoder.encode(pres)
        XCTAssertEqual(XML, "<presence/>")
    }
    
    func testPresence() {
        let encoder = Encoder()
        
        let presTo = Presence(to: JID("user@example.net"))
        let XML1 = try! encoder.encode(presTo)
        XCTAssertEqual(XML1, "<presence to='user@example.net'/>")
        
        let presSubscribe = Presence(type: .subscribe)
        let XML2 = try! encoder.encode(presSubscribe)
        XCTAssertEqual(XML2, "<presence type='subscribe'/>")
        
        let presBase = Presence()
        presBase.to = JID("user@example.com")
        presBase.type = .unsubscribe
        XCTAssertEqual(presBase.type, .unsubscribe)
        let XML3 = try! encoder.encode(presBase)
        XCTAssertEqual(XML3, "<presence to='user@example.com' type='unsubscribe'/>")
    }
    
    func testShow() {
        let encoder = Encoder()
        
        let pres = Presence()
        pres.show = .dnd
        XCTAssertEqual(pres.show, .dnd)
        let XML = try! encoder.encode(pres)
        XCTAssertEqual(XML, "<presence><show>dnd</show></presence>")
    }
    
    func testPriority() {
        let encoder = Encoder()
        
        let pres = Presence()
        XCTAssertEqual(pres.priority, 0)
        pres.priority = -10
        XCTAssertEqual(pres.priority, -10)
        let XML = try! encoder.encode(pres)
        XCTAssertEqual(XML, "<presence><priority>-10</priority></presence>")
    }
    
    func testCustom() {
        let encoder = Encoder()
        
        let pres = Presence()
        pres.setChild(node: Node(localname: "custom", namespaces: ["testns"], content: "This is a custom tag"))
        let XML = try! encoder.encode(pres)
        XCTAssertEqual(XML, "<presence><custom xmlns='testns'>This is a custom tag</custom></presence>")
    }
    
    func testError() {
        /*
         let encoder = XMPPEncoder()
         
         let error = ErrorStanza(node: Presence())
         let XML = try! encoder.encode(error)
         XCTAssertEqual(XML, "<presence type='error'/>")
         */
    }
    
    func testAuth() {
        let encoder = Encoder()
        
        let auth = Node(localname: "auth", namespaces: ["urn:ietf:params:xml:ns:xmpp-sasl"], attrs: ["mechanism": "PLAIN"], content: "encodedCredentials")
        let XML = try! encoder.encode(auth)
        XCTAssertEqual(XML, "<auth mechanism='PLAIN' xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>encodedCredentials</auth>")
    }
    
    /*
    func testParsing() {
        let parser = Parser()
        let node = parser.parse(stanza: "<presence/>")
        XCTAssertEqual(node?.localname, "presence")
        
        let node2 = parser.parse(stanza: "<message/>")
        XCTAssertEqual(node2?.localname, "message")
    }
 */
    
    static var allTests = [
        ("testEmptyPresence", testEmptyPresence),
        ("testPresence", testPresence),
        ("testShow", testShow),
        ("testPriority", testPriority),
        ("testCustom", testCustom),
        ("testCustom", testError),
        ("testAuth", testAuth),
        //("testCustom", testParsing),
        ]
}
