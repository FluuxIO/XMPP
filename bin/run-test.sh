#!/bin/bash

xcodebuild -scheme XMPP-iOS -destination 'name=iPhone XR' test

xcodebuild -scheme XMPP-MacOS test

swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12" --generate-linuxmain

swift test -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.12"
