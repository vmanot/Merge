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
    
    /// This test verifies that `_AsyncProcess` correctly handles long-running processes that have periods of silence
    /// (no stdout/stderr output).
    ///
    /// Context:
    /// `_AsyncProcess` has a built-in interrupt mechanism in `_readStdoutStderrUntilEnd()` that interrupts a process
    /// if it doesn't produce output for a certain duration. This is controlled by the timeout in the `interruptLater()`
    /// function where a `DispatchWorkItem` is scheduled with asyncAfter. The current timeout is `300` seconds.
    ///
    /// Failure Check:
    /// - With the current timeout (300s), the test should pass as the process completes in 5s.
    /// - To verify the interrupt mechanism, modify `_AsyncProcess.swift` and update the 300 second timeout to less than 5 seconds.
    /// - The test should fail as the process will be interrupted before it can output "done".
    func testLongSilentProcessInterrupt() async throws {
        let command = "sleep 5 && echo done"
        let process = try await _AsyncProcess(command: command, options: [])
        let result = try await process.run()
        
        // If the process was interrupted, we wouldn't get "done" as output
        XCTAssertEqual(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines), "done")
    }
}
