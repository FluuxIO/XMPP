import Foundation
import XMPP


guard let jid = JID("test@localhost/XMPPDemo") else { print("Invalid JID"); exit(1) }
var xmppConfig = Config(jid: jid, password: "test", useTLS: false)
xmppConfig.allowInsecure = true
xmppConfig.host = "mremond-mbp.local"
xmppConfig.streamObserver = DefaultStreamObserver()

let client = XMPP(config: xmppConfig)

let semaphore = DispatchSemaphore(value: 0)
client.connect {
  print("Disconnected !")
  semaphore.signal() 
}

print("Connect called")

_ = semaphore.wait(timeout: DispatchTime.distantFuture)
