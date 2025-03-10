//
//  AsyncIteration.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

import AsyncAlgorithms

final actor AsyncIteration {
    @MainActor
    var stateManagement = StateManagement.shared
    
    var channels: [Int: AsyncChannel<Int>] = [:]
}

extension AsyncIteration {
    private func getChannel(_ id: Int) -> AsyncChannel<Int> {
        if channels[id] == nil {
            channels[id] = AsyncChannel<Int>()
        }
        return channels[id]!
    }
}

extension AsyncIteration {
    private nonisolated func process(_ id: Int, _ point: Int, timeLimit: Int) async -> UInt64 {
        let task = Task {
            var count: UInt64 = 0
            var value: UInt64 = 0
            for _ in 0..<1000 {
                // reduce number of checking
                if Task.isCancelled { break }
                for _ in UInt64(0)..<UInt64(10_000_000) {
                    value += 1
                    count += value
                    if count > 499999999500000000 {
                        count = 0
                    }
                }
            }
            return count
        }
        let controller = Task {
            try await Task.sleep(nanoseconds: UInt64(timeLimit) * 1_000_000_000)
            task.cancel()
        }
        
        // Wait for the task to complete
        let count = await task.value
        controller.cancel()
        
        print("ID: \(id), Point: \(point), TimeLimt: \(timeLimit), Count: \(count)")
        return count
    }
}

extension AsyncIteration {
    func trigger(id: Int) async {
        let channel = getChannel(id)
        await withTaskGroup(of: UInt64.self) { [weak self] group in
            var threads = 0
            for await point in channel {
                if point >= 0 {
                    let timeLimit = Int.random(in: 2...6)
                    if threads > 3 {
                        if let value = await group.next() {
                            await self?.stateManagement.add(id: id, value: value)
                        }
                    }
                    group.addTask {
                        guard let value = await self?.process(id, point, timeLimit: timeLimit) else { return 0 as UInt64 }
                        return value
                    }
                    threads += 1
                } else {
                    channel.finish()
                }
            }
            for await value in group {
                await self?.stateManagement.add(id: id, value: value)
            }
        }
        channels[id] = nil
    }
    
    func doIt(id: Int) async {
        let channel = getChannel(id)
        for point in 0..<10 {
            await channel.send(point)
        }
        // finalize
        await channel.send(-1)
    }
}
