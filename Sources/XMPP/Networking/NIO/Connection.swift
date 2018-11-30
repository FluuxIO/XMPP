//
//  Connection.swift
//  XMPP
//
//  Created by Mickaël Rémond on 25/11/2018.
//  Copyright © 2018 ProcessOne. All rights reserved.
//

import Foundation
import NIO

// This is the implementation for Linux and MacOS when the lib is build through SwiftPM.
// It is not compiled with XCode, only through SwiftPM.

final class Connection: ConnectionP {
    weak var delegate: ConnectionDelegate?
    var streamObserver: StreamObserver?
    
    // Parameters
    let host: String
    let port: Int
    
    // swift-nio
    private var nioChannel: Channel?
    private let evGroup: MultiThreadedEventLoopGroup
    private var closeFuture: EventLoopFuture<Void>?
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    init(host h: String, port p: Int = 5222) {
        host = h
        port = p
        evGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    
    deinit {
        try! evGroup.syncShutdownGracefully()
    }
    
    func start(useTLS: Bool, allowInsecure: Bool) {
        let bootstrap = ClientBootstrap(group: evGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.add(handler: self)
        }
        
        // Connect and wait for the connection to be ready
        do {
            // TODO: Fix wait() this as we probably want to be asynchronous here:
            nioChannel = try bootstrap.connect(host: host, port: port).wait()
        } catch ChannelError.connectFailed {
            print("Connection error: connectFailed")
            let err = ConnectionError.network("connectFailed")
            delegate?.onStateChange(State.failed(err))
            return
        } catch let err {
            print("Connection error: \(err)")
            let err = ConnectionError.network("\(err)")
            delegate?.onStateChange(State.failed(err))
            return
        }
        
        closeFuture = nioChannel?.closeFuture
    }
    
    func stop() {
        try? nioChannel?.close().wait()
    }
    
    func send(data: Data?) {
        guard let data = data else { return }
        guard let channel = nioChannel else { return }
        
        streamObserver?.onEvent(StreamEvent.sent(xmpp: String(decoding: data, as: UTF8.self)))
        channel.sendRaw(data: data)
    }

    func send(string: String) {
        print("Will send string")
        guard let channel = nioChannel else { return }

        streamObserver?.onEvent(StreamEvent.sent(xmpp: string))
        channel.sendRaw(string: string)
    }
}

extension Connection: ChannelInboundHandler {
    // When connection is established and Swift-NIO is ready,
    // prepare a new XMPPSession and XML parser for new client
    func channelActive(ctx: ChannelHandlerContext) {
        print("Client connected to \(ctx.remoteAddress!)")
        // Connection is established, calling the delegate will trigger the negociation.
        delegate?.onStateChange(State.ready)
    }
    
    // TODO: Control packet size to prevent attack by sending an unlimited packet size
    // => The server should prevent this. Default limit is 50 KB.
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        // Convert channel data
        var read = unwrapInboundIn(data)
        let input = read.readBytes(length: read.readableBytes)
        guard let bytes = input else { return }

        delegate?.receive(bytes: bytes)
        if let string = String(bytes: bytes, encoding: .utf8) {
            // Send data to parser
            streamObserver?.onEvent(StreamEvent.received(xmpp: string))
        } else {
            print("not a valid UTF-8 sequence")
            ctx.close(promise: nil)
        }
    }
    
    // Network error
    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        let err = ConnectionError.network("Network error: \(error)")
        delegate?.onStateChange(State.failed(err))
        ctx.close(promise: nil)
    }
    
    // Connection has been closed
    func channelInactive(ctx: ChannelHandlerContext) {
        ctx.close(promise: nil)
        delegate?.onStateChange(State.cancelled)
    }
}

fileprivate extension Channel {
    func sendRaw(string: String) {
        var buffer = allocator.buffer(capacity: string.utf8.count)
        buffer.write(string: string)
        print("Write and flush buffer")
        writeAndFlush(NIOAny(buffer), promise: nil)
    }
    
    func sendRaw(data: Data) {
        let bytes = [UInt8](data)
        var buffer = allocator.buffer(capacity: bytes.count)
        buffer.write(bytes: bytes)
        writeAndFlush(NIOAny(buffer), promise: nil)
    }
}
