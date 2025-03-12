//
//  AsyncIteration.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

import AsyncAlgorithms

final actor AsyncIteration: Sendable {
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
    func trigger(id: Int, channel triggerChannel: AsyncChannel<Int>) async -> AsyncChannel<(Int, UInt64)> {
        let monitorChannel = AsyncChannel<(Int, UInt64)>()
        Task {
            await withTaskGroup(of: UInt64.self) { group in
                var threads = 0
                for await point in triggerChannel {
                    if point >= 0 {
                        let timeLimit = Int.random(in: 2...6)
                        if threads > 3 {
                            if let value = await group.next() {
                                await monitorChannel.send((id, value))
                            }
                        }
                        group.addTask { [weak self] in
                            if let value = await self?.process(id, point, timeLimit: timeLimit) {
                                return value
                            } else { return 0 as UInt64}
                        }
                        threads += 1
                    } else {
                        triggerChannel.finish()
                    }
                }
                for await value in group {
                    await monitorChannel.send((id, value))
                }
                await monitorChannel.send((-1, 0))
            }
        }
        return monitorChannel
    }
    
    func doIt(n: Int, channel: AsyncChannel<Int>) async {
        for point in 0..<n {
            await channel.send(point)
        }
        // finalize
        await channel.send(-1)
    }
}
