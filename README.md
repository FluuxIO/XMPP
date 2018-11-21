# Fluux XMPP

Fluux XMPP is a Chat SDK for iOS, implementing XMPP protocol. XMPP is an IETF standard.

Fluux XMPP is a clean slate implementation, with the following goals in mind:

- Focus on simplicity, by hiding XMPP technical details and exposing only chat oriented methods.
- Focus on modern Swift, recent iOS version and modern XMPP. The library ignores legacy or deprecated features on purpose.
- Focus on maintainability. XMPP is a complex protocol and maintainability should be the main criteria for design decision to be able to be sustainable in the long term.
- Focus on efficiency and scalability, leveraging only part of the XMPP protocol that are scalable. Many XEPs are too consuming to be used on large scale on production.

As a result, on iOS, we target iOS version 12+.

*Note*: This library is under development and not yet ready for production.

## Using Fluux XMPP with Carthage

1. Create your project as usual in XCode.
2. Save your project as a workspace, so that you can build your dependencies as submodules. Close the project.
3. Install [Carthage](https://github.com/Carthage/Carthage), if you do not already have the tool installed
4. Create a `Cartfile` (or update your existing one) to include Fluux XMPP as a dependency:
   ```
   github "FluuxIO/XMPP.git" ~> 0.0
   ```
5. Download and build the Fluux XMPP dependency:
   ```bash
   carthage update --platform iOS --use-submodules --no-use-binaries
   ```
	 We’re using `--use-submodules` so that our dependencies are added as submodules. This allows users to build the resulting application without Carthage if they want. We use `--no-use-binaries` so that dependencies are built locally on our system.
6. Open your application workspace and add your dependency projects into your workspace. You can do so by dragging the bundle `Carthage/Checkouts/XMPP/XMPP.xcodeproj` to your workspace.
7. In the *General* tab of your target, add Fluux XMPP as an embedded binary. Click `+` and select XMPP.framework for iOS.
8. You should now be able to use the framework from your app. Here is an example of minimal code you can add to your app to to an XMPP client: [Fluux XMPP client example for Fluux XMPP v0.0.1](https://gist.github.com/mremond/319dd29f2c308cf807f199b812260f98)

## Using Fluux XMPP with Cocoapods

Fluux XMPP library is published on [Cocoapods](https://cocoapods.org/pods/XMPP).

You can thus use it as follows:

1. Close your project
2. Create (or update) your `Podfile` to include `pod 'XMPP'`. For example:

   ```ruby
   platform :ios, '12.0'
   
   target 'XMPPPodTest' do
     pod 'XMPP'
   end
   
   post_install do |installer| 
     installer.pods_project.build_configurations.each do |config|
       if config.name == 'Release'
         config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
       end    
     end
   end
   ```
3. Install the dependencies:
   ```bash
   pod install
   ```
4. Open the workspace. You can now start using Fluux XMPP. Here is an example of minimal code you can add to your app to to an XMPP client:     [Fluux XMPP client example for Fluux XMPP v0.0.1](https://gist.github.com/mremond/319dd29f2c308cf807f199b812260f98).


## TLS support

At the moment the library only support standard TLS connection, not STARTTLS.
Apple Networking library does not support (yet ?) switching encryption after the connection
has been established, because they are worried by possible security issues around STARTTLS
implementations.

That said, XMPP support TLS on port 5223. It is called "legacy" SSL because use of port 5223
has been deprecated by the XMPP Standards Foundation a while back. That said, modern XMPP servers
like ejabberd support state of the art TLS on port 5223.
To use TLS at the moment, it is perfectly fine to use TLS on port 5223.

