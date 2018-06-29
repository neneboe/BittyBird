//
//  Serializer.swift
//  Pods
//
//  Created by Nick Eneboe on 6/28/18.
//

import Foundation
import SwiftMsgPack

/// Encodes and decodes messages using MessagePack
open class Serializer {
  /**
   Encodes a Message into MessagePack.Data

   - Parameter msg: Message instance to be packed
   - Parameter callback: Function that accepts and returns MessagePack.Data
   - Returns: A MessagePack.Data object returned from `callback`
   */
  open class func encode(msg: Message, callback: ((Data) -> Data)) -> Data {
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
    return callback(encodedMsg)
  }

  /**
   Decodes MessagePack.Data into a Message

   - Parameter rawPayload: Binary data from server
   - Parameter callback: Function that accepts and returns a Message
   - Returns: A Message object returned from `callback`
   */
  open class func decode(rawPayload: Data, callback: ((Message) -> Message)) -> Message {
    let data: Data = rawPayload
    var decodedMsg: Message?
    var decodedData: Any?
    do {
      decodedData = try data.unpack()
      decodedMsg = self.buildMessageFromData(decodedData: decodedData)
    } catch {
      print("Something went wrong while unpacking data: \(error)")
    }
    return callback(decodedMsg!)
  }

  /**
   Takes decoded MessagePack object and casts it to a Message

   - Parameter decodedData: Unpacked MessagePack.Data object
   - Returns: A Message instance
   */
  private class func buildMessageFromData(decodedData: Any?) -> Message {
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
