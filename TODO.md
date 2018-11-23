# TODO

- Organise tests for Swift PM, staying compliant with XCode setup.
- Test project setup with Carthage on iOS and MacOS
- Test project setup with Cocoapods on iOS and MacOS

## Backlog

- MacOS support
- Document code (Jazzy?).
- Detect connection loss when not receiving the replies from the keep-alive
- Detect p1:push support before sending p1:push configuration.
- Ability to send an IQ, passing a block to process the IQ reply.
- Define autoreconnect strategy.
- Add parser in the XMPP lib, focusing on extracting only the pieces of code we use.
- Add other auth mechanisms
- Add support for optional session
- Add roster query support.
- End to end encryption support
- MacOS support
- Linux support with SwiftNIO
- Attempt to run it on Android ?
- Message ack
- Persistent outgoing message queue to accumulate when there is no network
- Retry sending unsent messages in background
- Check progress on [SE-0236](https://forums.swift.org/t/se-0236-package-manager-platform-deployment-settings/17992) to update Package.swift and update doc.

# Done

- Test project setup with Swift PM
- Publish in Cocoapods / test using project from Carthage
- Bootstrap the framework to make it usable from Carthage, Cocoapod or Git submodules
- Observe incoming and outgoing Stream content to help with debugging. It could be used in a standalone XMPP console for iPad.
- Keep-alive support
- Basic support for p1:rebind
- Support for basic push notifications: Setup session and p1:push. Pass token if known.
- Add SSL (port 5223) support (not starttls as Network.Framework does not support STARTTLS yet).

