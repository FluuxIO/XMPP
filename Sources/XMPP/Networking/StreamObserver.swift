//
//  StreamObserver.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-11-18.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.
//

public enum StreamEvent {
    case received(xmpp: String)
    case sent(xmpp: String)
    // TODO: Move connection state management here
    // case connectionState
}

public struct DefaultStreamObserver: StreamObserver {
    
    public init() {}
    
    public func onEvent(_ event: StreamEvent) {
        switch event {
        case .received(let xmpp):
            print("<- \(xmpp)")
        case .sent(let xmpp):
            print("-> \(xmpp)")
        }
    }
}

public protocol StreamObserver {
    func onEvent(_ event: StreamEvent)
}
