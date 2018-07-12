//
//  BBStarscreamSocket.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/12/18.
//

import Starscream

class BBStarscreamSocket: WebSocket, BBWebSocket {
  required init(url: URL) {
    var request = URLRequest(url: url)
    request.timeoutInterval = 5
    super.init(request: request, protocols: nil)
  }
}
