//
//  ConnectionProtocol.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-11-25.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.

import Foundation

// This is the communication protocol between our network connection and our XMPP client facade.
protocol ConnectionDelegate: AnyObject {
    func onStateChange(_ newState: State)
    func receive(bytes: [UInt8])
}

protocol Connection {
    init(host: String, port: Int)
    func start(useTLS: Bool, allowInsecure: Bool)
    func stop()
    func send(data: Data?)
    func send(string: String)
    var streamObserver:StreamObserver? { get set }
    var delegate: ConnectionDelegate? { get set }
}
