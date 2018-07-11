//
//  JSONSerializer.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/9/18.
//

/// Encodes and decodes messages using JSON
open class JSONSerializer: Serializer {
  public init() {}

  /**
   Encodes a Message into JSON

   - Parameter msg: Message instance to be packed
   - Parameter callback: Function that accepts JSON with no return value
   */
  open func encode(msg: Message, callback: ((Data) -> Void)) -> Void {
    let body: Dictionary<String, Any> = [
      "topic": msg.topic,
      "event": msg.event,
      "payload": msg.payload,
      "ref": msg.ref,
      "joinRef": msg.joinRef ?? ""
    ]

    do {
      let jsonMsg = try JSONSerialization.data(withJSONObject: body)
      callback(jsonMsg)
    } catch {
      fatalError("Something went wrong while encoding message to JSON: \(error)")
    }
  }

  /**
   Decodes JSON data into a Message

   - Parameter rawPayload: JSON data from server
   - Parameter callback: Function that accepts a Message with no return value
   */
  open func decode(rawPayload: Data, callback: ((Message) -> Void)) -> Void {
    do {
      let decodedData = try JSONSerialization.jsonObject(with: rawPayload)
      let decodedMsg = buildMessageFromData(decodedData: decodedData)
      callback(decodedMsg)
    } catch {
      fatalError("Something went wrong while decoding JSON: \(error)")
    }
  }

  /**
   Takes decoded JSON object and casts it to a Message

   - Parameter decodedData: Unpacked jsonObject
   - Returns: A Message instance
   */
  private func buildMessageFromData(decodedData: Any?) -> Message {
    let castData = decodedData as! Dictionary<String, Any>
    return Message(
      topic: castData["topic"] as? String ?? "",
      event: castData["event"] as? String ?? "",
      payload: castData["payload"] as? Dictionary<String, Any> ?? [:],
      ref: castData["ref"] as? String ?? "",
      joinRef: castData["joinRef"] as? String
    )
  }
}
