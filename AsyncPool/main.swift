//
//  main.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

import Foundation

print("Hello, World!")

let a = AsyncIteration()

let t0 = Task {
    let id = 0
    await a.trigger(id: id)
    if let state = StateManagement.shared.states[id] {
        print("ID: \(id), Value: \(state)")
    } else {
        print("ID: \(id), failed")
    }
}

let t1 = Task {
    await a.doIt(id: 0)
}

_ = await [t0.value, t1.value]

print("Bye, World~")
