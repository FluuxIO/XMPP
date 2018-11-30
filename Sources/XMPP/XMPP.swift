//
// Created by Mickaël Rémond on 2018-10-18.
// Copyright (c) 2018 ProcessOne. All rights reserved.
//

import Foundation

// TODO: Move the dependency for iOS feature to a specific file.
#if os(iOS)
import UIKit
#endif

// XMPP is the XMPP client wrapper, managing the XMPP session, client workflow.
// It serves as the interface between the client and the XMPP server.
//
// XMPP is created using a Config struct.
// The user of the library can pass a delegate to support receiving events from the
// XMPP services (messages, presence updates, IQs, etc).
// When the connection is triggered the XMPP client will create the following dependent
// classes:
//  1. NWConnection is created to initiate the low level connection to the XMPP server.
//       Our XMPP client is responsible for providing function to react to network events
//       (connected, disconnected, etc) and receive data. It will feed the data to the XML
//       parser.
//  When socket state is connected and available, we create the following:
//  2. SAXDelegate instance: This instance is used by SAXParser to process parsing events.
//       It is responsible for splitting the XMPP packet and passing them to the
//       XMPPEventDelegate (user of our app). It holds a weak reference to our XMPP
//       client instance that is used to keep track of the current session state and
//       pass back information to the XMPPEventDelegate
//  3. SAXParser instance: The SAXParser will receive the raw data coming from the network and
//       feed them to libxml2 event parser (SAX). It relies on our SAXDelegate to process
//       SAX XML events.
// On disconnect, all the previously created instances are destroy. They will be recreated on
// reconnect.
//
// TODO: Add diagram of dependency for the XMPP client facade.
public final class XMPP: ConnectionDelegate, StreamManagerDelegate {
    public var delegate: XMPPDelegate?
    var onDisconnect: DisconnectHandler?
    
    // XMPP client configuration
    var config: Config
    // Server features discovered
    var features: Features

    // Delegation
    private var conn: Connection
    private var parser: Parser?

    // XMPP Workflow states
    private var xmppState: state
    var streamID: String = ""

    // Rebind support
    var rebindID: String?
    var mechanisms: Node?
    var keepAliveTimer: Timer?
    
    // State management
    enum state {
        case streamOpen, waitForRebind, waitForAuth, waitForFeatures, waitForBind,
             connected, disconnect, background
    }

    public init(config conf: Config) {
        config = conf
        features = Features()
        // Define initial state
        xmppState = .streamOpen
        // Setup networking
        conn = Connection(host: conf.host, port: conf.port)
        conn.streamObserver = conf.streamObserver
        conn.delegate = self
    }
    
    public typealias DisconnectHandler = () -> Void
    
    // Initiate actual XMPP client connection
    public func connect(_ disconnectHandler: DisconnectHandler? = nil) {
        xmppState = .streamOpen
        if let handler = disconnectHandler {
            onDisconnect = handler
        }
        conn.start(useTLS: config.useTLS, allowInsecure: config.allowInsecure)
    }
    
    // Terminate the XMPP client.
    // This called is either user initiated or trigger or non recoverable errors
    public func terminate() {
        conn.stop()
        onDisconnect?()
    }
    
    // ============================================================================
    // iOS background support
    // Switch client to background mode
    public func enterBackground() {
        keepAliveTimer?.invalidate()
        conn.stop()
        xmppState = .background
    }
    
    public func enterForeground() {
        connect()
    }
    
    // TODO: It should be async and have a callback to confirm when the actual send was performed.
    // TODO: We should probably queue outgoing message when we are not connected.
    // send is a public function to allow client to send stanza to the XMPP server.
    // It can be used only when the session is in the state 'connected'
    public func send(_ stanza: Stanza) throws {
        guard xmppState == .connected else { return }
        try sendStanza(stanza)
    }
    
    // This is a private method.
    func sendStanza(_ stanza: Stanza) throws {
        let encoder = Encoder()
        let packet = try encoder.encode(stanza)
        conn.send(string: packet)
    }
    
    // sendRaw allows sending raw, unchecked data in the XMPP stream.
    // The content of the string should be a valid and correct XMPP stanza.
    // This is a private function.
    private func sendRaw(string: String) {
        conn.send(string: string)
    }
    
    // =====================================================================================
    // Networking callbacks
    
    func onStateChange(_ newState: State) {
        switch newState {
        // When connection is ready, initiate the XMPP session workflow
        case .ready:
            // Setup parser
            //parser = Parser(handler: { [weak self] (stanza) in self?.processEvent(stanza) })
            parser = Parser(delegate: self)
            // Open initial stream tag
            openStream()
        case .cancelled:
            cleanUpState()
            #if os(iOS)
            DispatchQueue.main.async {
                let state = UIApplication.shared.applicationState
                if state == .active || state == .inactive { // Only connect when in foreground
                    self.connect() // TODO: Check if we want to have wait / cooldown time
                }
            }
            #else
            if let handler = onDisconnect {
                handler()
            } else {
                self.connect() // TODO: Check if we want to have wait / cooldown time
            }
            #endif
        case .failed(_):
            cleanUpState()
            onDisconnect?()
        default:
            break
        }
        delegate?.onConnectionUpdate(newState)
    }
    
    // Clean up internal states on disconnect or fatal error
    private func cleanUpState() {
        streamID = ""
        xmppState = .streamOpen
        parser = nil
    }
    
    // When data are received from network dispatch them to parser
    func receive(bytes: [UInt8]) {
        parser?.parse(bytes: bytes)
    }
    
    // =====================================================================================
    // StreamManagerDelegate: XMPP stream initiation workflow

    // TODO: Support for fast open (stream open with initial SYN) ?
    func openStream() {
        print("In open stream")
        let openStream = "<?xml version='1.0'?><stream:stream to='\(config.jid.server)' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
        sendRaw(string: openStream)
    }
    
    // Receive parsed data from Parser
    func processEvent(_ stanza: Stanza) {
        //print("Process Even node: \(stanza)")
        // TODO: catch error to pass them to client using the library
        switch xmppState {
        case .streamOpen:
            // print("Process stream open")
            xmppState = processStreamOpened(stanza)
        case .waitForRebind:
            // print("Process rebind result")
            xmppState = processRebind(stanza)
        case .waitForAuth:
            xmppState = processWaitForAuth(stanza)
        case .waitForFeatures:
            xmppState = processWaitForFeatures(stanza)
        case .waitForBind:
            xmppState = processWaitForBind(stanza)
        case .connected:
            // print("[XMPP] Received: \(stanza)")
            // Route XMPP stanza to client
            delegate?.onStanza(stanza)
        default:
            print("Received unexpected stanza in state \(xmppState): \(stanza)")
        }
    }
    
    func processStreamOpened(_ node: Node) -> state {
        guard node.prefix == "stream"
            else {
                print("\(node)")
                return xmppState
        }
        switch node.localname {
        case "features":
            return rebindAttempt(node)
        case "error":
            //let err = XMPPError(node: stanza) ?? XMPPError(type: "stream-open", text: "unknown error")
            // router.connectionResult(channel: _channel, result: Result<Jid>.error(err))
            terminate()
            return .disconnect
        default:
            print("Default case: \(node)")
            // let err = XMPPError(type: "stream-open", text: "unknown error")
            // router.connectionResult(channel: _channel, result: Result<Jid>.error(err))
            terminate()
            return .disconnect
        }
    }
    
    func rebindAttempt(_ stanza: Stanza) -> state {
        // TODO: Check if the server supports p1:rebind
        if let sid = rebindID {
            // TODO: Add a rebind attempt state ?
            let line = "<rebind xmlns='p1:rebind'><jid>\(config.jid)</jid><sid>\(sid)</sid></rebind>"
            // Cache mechanisms:
            mechanisms = stanza
            sendRaw(string: line)
            return .waitForRebind
        } else {
            return processFeaturesForAuth(stanza)
        }
    }
    
    func processRebind(_ stanza: Stanza) -> state {
        switch stanza.localname {
        case "rebind":
            mechanisms = nil
            // TODO: Check if there is anything to do on successfull rebind
            // TODO: Do we want to call a specific delegate on rebind to let client know about it?
            // maybe not, as we want to handle this transparently.
            setTimer()
            return .connected
        case "failure":
            if let mech = mechanisms {
                let newState = processFeaturesForAuth(mech)
                mechanisms = nil
                return newState
            }
            // No mechanisms in cache => Fails
            terminate()
            return .disconnect
        default:
            print("Unknown rebind result: \(stanza)")
            terminate()
            return .disconnect
        }
    }

    // TODO: Implement other auth types (for now only PLAIN is supported)
    func processFeaturesForAuth(_ stanza: Node) -> state {
        guard let mechanisms = stanza.nodes.first(where: { $0.localname == "mechanisms" })
            else { return xmppState }
        let mechNodes = mechanisms.nodes.filter { $0.localname == "mechanism" }
        let mechs = mechNodes.map { $0.content?.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if mechs.contains(where: { $0 == "PLAIN" }) {
            let user = userCredentials(username: config.jid.local, password: config.password)
            if let enc = user.toPlain() {
                let line = "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>\(enc)</auth>"
                sendRaw(string: line)
                return .waitForAuth
            }
        }
        
        // TODO: return an error to client when server do not support a known authentication mechanism
        return xmppState
    }
    
    // Authentication result
    func processWaitForAuth(_ stanza: Node) -> state {
        switch stanza.localname {
        case "success":
            // We need to reopen the stream after authentication, so we recreate the SAX Parser
            parser = Parser(delegate: self)
            
            // Reopen the stream
            let line = "<?xml version='1.0'?><stream:stream to='\(config.jid.server)' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
            sendRaw(string: line)
            return .waitForFeatures
        case "failure":
            var (type, text) = ("", "")
            for node in stanza.nodes {
                if node.localname == "text" {
                    text = node.content ?? ""
                } else {
                    type = node.localname
                }
            }
            let err = ConnectionError.session(SessionError(type: type, text: text))
            delegate?.onConnectionUpdate(State.failed(err))
            terminate()
            return .disconnect
        default:
            print("unknown response to auth packet")
            return xmppState
        }
    }
    
    // Store the server features
    func processWaitForFeatures(_ stanza: Stanza) -> state {
        guard stanza.prefix == "stream" && stanza.localname == "features" else { return xmppState }
        
        // 1. Store the server features:
        features = Features(from: stanza)
        
        // 2. Bind remote session to our client resource:
        // TODO: Generate proper IQ with incremental id
        var resource = JID.makeResource() // TODO: add a way to store the resource locally to reuse it on subsequent connection.
        if let res = config.jid.resource {
            resource = res
        }
        let line = "<iq type='set' id='bind1'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><resource>\(resource)</resource></bind></iq>"
        sendRaw(string: line)
        return .waitForBind
    }
    
    func processWaitForBind(_ stanza: Node) -> state {
        if let j = IQ.bindResultJid(from: stanza) {
            config.jid = j      // Update the JID as confirmed by server
            rebindID = streamID // Cache rebindID
            delegate?.onConnectionUpdate(State.connected(j))
            setupSession()
            setTimer()
            return .connected
        } else {
            // TODO: failure handler
            terminate()
            return .disconnect
        }
    }
    
    // TODO: Handle session if mandatory
    
    // =============================================================
    // Session configuration based on client preferences
    func setupSession() {
        // Setup Push
        let pushPayload = P1Push(keepalive: 30)
        pushPayload.session = 180
        if let token = config.pushToken {
            pushPayload.enablePush(type: .apns, token: token)
        }
        let iq = IQ(type: .set)
        iq.addPayload(node: pushPayload)

        do {
            try sendStanza(iq)
        /*
         if let initialPresence = config.initialPresence {
         do {
         try _channel.send(node: initialPresence)
         } catch {}
         }*/
            try sendStanza(Presence())
        } catch let err {
            print("Cannot generate stanza: \(err)")
        }
    }

    // Setup timer for keep-alive
    func setTimer() {
        keepAliveTimer?.invalidate()
        DispatchQueue.main.async {
            // Timers need a runloop
            self.keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { [weak self] timer in
                self?.conn.send(string: "\r\n")
            })
        }
    }
}

// Implement callbacks to handle receiving events from XMPP client
public protocol XMPPDelegate {
    // ConnectionState: .connecting, .ready, .failed(error), .waiting(error), .cancelled.
    func onConnectionUpdate(_ newState: State)
    func onStanza(_ stanza: Stanza)

    // TODO: Allow finer grain subscription).
    // func onMessage(_ stanza: Stanza)
    // func onIQ(_ stanza: Stanza)
    // func onError(_ error: XMPPError)
    
    // TODO: Should we use handlers to be able to make some methods optional ?
}

// State convey changes in connection states
public enum State {
    case ready
    case connected(JID)
    case failed(ConnectionError)
    case waiting(ConnectionError)
    case cancelled
}

// Error types:
// StreamError
