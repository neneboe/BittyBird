//
//  BBWebSocket.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/12/18.
//

import Starscream

public protocol BBWebSocket: WebSocketClient {
  var currentURL: URL { get }
  var delegate: WebSocketDelegate? { get }

  init(url: URL)
}
