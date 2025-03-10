//
//  temp.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

//
//  AsyncIteration.swift
//  AsyncPool
//
//  Created by Sung Gon Yi on 3/7/25.
//

import AsyncAlgorithms

final class AsyncIterationBAK {
    //@MainActor
    //let states = StateManagement()

    var channels: [Int: AsyncChannel<Int>] = [:]

    private func getChannel(_ id: Int) -> AsyncChannel<Int> {
        if channels[id] == nil {
            channels[id] = AsyncChannel<Int>()
        }
        return channels[id]!
    }
    
    private func process(_ id: Int, _ point: Int) async -> UInt64 {
        var count: UInt64 = 0
        for i in UInt64(0)..<UInt64(10_000_000_000) {
            if Task.isCancelled {
                print("\(id) cancelled")
                return 0 as UInt64
            }
            count += i
            if count > 499999999500000000 {
                count = 0
            }
        }
        let p = String(format: "%2d", point)
        print("ID: \(id), Point: \(p), Value: \(count)")
        return count
    }

    func trigger(id: Int) async -> [UInt64] {
        let channel = getChannel(id)
        let result = await withTaskGroup(of: UInt64.self, returning: [UInt64].self) { [weak self] group in
            var threads = 0
            var result: [UInt64] = []
            for await point in channel {
                if point >= 0 {
                    if threads > 3 {
                        if let value = await group.next() {
                            result.append(value)
                        }
                    }
                    group.addTask {
                        guard let value = await self?.process(id, point) else { return 0 as UInt64 }
                        return value
                        //await Task.detached {
                        //    guard let value = await self?.process(id, point) else { return 0 as UInt64 }
                        //    return value
                        //}.result.get()
                    }
                    threads += 1
                } else {
                    channel.finish()
                }
            }
            for await value in group {
                result.append(value)
            }
            return result
        }
        channels[id] = nil
        return result
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
