//
//  IQEncoderTests.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 2018-11-01.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.
//

import XCTest
@testable import XMPP

final class IQEncoderTests: XCTestCase {
    
    // p1:push payload is intended to be embedded in iq set request sent to server.
    func testP1PushPayload() {
        let encoder = Encoder()
        
        let payload = P1Push()
        var XML = try! encoder.encode(payload)
        XCTAssertEqual(XML, "<push xmlns='p1:push'/>")
        
        payload.keepalive = 60
        XML = try! encoder.encode(payload)
        XCTAssertEqual(XML, "<push xmlns='p1:push'><keepalive max='60'/></push>")
        
        payload.session = 15
        XML = try! encoder.encode(payload)
        XCTAssertEqual(XML, "<push xmlns='p1:push'><keepalive max='60'/><session duration='15'/></push>")

        // Test forcing sandbox to true (test do not support provisionning profile to read push setup from).
        payload.enablePush(type:.apns, token: "testToken")
        payload.sandbox = true  // Force sandbox to true for checking attribute
        payload.appId = "io.fluux.tests"
        XML = try! encoder.encode(payload)
        XCTAssertEqual(XML, """
<push apns-sandbox='true' xmlns='p1:push'><keepalive max='60'/><session duration='15'/>\
<notification><type>applepush</type><id>testToken</id></notification>\
<offline>true</offline><body from='name' groupchat='true' send='all'/>\
<appid>io.fluux.tests</appid></push>
""")
    }
    
    // Test embedding p1:push payload in IQ set
    func testP1PushIQSet() {
        let encoder = Encoder()
        
        let iq = IQ(type: .set, id: "test1")
        let payload = P1Push(keepalive: 30)
        iq.addPayload(node: payload)
        let XML = try! encoder.encode(iq)
        XCTAssertEqual(XML, "<iq id='test1' type='set'><push xmlns='p1:push'><keepalive max='30'/></push></iq>")
    }
    
    // TODO: Test getters
}
