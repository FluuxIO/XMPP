//
//  MobileProvisionTests.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 2018-11-03.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

import XCTest
@testable import XMPP

class MobileProvisionTests: XCTestCase {

    func testDecodeMobileProvision() {
        // Development provisioning profile
        let file1 = try! Resource(name: "dev-mock", ofType: "mobileprovision")
        var provision = MobileProvision.read(from: file1.path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .development)
        
        // Production provisioning profile
        let file2 = try! Resource(name: "prod-mock", ofType: "mobileprovision")
        provision = MobileProvision.read(from: file2.path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .production)
        
        // Broken provisioning profile (with some fields removed)
        let file3 = try! Resource(name: "broken-mock", ofType: "mobileprovision")
        provision = MobileProvision.read(from: file3.path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .disabled)
    }
}
