//
//  Config.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-14.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

public struct Config {
    // Will use server JID as host if not set explicitely:
    public var host: String
    public var port: Int = 5222
    public var jid: JID
    public var password: String

    // TLS Support
    public var useTLS: Bool
    // Allows connecting to server in SSL with incorrect or self-signed certificates:
    public var allowInsecure: Bool = false

    // Stream Observer
    public var streamObserver: StreamObserver?
    
    // public var initialPresence: Presence? = Presence()
    
    public var debug: Bool = false
    // public var initialPresence: Presence? = Presence()
    
    public var pushToken: String?
    
    // Possible options:
    //  - Logger
    //  - Lang
    //  - Retry
    //  - Push token

    public init(jid: JID, password: String, useTLS: Bool = false, debug: Bool = false) {
        self.jid = jid
        self.password = password

        self.debug = debug

        self.useTLS = useTLS
        if useTLS == true {
            port = 5223
        }

        host = jid.server
        
        //  - ConnectTimeout
    }
    
    var connection: Connection {
        get {
            #if os(Linux)
            return ConnectionNIO(host: host, port: port)
            #else
            return ConnectionTAPS(host: host, port: port)
            #endif
        }
    }
}
