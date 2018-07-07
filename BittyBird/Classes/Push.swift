//
//  Push.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/2/18.
//

/// Encapsulates the actions associated with pushing messages to server
open class Push {
  /// The channel the push came from
  let channel: Channel
  /// The name of the event, e.g. "join"
  let event: String
  /// The payload, e.g. ["user_id": "abc123"]
  var payload: Dictionary<String, Any>
  /// The push timeout, in seconds
  var timeout: Int
  /// Server's response to the push
  var receivedResp: Message? = nil
  /// Timer which triggers a timeout event
  var timeoutTimer: Timer? = nil
  /// Stores bindings of callbacks to be run when their correspondig statuses are received
  var recHooks: [(status: String, callback: (Message) -> Void)] = []
  /// Whether message has been sent
  var sent = false
  /// The reference ID of the Push
  var ref: String
  /// The event that is associated with the reference ID of the Push
  var refEvent: String? = nil

  /**
   Makes a new instance of Push

   - Parameter channel: The channel the push came from
   - Parameter event: The name of the event
   - Parameter payload: Optional parameter of the push's data
   - Parameter timeout: Number of seconds to wait before push is timed out
   - Returns: A new instance of Push
   */
  // Init is `required` so Push class can be dependency-injected on Channel initialization
  required public init(channel: Channel, event: String, payload: Dictionary<String, Any> = [:], timeout: Int) {
    self.channel = channel
    self.event = event
    self.payload = payload
    self.timeout = timeout
    self.ref = ""
  }

  /**
   Attempts to resend message

   - Parameter timeout: Number of seconds to wait before push has timed out
   */
  open func resend(timeout: Int) {
    self.timeout = timeout
    reset()
    send()
  }

  /// Sends push over channel's socket
  open func send() {
    guard !hasReceived(status: "timeout") else { return }
    startTimeout()
    sent = true
    let msg = Message(topic: channel.topic, event: event, payload: payload, ref: ref, joinRef: channel.joinRef)
    channel.socket.push(msg: msg)
  }

  /**
   Adds binding to `recHooks` of callback that will be run when corresponding
   status is received. Also runs callback immediately is the push has
   already received a responsing with a matching status
   */
  @discardableResult
  open func receive(status: String, callback: @escaping ((Message) -> Void)) -> Push {
    if hasReceived(status: status) { callback(self.receivedResp!) }
    recHooks.append((status: status, callback: callback))
    return self
  }

  /// Changes push back to initial state
  open func reset() {
    self.cancelRefEvent()
    self.ref = ""
    self.refEvent = nil
    self.receivedResp = nil
    self.sent = false
  }

  /**
   Finds all bindings with the passed in `status` and runs each of their
   callbacks, passing in the passed in msg

   - Parameter status: The status to match against
   - Parameter msg: The instance of Message passed to the found callbacks
   */
  open func matchReceive(status: String, msg: Message) {
    recHooks.filter({ $0.status == status }).forEach({ $0.callback(msg) })
  }

  /// Reverses the result on channel.on(ChannelEvent, callback) that spawned the Push
  open func cancelRefEvent() {
    guard refEvent != nil else { return }
    channel.off(event: refEvent!)
  }

  /// Invalidates and resets `timeoutTimer`
  open func cancelTimeout() {
    timeoutTimer?.invalidate()
    timeoutTimer = nil
  }

  /// Sets the push refs, registers bindings with channel to listen for
  /// `refEvent`, and starts timer that will trigger a timeout
  open func startTimeout() {
    if timeoutTimer != nil { cancelTimeout() }
    ref = channel.socket.makeRef()
    refEvent = channel.replyEventName(ref: ref)

    channel.on(event: refEvent!) { (msg) in
      self.cancelRefEvent()
      self.cancelTimeout()
      self.receivedResp = msg
      guard let status = msg.payload["status"] else { return }
      self.matchReceive(status: status as! String, msg: msg)
    }

    timeoutTimer = Timer.scheduledTimer(
      timeInterval: TimeInterval(timeout),
      target: self,
      selector: #selector(onTimeoutTriggered),
      userInfo: nil, repeats: false
    )
  }

  /// Checks if a status has already been received by the Push.
  ///
  /// - parameter status: Status to check
  /// - return: True if given status has been received by the Push.
  open func hasReceived(status: String) -> Bool {
    guard receivedResp?.payload["status"] != nil else { return false }
    return receivedResp?.payload["status"] as! String == status
  }

  /**
   Triggers an event on the `channel`

   - Parameter status: The status to pass along in a messages payload to channel.trigger
   - Parameter payload: Used as the payload in the message sent to channel.trigger
   */
  open func trigger(status: String, payload: Dictionary<String, Any>) {
    /// If there is no ref event, then there is nothing to trigger on the channel
    guard refEvent != nil else { return }

    var mutPayload = payload
    mutPayload["status"] = status

    let msg = Message(payload: mutPayload, ref: refEvent!)
    self.channel.trigger(msg: msg)
  }

  /// Called when `timeoutTimer` goes off. Triggers a timeout
  @objc func onTimeoutTriggered() {
    self.trigger(status: "timeout", payload: [:])
  }
}
