# Fluux XMPP

Fluux XMPP is a Chat SDK for iOS, implementing XMPP protocol. XMPP is an IETF standard.

Fluux XMPP is a clean slate implementation, with the following goals in mind:

- Focus on simplicity, by hiding XMPP technical details and exposing only chat oriented methods.
- Focus on modern Swift, recent iOS version and modern XMPP. The library ignores legacy or deprecated features on purpose.
- Focus on maintainability. XMPP is a complex protocol and maintainability should be the main criteria for design decision to be able to be sustainable in the long term.
- Focus on efficiency and scalability, leveraging only part of the XMPP protocol that are scalable. Many XEPs are too consuming to be used on large scale on production.

## TLS support

At the moment the library only support standard TLS connection, not STARTTLS.
Apple Networking library does not support (yet ?) switching encryption after the connection
has been established, because they are worried by possible security issues around STARTTLS
implementations.

That said, XMPP support TLS on port 5223. It is called "legacy" SSL because use of port 5223
has been deprecated by the XMPP Standards Foundation a while back. That said, modern XMPP servers
like ejabberd support state of the art TLS on port 5223.
To use TLS at the moment, it is perfectly fine to use TLS on port 5223.

