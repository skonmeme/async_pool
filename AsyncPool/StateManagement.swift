//
//  StateManagement.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

final class StateManagement {
    @MainActor
    static let shared = StateManagement()
    
    // Success & Failure
    var states: [Int: (Int, Int)] = [:]
    var values: [Int: [UInt64]] = [:]
        
    func add(id: Int, value: UInt64) {
        if states[id] == nil {
            states[id] = (0, 0)
            values[id] = []
        }
        if value > 200000000000000000 {
            states[id]!.0 += 1
        } else {
            states[id]!.1 += 1
        }
        values[id]!.append(value)
    }
        
    func printState(id: Int) {
        if states[id] != nil {
            print("ID: \(id), State: \(states[id]!), Value: \(values[id]!)")
        } else {
            print("ID: \(id), failed")
        }
    }
}
