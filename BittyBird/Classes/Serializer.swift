//
//  Serializer.swift
//  Pods
//
//  Created by Nick Eneboe on 6/28/18.
//

import Foundation
import SwiftMsgPack

/// Encodes and decodes messages using MessagePack
open class Serializer: CanSerialize {
  // typealiases to make Serializer conform to CanSerialize
  public typealias T = Message
  public typealias U = Data

  /**
   Encodes a Message into MessagePack.Data

   - Parameter msg: Message instance to be packed
   - Parameter callback: Function that accepts MessagePack.Data with no return value
   - Returns: No return value
   */
  public static func encode(msg: Message, callback: ((Data) -> Void)) {
    var encodedMsg = Data()
    do {
      try encodedMsg.pack(
        [
          "topic": msg.topic,
          "event": msg.event,
          "payload": msg.payload,
          "ref": msg.ref,
          "joinRef": msg.joinRef as Any
        ]
      )
    } catch {
      print("Something went wrong while packing data: \(error)")
    }

    callback(encodedMsg)
  }

  /**
   Decodes MessagePack.Data into a Message

   - Parameter rawPayload: Binary data from server
   - Parameter callback: Function that accepts a Message with no return value
   - Returns: No return value
   */
  public static func decode(rawPayload: Data, callback: ((Message) -> Void)) {
    let data: Data = rawPayload
    var decodedMsg: Message?
    var decodedData: Any?
    do {
      decodedData = try data.unpack()
      decodedMsg = self.buildMessageFromData(decodedData: decodedData)
    } catch {
      print("Something went wrong while unpacking data: \(error)")
    }

    callback(decodedMsg!)
  }

  /**
   Takes decoded MessagePack object and casts it to a Message

   - Parameter decodedData: Unpacked MessagePack.Data object
   - Returns: A Message instance
   */
  private static func buildMessageFromData(decodedData: Any?) -> Message {
    var msg: Message
    let castData = decodedData as! Dictionary <String, Any>
    if castData["joinRef"] as? String != nil {
      msg = Message(
        topic: castData["topic"] as! String,
        event: castData["event"] as! String,
        payload: castData["payload"] as! Dictionary <String, String>,
        ref: castData["ref"] as! String,
        joinRef: castData["joinRef"] as! String
      )
    } else {
      msg = Message(
        topic: castData["topic"] as! String,
        event: castData["event"] as! String,
        payload: castData["payload"] as! Dictionary <String, String>,
        ref: castData["ref"] as! String
      )
    }
    return msg
  }
}
