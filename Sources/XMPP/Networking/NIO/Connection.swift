//
//  Connection.swift
//  XMPP
//
//  Created by Mickaël Rémond on 25/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Foundation

// This is the implementation for Linux and MacOS when the lib is build through SwiftPM.
// It is not compiled with XCode, only through SwiftPM.

final class Connection: ConnectionP {
    weak var delegate: ConnectionDelegate?
    var streamObserver: StreamObserver?
    
    init(host: String, port: Int) {}
    func start(useTLS: Bool, allowInsecure: Bool) {}
    func stop() {}
    func send(data: Data?) {}
    func send(string: String) {}
}
