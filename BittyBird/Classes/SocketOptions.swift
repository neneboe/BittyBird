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
  public var encode: Any & CanSerialize

//  this.encode = opts.encode || this.defaultEncoder
//  this.decode = opts.decode || this.defaultDecoder
//  this.heartbeatIntervalMs  = opts.heartbeatIntervalMs || 30000
//  this.reconnectAfterMs     = opts.reconnectAfterMs || function(tries){
//  return [1000, 2000, 5000, 10000][tries - 1] || 10000
//  }
//  this.logger               = opts.logger || function(){} // noop
//  this.params               = opts.params || {}
}
