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
  /// The reference ID of the Push
  var ref: String
  /// The event that is associated with the reference ID of the Push
  var refEvent: String? = nil

  // Init is `required` so Push class can be dependency-injected on Channel initialization
  required public init(channel: Channel, event: String, payload: Dictionary <String, Any> = [:], timeout: Int) {
    self.channel = channel
    self.event = event
    self.payload = payload
    self.timeout = timeout
    self.ref = ""
  }

  open func send() {
    guard !hasReceived(status: "timeout") else { return }
    startTimeout()
    sent = true
    let msg = Message(topic: channel.topic, event: event, payload: payload, ref: ref, joinRef: channel.joinRef)
    channel.socket.push(msg: msg)
  }

  @discardableResult
  open func receive(status: String, callback: @escaping ((Message) -> Void)) -> Push {
    return self
  }

  open func reset() {
//    self.cancelRefEvent()
    self.ref = ""
//    self.refEvent = nil
//    self.receivedMessage = nil
    self.sent = false
  }

  open func startTimeout() {

  }

  open func resend(timeout: Int) {

  }

  /// Checks if a status has already been received by the Push.
  ///
  /// - parameter status: Status to check
  /// - return: True if given status has been received by the Push.
  open func hasReceived(status: String) -> Bool {
    return false
    //    guard
    //      let receivedStatus = self.receivedResp?.status,
    //      receivedStatus == status
    //      else { return false }
    //
    //    return true
  }

  /// Triggers an event to be sent though the Channel
  open func trigger(status: String, payload: Dictionary <String, Any>) {
    /// If there is no ref event, then there is nothing to trigger on the channel
    guard refEvent != nil else { return }

    var mutPayload = payload
    mutPayload["status"] = status

    let msg = Message(payload: mutPayload, ref: refEvent!)
    self.channel.trigger(msg: msg)
  }
}
