//
//  SocketOptions.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

import Foundation

/// A struct for specifying various options on Socket initialization
public struct SocketOptions {
  public var timeout: Int?
  public var transport: ((URL) -> Any)?
  public var encode: ((_ msg: PhxMessage) -> Any)?
  public var decode: ((_ payload: Any) -> Any)?
  public var heartbeatIntervalSeconds: Int?
  public var reconnectAfterSeconds: ((_ tries: Int) -> Int)?
  public var logger: Any?
  public var params: Dictionary <String, Any>?
}
