//
//  Features.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-10-24.
//  Copyright © 2018-2019 ProcessOne. All rights reserved.
//

import Foundation

// This struct is used by XMPP connection to store the server features discovered by the client.
struct Features {
    var p1PushSupport: Bool = false

    // TODO: Parse stanza and initiate list of discovered features on the server.
    // If the stanza is not a stream:features stanza, the features discovered will be empty.
    init(from stanza: Stanza? = nil) {
    }
}
