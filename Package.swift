// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XMPP",
    products: [
        .library(name: "XMPP", targets: ["XMPP"]),
    ],
    targets: [
        .systemLibrary(name: "libxml2", pkgConfig: "libxml-2.0", providers: [.brew(["libxml2"])]),
        .target(name: "XMPP", dependencies: ["libxml2"]),
        .testTarget(name: "XMPPTests", dependencies: ["XMPP"]),
    ]
)
