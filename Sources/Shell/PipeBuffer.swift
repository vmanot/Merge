//
// Copyright (c) Vatsal Manot
//

import Foundation

class PipeBuffer {
    enum StreamID: String {
        case stdOut, stdErr
    }
    
    internal let pipe = Pipe()
    private var buffer: Data = .init()
    private let semaphore = DispatchGroup()
    
    let id: StreamID
    init(id: StreamID) {
        self.id = id
        
        self.pipe.fileHandleForReading.readabilityHandler = { handler in
            self.semaphore.enter()
            let data = handler.availableData
            self.buffer.append(contentsOf: data)
            self.semaphore.leave()
        }
    }
    
    func closeReturningData() -> Data {
        self.semaphore.wait()
        
        self.pipe.fileHandleForReading.readabilityHandler = nil
        let remainingData = try! self.pipe.fileHandleForReading.readToEnd() ?? Data()
        
        let data = self.buffer + remainingData
        self.buffer = Data()
        return data
    }
}
