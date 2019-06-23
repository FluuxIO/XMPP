//
//  MobileProvisionTests.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 2018-11-03.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.
//

import XCTest
@testable import XMPP

class MobileProvisionTests: XCTestCase {

    func testDecodeMobileProvision() {
        guard let bundle = Bundle(forTest: self) else { XCTFail("Missing init bundle"); return }
        
        // Development provisioning profile
        var path = bundle.path(forResource: "dev-mock", ofType: "mobileprovision")!
        var provision = MobileProvision.read(from: path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .development)
        
        // Production provisioning profile
        path = bundle.path(forResource: "prod-mock", ofType: "mobileprovision")!
        provision = MobileProvision.read(from: path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .production)
        
        // Broken provisioning profile (with some fields removed)
        path = bundle.path(forResource: "broken-mock", ofType: "mobileprovision")!
        provision = MobileProvision.read(from: path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .disabled)
    }
}
