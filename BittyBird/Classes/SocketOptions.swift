//
//  SocketOptions.swift
//  Pods
//
//  Created by Nick Eneboe on 6/29/18.
//

/// A struct for specifying various options on Socket initialization
public struct SocketOptions {
  public var timeout: Int?
//  public var transport: Any?
  public let heartbeatIntervalSeconds: Int?
  public let reconnectAfterSeconds: ((_ tries: Int) -> Int)?
  public let logger: ((_ kind: String, _ msg: String, _ data: Any) -> Void)?
  public let params: Dictionary<String, Any>?
  public let serializer: Serializer?
  public var webSocketClass: BBWebSocket.Type?
  public let channelClass: Channel.Type?
  public let pushClass: Push.Type?

  public init(
    timeout: Int? = nil,
    heartbeatIntervalSeconds: Int? = nil,
    reconnectAfterSeconds: ((_ tries: Int) -> Int)? = nil,
    logger: ((_ kind: String, _ msg: String, _ data: Any) -> Void)? = nil,
    params: Dictionary<String, Any>? = nil,
    serializer: Serializer? = nil,
    webSocketClass: BBWebSocket.Type? = nil,
    channelClass: Channel.Type? = nil,
    pushClass: Push.Type? = nil
  ) {
    self.timeout = timeout
    self.heartbeatIntervalSeconds = heartbeatIntervalSeconds
    self.reconnectAfterSeconds = reconnectAfterSeconds
    self.logger = logger
    self.params = params
    self.serializer = serializer
    self.webSocketClass = webSocketClass
    self.channelClass = channelClass
    self.pushClass = pushClass
  }
}
