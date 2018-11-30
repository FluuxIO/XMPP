//
//  TestsHelpers.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 24/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import XCTest
import Foundation

extension Bundle {

    convenience init?(forTest testClass: XCTestCase) {
        if isRunningXCTest() {
            self.init(for: type(of: testClass))
        } else {
            let fileManager = FileManager.default
            let path = fileManager.currentDirectoryPath
            self.init(path: "\(path)/Tests/XMPPTests/TestData")
        }
    }
}

// Return true if running in XCode (and thus will have access to test bundle)
// or false of running in Swift
fileprivate func isRunningXCTest() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
