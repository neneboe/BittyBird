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
//  public var transport: Any?
  public var heartbeatIntervalSeconds: Int?
  public var reconnectAfterSeconds: ((_ tries: Int) -> Int)?
  public var logger: ((_ kind: String, _ msg: String, _ data: Any) -> Void)?
  public var params: Dictionary <String, Any>?

  public init(
    timeout: Int? = nil,
    heartbeatIntervalSeconds: Int? = nil,
    reconnectAfterSeconds: ((_ tries: Int) -> Int)? = nil,
    logger: ((_ kind: String, _ msg: String, _ data: Any) -> Void)? = nil,
    params: Dictionary <String, Any>? = nil
  ) {
    self.timeout = timeout
    self.heartbeatIntervalSeconds = heartbeatIntervalSeconds
    self.reconnectAfterSeconds = reconnectAfterSeconds
    self.logger = logger
    self.params = params
  }
}
