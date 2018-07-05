//
//  Push.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/2/18.
//

open class Push {
  /// The channel
  let channel: Channel
  /// The name of the event, e.g. "join"
  let event: String
  /// The payload, e.g. ["user_id": "abc123"]
  var payload: Dictionary <String, Any>
  /// The push timeout, in seconds
  var timeout: Int
  /// Server's response to the push
  var receivedResp: Message? = nil
  /// Timer which triggers a timeout event
  var timeoutTimer: Timer? = nil
  /// Hooks into a Push. Where .receive("ok", callback(Payload)) are stored
  var recHooks: Array <Dictionary <String, ((Message) -> ())>> = []
  /// Whether message has been sent
  var sent = false

  init(channel: Channel, event: String, payload: Dictionary <String, Any> = [:], timeout: Int) {
    self.channel = channel
    self.event = event
    self.payload = payload
    self.timeout = timeout
  }

  open func send() {

  }

  open func startTimeout() {
    
  }

  open func resend(timeout: Int) {
    
  }
}
