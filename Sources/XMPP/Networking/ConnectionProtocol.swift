//
//  ConnectionProtocol.swift
//  XMPP
//
//  Created by Mickaël Rémond on 25/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Foundation

// This is the communication protocol between our network connection and our XMPP client facade.
protocol ConnectionDelegate: AnyObject {
    func onStateChange(_ newState: State)
    func receive(_ data: Data)
}

// TODO Change name (should be Connection. Connection class should be NetworkConnection
protocol ConnectionP {
    init(host: String, port: Int)
    func start(useTLS: Bool, allowInsecure: Bool)
    func stop()
    func send(data: Data?)
    func send(string: String)
    var streamObserver:StreamObserver? { get set }
    var delegate: ConnectionDelegate? { get set }
}
