//
//  PresenceTests.swift
//  BittyBird_Tests
//
//  Created by Nick Eneboe on 7/6/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
@testable import BittyBird

class PresenceSpec: QuickSpec {
  override func spec() {
    describe("A Presence") {
      let fixtures: PresenceDiff = [
        "joins": ["u1": ["metas": [["id": 1, "phx_ref": "1.2"]]]],
        "leaves": ["u2": ["metas": [["id": 2, "phx_ref": "2"]]]],
        "state": [
          "u1": ["metas": [["id": 1, "phx_ref": "1"]]],
          "u2": ["metas": [["id": 2, "phx_ref": "2"]]],
          "u3": ["metas": [["id": 3, "phx_ref": "3"]]]
        ]
      ]

      describe("#syncState") {
        it("syncs empty state") {
          var state: PresenceState = [:]
          let newState: PresenceState = ["uid1": ["metas": [["id": 1, "phx_ref": "1"]]]]
          state = Presence.syncState(currentState: state, newState: newState)
          expect(state as NSDictionary) == newState as NSDictionary
        }

        it("onJoins new presences and onLeave's left presences") {
          let newState = fixtures["state"]!
          var state: PresenceState = ["u4": ["metas": [["id": 4, "phx_ref": "4"]]]]
          var joined: PresenceState = [:]
          var left: PresenceState = [:]
          let onJoin = { (key, current, newPres) -> Void in
            joined[key] = ["current": current, "newPres": newPres]
          }
          let onLeave = { (key, current, leftPres) -> Void in
            left[key] = ["current": current, "leftPres": leftPres]
          }

          state = Presence.syncState(
            currentState: state, newState: newState, onJoin: onJoin, onLeave: onLeave
          )
          expect(state as NSDictionary) == newState as NSDictionary

          let expectedJoined = [
            "u1": ["current": nil, "newPres": ["metas": [["id": 1, "phx_ref": "1"]]]],
            "u2": ["current": nil, "newPres": ["metas": [["id": 2, "phx_ref": "2"]]]],
            "u3": ["current": nil, "newPres": ["metas": [["id": 3, "phx_ref": "3"]]]]
          ]
          let expectedLeft = [
            "u4": ["current": ["metas": []], "leftPres": ["metas": [["id": 4, "phx_ref": "4"]]]]
          ]
          expect(joined as NSDictionary) == expectedJoined as NSDictionary
          expect(left as NSDictionary) == expectedLeft as NSDictionary
        }

        it("onJoins only newly added metas") {
          let newState = ["u3": ["metas": [["id": 3, "phx_ref": "3"], ["id": 3, "phx_ref": "3.new"]]]]
          var state: PresenceState = ["u3": ["metas": [["id": 3, "phx_ref": "3"]]]]
          var joined: PresenceState = [:]
          var left: PresenceState = [:]
          let onJoin = { (key, current, newPres) -> Void in
            joined[key] = ["current": current, "newPres": newPres]
          }
          let onLeave = { (key, current, leftPres) -> Void in
            left[key] = ["current": current, "leftPres": leftPres]
          }
          state = Presence.syncState(
            currentState: state, newState: newState, onJoin: onJoin, onLeave: onLeave
          )
          expect(state as NSDictionary) == newState as NSDictionary
          let expectedJoined = [
            "u3": ["current": ["metas": [["id": 3, "phx_ref": "3"]]],
                   "newPres": ["metas": [["id": 3, "phx_ref": "3"], ["id": 3, "phx_ref": "3.new"]]]]
          ]
          expect(joined as NSDictionary) == expectedJoined as NSDictionary
        }
      }

      describe("#syncDiff") {
        it("syncs empty state") {
          let state: PresenceState = [:]
          let joins = ["uid1": ["metas": [["id": 1, "phx_ref": "1"]]]]
          let diffMsg = Message(payload: [
            "joins": joins,
            "leaves": [:]
          ])
          let newState = Presence.syncDiff(currentState: state, diffMsg: diffMsg)
          expect(newState as NSDictionary) == joins as NSDictionary
        }

        it("removes presence when meta is empty and adds additional meta") {
          var state = fixtures["state"]
          let diffMsg = Message(payload: ["joins": fixtures["joins"]!, "leaves": fixtures["leaves"]!])
          state = Presence.syncDiff(currentState: state!, diffMsg: diffMsg)
          let expectedState = [
            "u1": ["metas": [["id": 1, "phx_ref": "1"], ["id": 1, "phx_ref": "1.2"]]],
            "u3": ["metas": [["id": 3, "phx_ref": "3"]]]
          ]
          expect(state as NSDictionary?) == expectedState as NSDictionary
        }

        it("removes meta while leaving key if other metas exist") {
          var state: PresenceState = [
            "u1": ["metas": [["id": 1, "phx_ref": "1"], ["id": 1, "phx_ref": "1.2"]]]
          ]
          let diffMsg = Message(
            payload: ["joins": [:], "leaves": ["u1": ["metas": [["id": 1, "phx_ref": "1"]]]]]
          )
          state = Presence.syncDiff(currentState: state, diffMsg: diffMsg)
          let expectedState = ["u1": ["metas": [["id": 1, "phx_ref": "1.2"]]]]
          expect(state as NSDictionary) == expectedState as NSDictionary
        }

        describe("callbacks") {
          var onJoinCalledWith: Array<String>!
          var onLeaveCalledWith: Array<String>!
          let onJoinCallback = { (key, _: PresenceInfo?, _: PresenceInfo) in
            onJoinCalledWith.append(key)
          }
          let onLeaveCallback = { (key, _: PresenceInfo, _: PresenceInfo) in
            onLeaveCalledWith.append(key)
          }

          beforeEach {
            onJoinCalledWith = []
            onLeaveCalledWith = []
          }

          context("when joins is not empty") {
            it("triggers onJoin callback") {
              let state: PresenceState = [:]
              let joins = ["uid1": ["metas": [["id": 1, "phx_ref": "1"]]]]
              let diffMsg = Message(payload: ["joins": joins, "leaves": [:]])
              let _ = Presence.syncDiff(currentState: state, diffMsg: diffMsg, onJoin: onJoinCallback)
              expect(onJoinCalledWith as NSArray) == ["uid1"] as NSArray
              expect(onLeaveCalledWith).to(beEmpty())
            }
          }
          context("when leaves is not empty") {
            it("triggers onLeave callback") {
              let leaves = ["uid1": ["metas": [["id": 1, "phx_ref": "1"]]]]
              let state: PresenceState = leaves
              let diffMsg = Message(payload: ["joins": [:], "leaves": leaves])
              let _ = Presence.syncDiff(currentState: state, diffMsg: diffMsg, onLeave: onLeaveCallback)
              expect(onJoinCalledWith).to(beEmpty())
              expect(onLeaveCalledWith as NSArray) == ["uid1"] as NSArray
            }
          }
        }
      }

      describe("#list") {
        it("lists full presence by default") {
          let state = fixtures["state"]!
          let expectedList = [
            ["metas": [["id": 1, "phx_ref": "1"]]],
            ["metas": [["id": 2, "phx_ref": "2"]]],
            ["metas": [["id": 3, "phx_ref": "3"]]]
          ]
          let list = Presence.list(presences: state)
          expect(list as NSArray) == expectedList as NSArray
        }

        it("lists with custom function") {
          let state = ["u1": ["metas": [
            ["id": 1, "phx_ref": "1.first"],
            ["id": 1, "phx_ref": "1.second"]
          ]]]

          let listBy = { (key: String, presence: Dictionary<String, Any>) -> Dictionary<String, Any> in
            return (presence["metas"] as! Array).first!
          }

          let list = Presence.list(presences: state, chooser: listBy)
          expect(list as NSArray) == [["id": 1, "phx_ref": "1.first"]] as NSArray
        }
      }
    }
  }
}
