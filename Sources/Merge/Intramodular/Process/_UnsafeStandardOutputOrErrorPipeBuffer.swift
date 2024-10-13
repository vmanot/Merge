//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
package class _UnsafeStandardOutputOrErrorPipeBuffer {
    package let pipe = Pipe()
    private var buffer: Data = .init()
    private let semaphore = DispatchGroup()
    private let id: ID
    
    package init(id: ID) {
        self.id = id
        self.pipe.fileHandleForReading.readabilityHandler = { handler in
            self.semaphore.enter()
            
            let data = handler.availableData
            
            self.buffer.append(contentsOf: data)
            
            self.semaphore.leave()
        }
    }
    
    package func closeReturningData() throws -> Data {
        self.semaphore.wait()
        
        self.pipe.fileHandleForReading.readabilityHandler = nil
        
        let remainingData: Data = try self.pipe.fileHandleForReading.readToEnd() ?? Data()
        let data: Data = self.buffer + remainingData
        
        self.buffer = Data()
        
        return data
    }
}

@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
package actor _UnsafeAsyncStandardOutputOrErrorPipeBuffer {
    package let pipe = Pipe()
    private var buffer: Data = .init()
    private let id: ID
    
    package init(id: ID) {
        self.id = id
        self.pipe.fileHandleForReading.readabilityHandler = { [weak self] handler in
            guard let self = self else {
                return
            }
            
            let data = handler.availableData
            
            Task {
                await self.appendData(data)
            }
        }
    }
    
    private func appendData(_ data: Data) {
        buffer.append(contentsOf: data)
    }
    
    package func closeReturningData() async throws -> Data {
        pipe.fileHandleForReading.readabilityHandler = nil
        
        let remainingData: Data = try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
                
                continuation.resume(returning: data)
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        let data: Data = await withTaskGroup(of: Data.self) { group -> Data in
            group.addTask {
                await self.buffer
            }
            
            group.addTask {
                remainingData
            }
            
            var combinedData = Data()
            
            for await data in group {
                combinedData.append(data)
            }
            
            return combinedData
        }
        
        buffer = Data()
        
        return data
    }
}

@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
extension _UnsafeStandardOutputOrErrorPipeBuffer {
    package enum ID: String {
        case stdout
        case stderr
    }
}

@available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *)
extension _UnsafeAsyncStandardOutputOrErrorPipeBuffer {
    package enum ID: String {
        case stdout
        case stderr
    }
}
