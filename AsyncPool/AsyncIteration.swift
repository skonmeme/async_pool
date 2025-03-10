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
    private nonisolated func process(_ id: Int, _ point: Int) async -> UInt64 {
        var count: UInt64 = 0
        for i in UInt64(0)..<UInt64(10_000_000_000) {
            count += i
            if count > 499999999500000000 {
                count = 0
            }
        }
        return count
    }

    func trigger(id: Int) async {
        let channel = getChannel(id)
        let result = await withTaskGroup(of: UInt64.self, returning: UInt64.self) { [weak self] group in
            var threads = 0
            var result: UInt64 = 0
            for await point in channel {
                if point >= 0 {
                    if threads > 3 {
                        if let value = await group.next() {
                            result += value
                        }
                    }
                    group.addTask {
                        guard let value = await self?.process(id, point) else { return 0 as UInt64 }
                        return value
                    }
                    threads += 1
                } else {
                    channel.finish()
                }
            }
            for await value in group {
                result += value
            }
            return result
        }
        await stateManagement.add(id: id, value: result)
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
