//
//  StateManagement.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

final class StateManagement {
    @MainActor
    static let shared = StateManagement()
    
    var states: [Int: [UInt64]] = [:]
    
    func add(id: Int, value: UInt64) async {
        if states[id] == nil {
            states[id] = []
        }
        states[id]!.append(value)
    }
}
