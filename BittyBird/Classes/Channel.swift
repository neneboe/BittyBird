//
//  Channel.swift
//  Pods
//
//  Created by Nick Eneboe on 6/30/18.
//

import Foundation

open class Channel {
  /// Triggers an event to the correct event bindings created by `channel.on("event")`.
  ///
  /// - parameter event: Event to trigger
  /// - parameter payload: Payload of the event
  /// - parameter ref: Ref of the event
  /// - parameter joinRef: Ref of the join event. Defaults to nil
  open func trigger(msg: Message) {
//    let handledMessage = self.onMessage(message)
//
//    self.bindings
//      .filter( { return $0.event == message.event } )
//      .forEach( { $0.callback(handledMessage) } )
  }
}
