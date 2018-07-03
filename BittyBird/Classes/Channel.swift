//
//  Channel.swift
//  Pods
//
//  Created by Nick Eneboe on 6/30/18.
//

import Foundation

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
  /// Collection of event bindings
  var bindings: [(event: String, ref: Int, callback: (Message) -> Void)] = []
  /// Timout when attempting to join a Channel
  var timeout: Int
  /// Set to true once the channel calls .join()
  var joinedOnce: Bool = false
  /// Push to send when the channel calls .join()
  var joinPush: Push
  /// Buffer of Pushes that will be sent once the Channel's socket connects
  var pushBuffer: Array <Push> = []
  /// Timer to attempt to rejoin
  var rejoinTimer: BBTimer?

  /**
   Creates a new instance of Channel

   - Parameter msg: Instance of Message
   */
  init(topic: String, params: Dictionary <String, Any>, socket: Socket) {
    self.topic = topic
    self.params = params
    self.socket = socket
    self.timeout = socket.timeout
    self.joinPush = Push()
    self.rejoinTimer = BBTimer(callback: {
      self.rejoinTimer?.scheduleTimeout()
      if socket.isConnected { self.rejoin() }
    }, timerCalc: socket.reconnectAfterSeconds)
  }

  open func rejoin() {

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
}
