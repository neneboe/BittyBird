//
//  PhxMessage.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Foundation

public protocol PhxMessage {
  var topic: String { get }
  var event: String { get }
  var payload: Dictionary <String, Any> { get }
  var ref: String { get }
}
