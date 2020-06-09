//
//  IQEncoder.swift
//  XMPP
//
//  Created by Mickaël Rémond on 2018-11-01.
//  Copyright © 2018-2020 ProcessOne. All rights reserved.
//

public class IQ: Stanza {
    public enum XMPPType: String {
        case set
        case get
        case error
    }
    
    public init(type t: XMPPType = .get, to jid: JID? = nil, id: String? = nil) {
        super.init(localname: "iq")
        attrs["to"] = jid?.full()
        attrs["type"] = t.rawValue
        attrs["id"] = id ?? randomID(length: 6)
    }
    
    public func addPayload(node: Node) {
        nodes.append(node)
    }
    
    public func getPayload(namespace: String) {
        // TODO:
    }
    
    private func randomID(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
}

// p1:push IQ payload
// set methods are used to define the builder methods
// get methods are used to define the parsing methods
//
// A p1:push setup iq stanza can be prepared as follows:
//
//   let iq = IQ(type: .set)
//   let payload = P1Push(keepalive: 30)
//   iq.addPayload(node: payload)
//
class P1Push: Node {
    
    init(keepalive interval: Int? = nil) {
        super.init(localname: "push", namespaces: ["p1:push"])
        if let k = interval {
            keepalive = k
        }
    }
    
    // =============================================================================
    // Session and connection reliability features
    
    // keepalive defines the interval (in second) at which the client is expected to send white space pings.
    // If the server does not hear from the client in that delay, it will consider the session as detached.
    // keepalive is disabled as default.
    // When defined, it should be a value between 30 and 300.
    var keepalive: Int? {
        set {
            guard var interval = newValue else {
                deleteChild(localname: "keepalive")
                return
            }
            guard interval > 0 else {
                deleteChild(localname: "keepalive")
                return
            }
            
            if interval < 30 {
                interval = 30
            }
            if interval > 300 {
                interval = 300
            }
            let node = Node(localname: "keepalive", attrs: ["max":String(interval)])
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "keepalive")) else { return nil }
            guard let maxS = n.attrs["max"] else { return nil }
            if let max = Int(maxS) {
                if max < 30 {
                    return 30
                }
                if max > 300 {
                    return 300
                }
                return max
            }
            return nil
        }
    }
    
    // Session define the duration (in minutes) during which the session will be kept on the server in detached
    // mode (= without any TCP connection open).
    // Session can stay up between 0 minutes (to disconnect immediately when connection loss is detected)
    // and a day (24 hours).
    var session: Int? {
        set {
            guard var duration = newValue else {
                deleteChild(localname: "session")
                return
            }
            guard duration > 0 else {
                deleteChild(localname: "session")
                return
            }

            if duration > 1440 {
                duration = 1440
            }
            let node = Node(localname: "session", attrs: ["duration":String(duration)])
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "session")) else { return nil }
            guard let durationS = n.attrs["duration"] else { return nil }
            if let duration = Int(durationS) {
                if duration <= 0 {
                    // Default value is 0 on server
                    return nil
                }
                if duration > 1440 {
                    return 1440
                }
                return duration
            }
            return nil
        }
    }
    
    // =============================================================================
    // Push notification related features
    
    enum NotificationType: String {
        case apns = "applepush"
        case gcm
        case fcm
        case fcmData = "fcm-data" // TODO: Check doc update
    }
    
    struct Notification {
        var serviceType: NotificationType
        var token: String
    }
    
    private var _pushEnabled: Bool = false
    
    func enablePush(type t: NotificationType, token: String) {
        _pushEnabled = true

        // Set notification type, to enable push (optional)
        notification = Notification(serviceType: t, token: token)
        
        // Set APNS push mode
        if let provision = MobileProvision.read() {
            print("We need to use Sandbox")
            sandbox = provision.entitlements.apsEnvironment == .development ? true : false
        }
        
        // As default, we want to receive push when the session expired
        offline = true
        
        // Set meaningful default values for push text
        // TODO: Should this be a localizable string with parameters from push notification ?
        body = Body(send: .all, groupchat: true, from: .name)
    }
    
    var notification: Notification? {
        set {
            // Always set notification from scratch
            deleteChild(localname: "notification")
            guard let pushConfig = newValue else { return }
            
            let type = Node(localname: "type", content: pushConfig.serviceType.rawValue)
            let token = Node(localname: "id", content: pushConfig.token)
            let notif = Node(localname: "notification")
            notif.nodes = [type, token]
            setChild(node: notif)
        }
        get {
            guard let notif = getChild(node: Node(localname: "notification")) else { return nil }
            guard let tokenNode = notif.getChild(node: Node(localname: "id")) else { return nil }
            guard let tokenS = tokenNode.content else { return nil }
            guard let typeNode = notif.getChild(node: Node(localname: "type")) else { return nil }
            guard let typeS = typeNode.content else { return nil }
            guard let type = NotificationType(rawValue: typeS) else { return nil }
            return Notification(serviceType: type, token: tokenS)
        }
    }
    
    // TODO: This value should probably be in notification tag (subel or attr)
    // Default value = false
    var sandbox: Bool {
        set {
            // The default for apns-sandbox is false, so we can omit it
            if newValue == false {
                deleteAttr(name: "apns-sandbox")
                return
            }

            attrs["apns-sandbox"] = "true"
        }
        get {
            guard let sandbox = attrs["apns-sandbox"] else { return false }
            if sandbox == "true" {
                return true
            }
            return false
        }
    }
    
    // TODO: This value should probably be in notification tag (subel or attr) + Default should probably reversed.
    // Default value = false
    var offline: Bool {
        set {
            // The default for offline is false, so we can omit it
            if newValue == false {
                deleteChild(localname: "offline")
                return
            }
            let node = Node(localname: "offline", content: "true")
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "offline")) else { return false }
            guard let offlineS = n.content else { return false }

            if let offline = Bool(offlineS) {
                if offline == true {
                    return true
                }
            }
            return false
        }
    }
    
    // TODO: Read default appid from provisioning profile ?
    var appId: String? {
        set {
            // The default for offline is false, so we can omit it
            guard let appid = newValue else {
                deleteChild(localname: "appid")
                return
            }
            let node = Node(localname: "appid", content: appid)
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "appid")) else { return nil }
            guard let appid = n.content else { return nil }
            return appid
        }
    }
    
    // Allow customizing standard push body
    struct Body {
        var send: Send?
        var groupchat: Bool?
        var from: From?
        
        enum Send: String {
            case all
            case firstPerUser = "first-per-user"
            case first
            case none
        }
        
        enum From: String {
            case jid, none, username, name
        }
    }
    
    var body: Body? {
        set {
            guard let b = newValue else {
                deleteChild(localname: "body")
                return
            }
            // Do not create an empty node
            guard b.from != nil || b.groupchat != nil || b.send != nil else {
                deleteChild(localname: "body")
                return
            }
            let node = Node(localname: "body")
            if let send = b.send {
                node.attrs["send"] = send.rawValue
            }
            if let groupchat = b.groupchat {
                node.attrs["groupchat"] = groupchat ? "true" : "false"
            }
            if let from = b.from {
                node.attrs["from"] = from.rawValue
            }
            setChild(node: node)
        }
        get {
            guard let n = getChild(node: Node(localname: "body")) else { return nil }
            var b = Body()
            if let s = n.attrs["send"] {
                b.send = Body.Send(rawValue: s)
            }
            if let f = n.attrs["from"] {
                b.from = Body.From(rawValue: f)
            }
            b.groupchat = n.attrs["from"] == "true" ? true : false
            return b
        }
    }
}

// TODO: How do we disable push for a given token ?
// Should we do that as default when the client has a token but want to disable push ?
// Maybe we should have a disabled attribute on notification tag, to force remove from db on client side ?
// Otherwise, we should probably have a device name (resource) and a rule on server that clean the tokens for
// that resource when the notification tag is not set. Probably, this is easier to implement reliably on the
// client.
//
// The disco of the push on the server should not only tell the client if p1:push is supported (and which version),
// but also which notification types (apns, fcm, fcm-data, gcm) are supported.
// Webpush should also probably be a notification type in that same p1:push configuration.
