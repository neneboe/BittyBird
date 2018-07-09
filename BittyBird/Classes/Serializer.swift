//
//  Serializer.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/9/18.
//

public protocol Serializer {
  func encode(msg: Message, callback: ((Data) -> Void))
  func decode(rawPayload: Data, callback: ((Message) -> Void))
}
