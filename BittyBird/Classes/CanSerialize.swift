//
//  CanSerialize.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Foundation

public protocol CanSerialize {
  associatedtype T: PhxMessage
  associatedtype U
  func encode(msg: T, callback: ((U) -> Void))
  func decode(rawPayload: U, callback: ((T) -> Void))
}
