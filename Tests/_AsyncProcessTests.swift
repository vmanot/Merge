//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Swallow
import XCTest

final class _AsyncProcessTests: XCTestCase {
    func testEcho() async throws {
        for _ in 0..<10 {
            let process = try _AsyncProcess(existingProcess: Process(command: "echo hello"), options: [])
            
            let result: Process.RunResult = try await process.run()
            
            XCTAssert(result.stdoutString == "hello")
        }
        
        for _ in 0..<10 {
            let process = try _AsyncProcess(existingProcess: Process(command: "echo hello"), options: [])
            
            try await process.start()
            
            let result: Process.RunResult = try await process.run()
            
            XCTAssert(result.stdoutString == "hello")
        }
    }
    
    func testFoo() async throws {
        let process = try await _AsyncProcess(
            command: "echo Hello",
            options: [._forwardStdoutStderr]
        )
        
        let result = try await process.run()
        
        XCTAssertEqual(result.stdoutString!, "Hello")
    }
}
