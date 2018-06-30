//
//  Message.swift
//  Pods
//
//  Created by Nick Eneboe on 6/28/18.
//

import Foundation

/// Encapsulates message properties in format to match Phoenix messages
public struct Message: PhxMessage {
  /// The name of the room or channel
  public var topic: String
  /// The name of the event
  public var event: String
  /// The message data
  public var payload: Dictionary <String, Any>
  /// An id for the message
  public var ref: String
  /// An id from joining a channel
  public var joinRef: String?

  /**
   Initializes a new instance of Message without having to pass a `joinRef` property
   - Parameters:
       - topic: Name of the room or channel
       - event: Name of the event
       - payload: The message data
       - ref: An id for the message
   - Returns: An instance of Message
   */
  init(topic: String, event: String, payload: Dictionary <String, String>, ref: String) {
    self.topic = topic
    self.event = event
    self.payload = payload
    self.ref = ref
    self.joinRef = nil
  }

  /**
   Initializes a new instance of Message
   - Parameters:
       - topic: Name of the channel
       - event: Name of the event
       - payload: The message data
       - ref: An id for the message
       - joinRef: An id from joining a channel
   - Returns: An instance of Message
   */
  init(topic: String, event: String, payload: Dictionary <String, String>, ref: String, joinRef: String) {
    self.topic = topic
    self.event = event
    self.payload = payload
    self.ref = ref
    self.joinRef = joinRef
  }
}
