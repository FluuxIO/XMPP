//
//  ConnectionError.swift
//  XMPP
//
//  Created by Mickaël Rémond on 22/10/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Network

// TODO: Support error description
public enum ConnectionError: Error {
    // Error can come from NWError
    case network(Error)
    // or it can be an error at XMPP level, coming from session establishment
    case session(SessionError)
}

// Wrap unrecoverable errors that happens at the XMPP session level.
// This is for example the case for authentication errors.
public struct SessionError: Error {
    var type: String
    var text: String?
}
