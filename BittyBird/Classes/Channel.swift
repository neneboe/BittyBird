//
//  Channel.swift
//  Pods
//
//  Created by Nick Eneboe on 6/30/18.
//

/// The states of a channel's lifecycle
public enum ChannelState {
  public static let closed = "closed"
  public static let errored = "errored"
  public static let joined = "joined"
  public static let joining = "joining"
  public static let leaving = "leaving"
}

/// Server-side names of channel lifecycle events
public enum ChannelEvent {
  public static let heartbeat = "heartbeat"
  public static let close = "phx_close"
  public static let error = "phx_error"
  public static let join = "phx_join"
  public static let reply = "phx_reply"
  public static let leave = "phx_leave"
}

open class Channel {
  /// Server-side names of channel lifecycle events
  let CHANNEL_LIFECYCLE_EVENTS: Array <String> = [
    ChannelEvent.close, ChannelEvent.error, ChannelEvent.join, ChannelEvent.reply, ChannelEvent.leave
  ]
  /// Current state of the Channel
  var state: String = ChannelState.closed
  /// The topic of the Channel. e.g. "room: lobby"
  let topic: String
  /// The params sent when joining the channel
  var params: Dictionary <String, Any>
  /// The Socket that the channel belongs to
  let socket: Socket
  /// Array of event bindings as named tuples
  var bindings: [(event: String, callback: (Message) -> Void)] = []
  /// Timout when attempting to join a Channel
  var timeout: Int
  /// Set to true once the channel calls .join()
  var joinedOnce: Bool = false
  /// Push to send when the channel calls .join()
  var joinPush: Push!
  /// Buffer of Pushes that will be sent once the Channel's socket connects
  var pushBuffer: Array <Push> = []
  /// Timer to attempt to rejoin
  var rejoinTimer: BBTimer?
  /// The type of Push to use for creating new pushes
  let pushClass: Push.Type

  /**
   Creates a new instance of Channel

   - Parameter topic: Name of the channel to join
   - Parameter params: Optional params to pass along to server on join request
   - Parameter socket: Socket to use for transport
   - Parameter pushClass: Optional type of Push to use for creating new pushes
   - Returns: A new instance of channel
   */
  init(
    topic: String,
    params: Dictionary <String, Any> = [:],
    socket: Socket,
    pushClass: Push.Type = Push.self
  ) {
    self.topic = topic
    self.params = params
    self.socket = socket
    self.timeout = socket.timeout
    self.pushClass = pushClass
    self.joinPush = pushClass.init(
      channel: self, event: ChannelEvent.join, payload: self.params, timeout: self.timeout
    )
    self.rejoinTimer = BBTimer(callback: {
      () -> Void in self.rejoinUntilConnected()
    }, timerCalc: socket.reconnectAfterSeconds)
  }

  /// Keeps trying to rejoin channel on a repeating exponential backoff timer
  open func rejoinUntilConnected() {
    rejoinTimer?.scheduleTimeout()
    if socket.isConnected {
      rejoin()
    }
  }

  /**
   Joins a channel

   - Parameter timeout: Optional duration to wait for a response to the join message
   - Returns: the `joinPush`, the channel's instance of Push used to send join message
  */
  open func join(timeout: Int? = nil) -> Push {
    guard !joinedOnce else {
      fatalError("tried to join multiple times. 'join' can only be called a single time per channel instance")
    }
    joinedOnce = true
    rejoin(timeout: timeout)
    return joinPush
  }

  /// Registers callbacks to be run on the close event
  open func onClose(callback: @escaping ((Message) -> Void)) {
    on(event: ChannelEvent.close, callback: callback)
  }
  /// Registers callbacks to be run on the close event
  open func onError(callback: @escaping ((Message) -> Void)) {
    on(event: ChannelEvent.error, callback: callback)
  }

  /**
   Adds an event binding to the `bindings` list

   - Parameter event: Name of the event to listen for
   - Parameter callback: The function to run when the event occurs
   */
  open func on(event: String, callback: @escaping ((Message) -> Void)) {
    self.bindings.append((event: event, callback: callback))
  }

  /**
   Removes event binding from `bindings` list

   - Parameter: event: Name the the event to remove
   */
  open func off(event: String) {
    bindings = bindings.filter({ !($0.event == event) })
  }

  /// Whether channel is joined and socket is connected
  open var canPush: Bool { get { return socket.isConnected && isJoined }}

  /**
   Push the event with payload to the channel

   - Parameter event: Name of the event
   - Parameter payload: The event data
   - Parameter timeout: Optional duration to wait for a response to the push
   */
  open func push(event: String, payload: Dictionary <String, Any>, timeout: Int? = nil) -> Push {
    guard !joinedOnce else {
      fatalError("tried to push \(event) to \(topic) before joining. Use channel.join() before pushing events.")
    }
    let pushEvent = pushClass.init(channel: self, event: event, payload: payload, timeout: timeout ?? self.timeout)
    if canPush { pushEvent.send() }
    else {
      pushEvent.startTimeout()
      pushBuffer.append(pushEvent)
    }
    return pushEvent
  }

  /**
   Leaves the channel, unsubscibres from server events, and instructs
   channel to terminate on server.
   To receive leave acknowledgements, use the a receive hook to bind to the
   server ack.
   Example:
       channel.leave().receive("ok") { _ in { print("left") }
   - Parameter timeout: Optional timeout
   - Returns: A push to which you can add `receive` hooks
   */
  @discardableResult
  open func leave(timeout: Int? = nil) -> Push {
    state = ChannelState.leaving
    let onClose: ((Message) -> Void) = { [weak self] (msg) in
      self?.socket.log(kind: "channel", msg: "leave \(self?.topic ?? "unknown")")
      self?.trigger(msg: msg)
    }

    let leavePush = pushClass.init(channel: self, event: ChannelEvent.leave, timeout: timeout ?? self.timeout)
    leavePush
      .receive(status: "ok", callback: onClose)
      .receive(status: "timeout", callback: onClose)
    leavePush.send()
    if !canPush { leavePush.trigger(status: "ok", payload: [:]) }
    return leavePush
  }

  /**
   Pushes join channel message to server

   - Parameter timeout: Duration to wait for a response to join message
   */
  open func sendJoin(timeout: Int) {
    self.state = ChannelState.joining
    self.joinPush.resend(timeout: timeout)
  }

  /**
   Rejoins the channel

   - Parameter timeout: Optional duration to wait for a response to the join message
   */
  open func rejoin(timeout: Int? = nil) {
    self.sendJoin(timeout: timeout ?? self.timeout)
  }

  /**
   Triggers an event to the correct event bindings created by `channel.on("event")`.

   - Parameter msg: Instance of Message
   */
  open func trigger(msg: Message) {
//    let handledMessage = self.onMessage(message)
//
//    self.bindings
//      .filter( { return $0.event == message.event } )
//      .forEach( { $0.callback(handledMessage) } )
  }

  open func isMember(msg: Message) -> Bool {
    return true
  }

  open var joinRef: String { get { return joinPush.ref }}

  open var isJoined: Bool { get { return state == ChannelState.joined }}
}
