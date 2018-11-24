//
//  MobileProvisionTests.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 03/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import XCTest
@testable import XMPP

class MobileProvisionTests: XCTestCase {

    func testDecodeMobileProvision() {
        let bundle = Bundle(for: type(of: self))
        
        // Development provisioning profile
        var path = bundle.testPath(forResource: "dev-mock", ofType: "mobileprovision")!
        var provision = MobileProvision.read(from: path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .development)
        
        // Production provisioning profile
        path = bundle.testPath(forResource: "prod-mock", ofType: "mobileprovision")!
        provision = MobileProvision.read(from: path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .production)
        
        // Broken provisioning profile (with some fields removed)
        path = bundle.testPath(forResource: "broken-mock", ofType: "mobileprovision")!
        provision = MobileProvision.read(from: path)
        XCTAssertEqual(provision?.entitlements.apsEnvironment, .disabled)
    }
    
}
