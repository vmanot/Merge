//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class _AsyncProcessTests: XCTestCase {
    func testEcho() async throws {
        for _ in 0..<10 {
            let process = _AsyncProcess(existingProcess: Process(command: "echo hello"), options: [])
            
            let result: _ProcessResult = try await process.run()
                        
            XCTAssert(result.stdoutString == "hello")
        }
        
        for _ in 0..<10 {
            let process = _AsyncProcess(existingProcess: Process(command: "echo hello"), options: [])
            
            try await process.start()
            
            let result: _ProcessResult = try await process.run()
            
            XCTAssert(result.stdoutString == "hello")
        }
    }
}
