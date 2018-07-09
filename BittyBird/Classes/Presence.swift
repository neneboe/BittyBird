//
//  Presence.swift
//  BittyBird
//
//  Created by Nick Eneboe on 7/6/18.
//

// Looks like ["joins": ["uid1": ["metas": [["name": "Nick", "someProp": true]]]], "leaves": ...]
public typealias PresenceDiff = Dictionary<String, PresenceState>

// Looks like ["uid1": ["metas": [["name": "Nick", "someProp": true]]], "uid2": ...]
public typealias PresenceState = Dictionary<String, Dictionary<String, Any>>

/** Looks like
 [
   ["metas": [["name": "Nick", "phx_ref": "1"], ...], "userInfo": "blah"],
   ["metas": [["name": "Nicole", "phx_ref": "2"], ...]],
   ...
 ]
 */
public typealias PresenceList = Array<Dictionary<String, Any>>

// Looks like ["metas": [["name": "Nick", "someProp": true]]
public typealias PresenceInfo = Dictionary<String, PresenceMetas>

// Metas are stored in an array because a user may be online from more than one device simultaneously
/** Looks like
 [
   ["name": "Nick", "someProp": true, "phx_ref": "someRef", ...],
   ["name": "Nick", "someProp": false, "phx_ref": "someDifferentRef", ...],
   ...
 ]
 */
public typealias PresenceMetas = Array<Dictionary<String, Any>>

open class Presence {
  open class func syncState(
    currentState: PresenceState,
    newState: PresenceState,
    onJoin: ((String, PresenceInfo?, PresenceInfo) -> Void) = { (_, _, _) in () },
    onLeave: ((String, PresenceInfo, PresenceInfo) -> Void) = { (_, _, _) in () }
  ) -> PresenceState {
    var joins: PresenceState = [:]
    var leaves: PresenceState = [:]
    
    currentState.forEach { (key, presence) in
      if newState[key] == nil {
        leaves[key] = presence
      }
    }
    newState.forEach { (key, newPresence) in
      if let currentPresence = currentState[key] {
        let newPresenceMetas = newPresence["metas"] as? PresenceMetas ?? []
        let currentPresenceMetas = currentPresence["metas"] as? PresenceMetas ?? []
        let newRefs: Array<String> = newPresenceMetas.map({ $0["phx_ref"] as! String })
        let curRefs: Array<String> = currentPresenceMetas.map({ $0["phx_ref"] as! String })
        let joinedMetas: PresenceMetas = newPresenceMetas.filter({ (meta) -> Bool in
          !curRefs.contains(meta["phx_ref"] as! String)
        })
        let leftMetas: PresenceMetas = currentPresenceMetas.filter({ (meta) -> Bool in
          !newRefs.contains(meta["phx_ref"] as! String)
        })
        if !joinedMetas.isEmpty {
          joins[key] = newPresence
          joins[key]!["metas"] = joinedMetas
        }
        if !leftMetas.isEmpty {
          leaves[key] = currentPresence
          leaves[key]!["metas"] = leftMetas
        }
      } else {
        joins[key] = newPresence
      }
    }

    let diffMsg = Message(payload: ["joins": joins, "leaves": leaves])
    return syncDiff(currentState: currentState, diffMsg: diffMsg, onJoin: onJoin, onLeave: onLeave)
  }

  open class func syncDiff(
    currentState: PresenceState,
    diffMsg: Message,
    onJoin: ((String, PresenceInfo?, PresenceInfo) -> Void) = { (_, _, _) in () },
    onLeave: ((String, PresenceInfo, PresenceInfo) -> Void) = { (_, _, _) in () }
  ) -> PresenceState {
    var state = currentState
    let diffPayload = diffMsg.payload as! PresenceDiff
    let joins = diffPayload["joins"]
    let leaves = diffPayload["leaves"]

    joins?.forEach({ (key, newPresence) in
      let currentPresence = state[key]
      state[key] = newPresence
      if currentPresence != nil {
        var stateMetas = state[key]!["metas"] as! PresenceMetas
        (currentPresence!["metas"] as! PresenceMetas).forEach({
          print($0)
          stateMetas.insert($0, at: 0)
        })
        state[key]!["metas"] = stateMetas
      }
      onJoin(key, (currentPresence as? PresenceInfo), state[key] as! PresenceInfo)
    })

    leaves?.forEach({ (key, leftPresence) in
      guard var currentPresence = state[key] else { return }
      let refsToRemove = (leftPresence["metas"] as! PresenceMetas).map({ $0["phx_ref"] as! String })
      currentPresence["metas"] = (currentPresence["metas"] as! PresenceMetas).filter({
        !refsToRemove.contains($0["phx_ref"] as! String)
      })
      onLeave(key, currentPresence as! PresenceInfo, leftPresence as! PresenceInfo)
      state[key] = currentPresence
      if (currentPresence["metas"] as! PresenceMetas).isEmpty { state.removeValue(forKey: key) }
    })

    return state
  }

  open class func list(
    presences: PresenceState,
    chooser: ((String, Dictionary<String, Any>) -> Dictionary<String, Any>)
      = { (key, pres) -> Dictionary<String, Any> in return pres }
  ) -> PresenceList {
    var presenceList: PresenceList = []
    presences.forEach { (key, presence) in
      presenceList.append(chooser(key, presence))
    }
    return presenceList
//    return this.map(presences, (key, presence) => {
//      return chooser(key, presence)
//      })
  }
}
