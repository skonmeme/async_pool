//
//  main.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

import AsyncAlgorithms
import Foundation

print("Hello, World!")

let a = AsyncIteration()
let triggerChannel = AsyncChannel<Int>()

let t0 = Task {
    let id = 0
    let monitorChannel = await a.trigger(id: id, channel: triggerChannel)
    for await value in monitorChannel {
        if value.0 >= 0 {
            StateManagement.shared.add(id: value.0, value: value.1)
        } else {
            monitorChannel.finish()
        }
    }
    if let state = StateManagement.shared.states[id], let values = StateManagement.shared.values[id] {
        print("ID: \(id), State: \(state), Value: \(values)")
    } else {
        print("ID: \(id), failed")
    }
}

let t1 = Task {
    await a.doIt(n: 50, channel: triggerChannel)
}

_ = await [t0.value, t1.value]

print("Bye, World~")
