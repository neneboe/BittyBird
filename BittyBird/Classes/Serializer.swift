//
//  Serializer.swift
//  Pods
//
//  Created by Nick Eneboe on 6/28/18.
//

import SwiftMsgPack

/// Encodes and decodes messages using MessagePack
open class Serializer {
  public init() {}

  /**
   Encodes a Message into MessagePack.Data

   - Parameter msg: Message instance to be packed
   - Parameter callback: Function that accepts MessagePack.Data with no return value
   */
  open func encode(msg: Message, callback: ((Data) -> Void)) -> Void {
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
   */
  open func decode(rawPayload: Data, callback: ((Message) -> Void)) -> Void {
    let data: Data = rawPayload
    var decodedMsg: Message?
    var decodedData: Any?
    do {
      decodedData = try data.unpack()
      decodedMsg = buildMessageFromData(decodedData: decodedData)
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
  private func buildMessageFromData(decodedData: Any?) -> Message {
    let castData = decodedData as! Dictionary <String, Any>
    return Message(
      topic: castData["topic"] as! String,
      event: castData["event"] as! String,
      payload: castData["payload"] as! Dictionary <String, Any>,
      ref: castData["ref"] as! String,
      joinRef: castData["joinRef"] as? String
    )
  }
}
