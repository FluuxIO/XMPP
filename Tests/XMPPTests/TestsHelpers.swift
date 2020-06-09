//
//  TestsHelpers.swift
//  XMPPTests
//
//  Created by Mickaël Rémond on 2018-11-24.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

import XCTest
import Foundation

// Helper to access test data from XCode 11. Bundle are not supported with SwiftPM.
struct Resource {
    let url: URL
    
    init(name: String, ofType: String) throws {
        let testFileURL = URL(fileURLWithPath: "\(#file)", isDirectory: false)
        let testDirURL = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("XMPPTests/TestData", isDirectory: true)

        self.url = testDirURL.appendingPathComponent("\(name).\(ofType)", isDirectory: false)
    }
    
    var path: String {
        get {
            return self.url.path
        }
    }
}
