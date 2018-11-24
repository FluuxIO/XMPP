//
//  TestsHelpers.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 24/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Foundation

extension Bundle {
    func testPath(forResource r: String, ofType t: String) -> String? {
        if isRunningXCTest() {
            return self.path(forResource: r, ofType: t)
        } else {
            return "Tests/XMPPTests/TestData/\(r).\(t)"
        }
    }
    
    // Return true if running in XCode (and thus will have access to test bundle)
    // or false of running in Swift
    private func isRunningXCTest() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
