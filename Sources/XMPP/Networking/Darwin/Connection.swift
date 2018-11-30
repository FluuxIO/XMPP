//
// Created by Mickaël Rémond on 2018-10-18.
// Copyright (c) 2018 ProcessOne. All rights reserved.
//

import Foundation
import Network

// This is the implementation for latest AppleOS, that support Network.framework.
// It is not compiled with SwiftPM, only with Xcode.

// Provide low level networking behaviour for Fluux XMPP client.
final class Connection: ConnectionP {
    private let endpoint: NWEndpoint
    private var conn: NWConnection?
    private let queue: DispatchQueue

    weak var delegate: ConnectionDelegate?
    var streamObserver: StreamObserver?

    init(host: String, port: Int) {
        // Setup network
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(String(port)) ?? 5222
        endpoint = NWEndpoint.hostPort(host: host, port: port)
        
        // Define queue for networking operations
        queue = DispatchQueue.init(label: "XMPP")
    }
    
    // =======================================================================
    // Internal for networking handling
    
    // TODO: Add support for viabilityUpdateHandler and betterPathUpdateHandler
    // Throw error if delegate is not set ?
    // TODO: Makes for sense to define useTLS and allowInsecure on init
    func start(useTLS: Bool = false, allowInsecure: Bool = false) {
        // Initiate TCP connection for TLS or TCP
        let parameters: NWParameters
        if useTLS == true {
            parameters = getTLSParameters(allowInsecure: allowInsecure, queue: queue)
        } else {
            parameters = NWParameters.tcp
        }

        // Setup and launch TCP connection
        conn = NWConnection.init(to: endpoint, using: parameters)
        conn?.stateUpdateHandler = { [weak self] in self?.stateUpdateHandler($0) }
        conn?.start(queue: queue)
    }

    func stop() {
        conn?.cancel()
    }
    
    // FIXME: handle error when sending when not connected ?
    func send(data: Data?) {
        conn?.send(content: data,
                completion: .contentProcessed({ [weak self] error in self?.handleNetworkError(error) }))
    }
    
    func send(string: String) {
        streamObserver?.onEvent(StreamEvent.sent(xmpp: string))
        send(data: string.data(using: .utf8))
    }
    
    func stateUpdateHandler(_ newState: NWConnection.State) {
        switch(newState) {
        case .ready:
            // Handle connection established
            // print("connection ready")
            delegate?.onStateChange(State.ready)
            // Start receiver loop:
            self.conn?.receive(minimumIncompleteLength: 1, maximumLength: 10000, completion:
                { [weak self] (data: Data?, ctx: NWConnection.ContentContext?, isComplete: Bool, error: NWError?) in
                    if let err = error {
                        print("Receive error: \(err)")
                    }
                    self?.receive(data, ctx, isComplete, error)
            })
        case .waiting(let error):
            print("waiting error: \(error)")
            // Handle connection waiting for network
            let networkError = ConnectionError.network(error.debugDescription)
            delegate?.onStateChange(State.waiting(networkError))
        case .failed(let error):
            // Handle fatal connection error
            print("failed error: \(error)")
        // TODO: Pass failed error to client.
        case .cancelled:
            print("connection terminated")
            conn = nil
            delegate?.onStateChange(State.cancelled)
        default:
            break
        }
    }

    // Receive data coming from network and send them to parser
    func receive(_ data: Data?, _ ctx: NWConnection.ContentContext?, _ isComplete: Bool, _ error: NWError?) {
        // TODO: Broadcast disconnect to client
        guard isComplete == false else { conn?.cancel(); return }
        if let err = error { broadcastError(error: err); return }
        
        // Pass data to delegate
        if let d = data {
            if let receivedString = String(data: d, encoding: String.Encoding.utf8) {
                streamObserver?.onEvent(StreamEvent.received(xmpp: receivedString))
            }
            delegate?.receive(bytes: Array(d))
        }
        
        // Receive next data from socket
        self.conn?.receive(minimumIncompleteLength: 1, maximumLength: 10000, completion:
            { [weak self] (data: Data?, ctx: NWConnection.ContentContext?, isComplete: Bool, error: NWError?) in
                self?.receive(data, ctx, isComplete, error)
        })
    }
    
    // Broadcast error to client
    func broadcastError(error: NWError) {
        switch error {
        case .posix(let code):
            // Connection cancelled is already handled at connection level State change event
            if code == POSIXError.ECANCELED {
                return
            }
        default:
            break
        }
        // TODO: Broadcast error to client. Should not be a state change error but probably a more general
        // Stream error ?
        print("receive error: \(error.debugDescription)")
    }
    
    func handleNetworkError(_ error: NWError?) {
        if error != nil {
            // TODO: Broadcast error to client
            print("handleNetworkError: \(error?.debugDescription ?? "nil error")")
        }
    }
}


// Prepare networking parameters for TLS, making it possible to accept invalid certificates.
// This can be handy during development, when it is typical to use self-signed certificates.
// However, it is not recommended to allow insecure certs in production, as this is opens
// a vector from man in the middle attacks.
fileprivate func getTLSParameters(allowInsecure: Bool, queue: DispatchQueue) -> NWParameters {
    let options = NWProtocolTLS.Options()
    
    sec_protocol_options_set_verify_block(options.securityProtocolOptions, { (sec_protocol_metadata, sec_trust, sec_protocol_verify_complete) in
        
        let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
        
        var error: CFError?
        if SecTrustEvaluateWithError(trust, &error) {
            sec_protocol_verify_complete(true)
        } else {
            if allowInsecure == true {
                sec_protocol_verify_complete(true)
            } else {
                sec_protocol_verify_complete(false)
            }
        }
        
    }, queue)
    
    return NWParameters(tls: options)
}

