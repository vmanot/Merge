//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

package class _UnsafePipeBuffer {
    package enum StreamID: String {
        case stdout
        case stderr
    }
    
    internal let pipe = Pipe()
    
    private var buffer: Data = .init()
    private let semaphore = DispatchGroup()
    
    private let id: StreamID
    
    package init(id: StreamID) {
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

#endif
