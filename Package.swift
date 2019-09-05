// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "XMPP",
    
    // TODO: We could support a broader range if using Swift-NIO directly for all platforms
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
        .tvOS(.v12),
        // for 5.1: .watchOS(.v6)
    ],
    
    products: [
        .library(name: "XMPP", targets: ["XMPP"]),
        .executable(name: "XMPPDemo", targets: ["XMPPDemo"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.0"),
    ],
    
    targets: [
        // Dependencies
        .target(name: "CXML",
                dependencies: [],
                //cSettings: [.headerSearchPath("deps/libxml2/")],
                linkerSettings: [.linkedLibrary("xml2")]),
        .target(name: "XFoundationCompat"),

        // Core lib
        .target(name: "XMPP", dependencies: ["NIO", "NIOSSL", "XFoundationCompat", "CXML"]),

        // Demo and tests
        .target(name: "XMPPDemo", dependencies: ["XMPP"]),
        .testTarget(name: "XMPPTests", dependencies: ["XMPP"]),
    ]
)
