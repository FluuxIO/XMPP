import Foundation

// This is the implementation for Linux and MacOS with build through SwiftPM.
// It is not compiled with XCode, only through SwiftPM.

final class Connection: ConnectionP {
    weak var delegate: ConnectionDelegate?
    var streamObserver: StreamObserver?
    
    init(host: String, port: Int) {}
    func start(useTLS: Bool, allowInsecure: Bool) {}
    func stop() {}
    func send(data: Data?) {}
    func send(string: String) {}
}
