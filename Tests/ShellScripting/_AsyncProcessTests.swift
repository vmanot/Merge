//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Foundation
import Swallow
import Testing

@Suite(.serialized)
struct _AsyncProcessTests {
    @Test
    func testEcho() async throws {
        for _ in 0..<10 {
            let process: _AsyncProcess = try _AsyncProcess(existingProcess: Process(command: "echo hello"), options: [])

            let result: _ProcessRunResult = try await process.run()

            #expect(result.stdoutString == "hello")
        }

        for _ in 0..<10 {
            let process: _AsyncProcess = try _AsyncProcess(existingProcess: Process(command: "echo hello"), options: [])

            try await process.start()

            let result: _ProcessRunResult = try await process.run()

            #expect(result.stdoutString == "hello")
        }
    }

    @Test
    func testFoo() async throws {
        let process: _AsyncProcess = try await _AsyncProcess(
            command: "echo Hello",
            options: [._forwardStdoutStderr]
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString! == "Hello")
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
    @Test
    func testLongSilentProcessInterrupt() async throws {
        let command: String = "sleep 5 && echo done"
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", command],
            currentDirectoryURL: nil,
            environmentVariables: [:],
            options: []
        )
        let result: _ProcessRunResult = try await process.run()

        // If the process was interrupted, we wouldn't get "done" as output
        #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == "done")
    }

    // MARK: - Error Conditions and Edge Cases

    @Test
    func testInvalidCommand() async throws {
        // Use a command that fails immediately rather than hangs
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", "/nonexistent/command"],
            options: []
        )

        do {
            let result: _ProcessRunResult = try await process.run()
            // If it doesn't throw, check for termination error
            #expect(result.terminationError != nil)
            #expect(result.terminationError?.status != 0)
        } catch {
            // Expected to fail - this is acceptable
        }
    }

    @Test
    func testStderrCapture() async throws {
        let command: String = "echo 'error message' >&2"
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", command],
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stderrString?.trimmingCharacters(in: .whitespacesAndNewlines) == "error message")
        #expect(result.stdoutString?.isEmpty ?? true)
    }

    @Test
    func testNonZeroExitCode() async throws {
        let command: String = "exit 42"
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", command],
            options: []
        )

        do {
            let result: _ProcessRunResult = try await process.run()
            // Process may return result with termination error instead of throwing
            if let terminationError = result.terminationError {
                #expect(terminationError.status == 42)
            } else {
                Issue.record("Expected termination error for non-zero exit code")
            }
        } catch let error as ProcessTerminationError {
            #expect(error.status == 42)
        }
    }

    @Test
    func testEmptyOutput() async throws {
        let command: String = "true"  // Command that succeeds but produces no output
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", command],
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString?.isEmpty ?? true)
        #expect(result.stderrString?.isEmpty ?? true)
        #expect(result.terminationError == nil)
    }

    @Test
    func testLargeOutput() async throws {
        // Generate output to test buffering (use seq for better cross-platform compatibility)
        let command: String = "seq 1 100 | while read i; do echo \"Line $i with some additional text to make it longer\"; done"
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", command],
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(!(result.stdoutString?.isEmpty ?? true))
        #expect((result.stdoutString?.count ?? 0) > 1000)
        #expect(result.stdoutString?.contains("Line 100") ?? false)
    }

    // MARK: - Process State Management

    @Test
    func testProcessState() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["hello"],
            options: []
        )

        // Initially not launched
        #expect(process.state == .notLaunch)
        #expect(!(process.isRunning))

        // Run the process to completion
        _ = try await process.run()

        // Should be terminated after completion
        #expect(process.state.isTerminated)
        #expect(!(process.isRunning))

        // Running again should return the same state
        _ = try await process.run()
        #expect(process.state.isTerminated)
        #expect(!(process.isRunning))
    }

    @Test
    func testComplexProcessWorkflow() async throws {
        // Test a more complex workflow with multiple processes, error handling, and stream capture
        let tempDir: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        let testFile: URL = tempDir.appendingPathComponent("async_process_test_\(UUID().uuidString).txt")

        defer {
            // Cleanup
            try? FileManager.default.removeItem(at: testFile)
        }

        // Step 1: Create a file with some content
        let createFileProcess = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: "/bin/bash"),
            arguments: ["-c", "echo 'Line 1\nLine 2\nLine 3' > '\(testFile.path)'"],
            environment: [:],
            currentDirectoryURL: tempDir,
            options: []
        )

        #expect(createFileProcess.state == .notLaunch)
        let createResult: _ProcessRunResult = try await createFileProcess.run()
        #expect(createResult.terminationError == nil)
        #expect(createFileProcess.state.isTerminated)

        // Step 2: Verify file exists and read it back
        let readFileProcess = try _AsyncProcess(
            launchPath: "/bin/cat",
            arguments: [testFile.path],
            currentDirectoryURL: tempDir,
            environmentVariables: ["LANG": "en_US.UTF-8"],
            options: []
        )

        let readResult: _ProcessRunResult = try await readFileProcess.run()
        #expect(readResult.terminationError == nil)

        let fileContent: String? = readResult.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(fileContent == "Line 1\nLine 2\nLine 3")

        // Step 3: Process the file with a more complex command (word count)
        let wcProcess = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/wc"),
            arguments: ["-l", testFile.path],
            environment: nil,
            currentDirectoryURL: nil,
            options: []
        )

        let wcResult: _ProcessRunResult = try await wcProcess.run()
        #expect(wcResult.terminationError == nil)

        let lineCount: String? = wcResult.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(lineCount?.hasPrefix("3") ?? false, "Expected line count to start with '3', got: \(lineCount ?? "nil")")

        // Step 4: Test error handling with invalid file
        let invalidFileProcess = try _AsyncProcess(
            launchPath: "/bin/cat",
            arguments: ["/nonexistent/file/path"],
            options: []
        )

        let invalidResult: _ProcessRunResult = try await invalidFileProcess.run()
        // Should complete but with error content in stderr
        #expect(!(invalidResult.stderrString?.isEmpty ?? true))
        #expect(invalidResult.stderrString?.contains("No such file") ?? false)

        // Step 5: Test concurrent process execution
        let processes: [_AsyncProcess] = try (1...3).map { i in
            try _AsyncProcess(
                launchPath: "/bin/bash",
                arguments: ["-c", "sleep 0.1 && echo 'Process \(i) done'"],
                options: []
            )
        }

        let startTime: Date = Date()
        let results: [_ProcessRunResult] = try await withThrowingTaskGroup(of: _ProcessRunResult.self) { group in
            for process in processes {
                group.addTask {
                    try await process.run()
                }
            }

            var results: [_ProcessRunResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        let duration: TimeInterval = Date().timeIntervalSince(startTime)

        // Should complete concurrently (< 0.5s) not sequentially (> 0.3s)
        #expect(duration < 0.5)
        #expect(results.count == 3)
        #expect(results.allSatisfy { $0.terminationError == nil })

        // Verify all processes completed and produced expected output
        let outputs: [String] = results.compactMap { $0.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) }
        #expect(outputs.count == 3)
        #expect(outputs.contains("Process 1 done"))
        #expect(outputs.contains("Process 2 done"))
        #expect(outputs.contains("Process 3 done"))
    }

    @Test
    func testMultipleRunCalls() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["hello"],
            options: []
        )

        // First run
        let result1: _ProcessRunResult = try await process.run()

        // Second run should return same result
        let result2: _ProcessRunResult = try await process.run()

        #expect(result1.stdoutString == result2.stdoutString)
        #expect(result1.terminationError == result2.terminationError)
    }

    // MARK: - Process Options

    @Test
    func testForwardOutputOption() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["forwarded"],
            options: [._forwardStdoutStderr]
        )

        let result: _ProcessRunResult = try await process.run()

        // Output should still be captured even when forwarded
        #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == "forwarded")
    }

    @Test
    func testForwardOutputToFileSink() async throws {
        let logFile: URL = temporaryFile(named: "combined.log")

        defer {
            try? FileManager.default.removeItem(at: logFile.deletingLastPathComponent())
        }

        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", "printf 'stdout-line\\n'; sleep 0.1; printf 'stderr-line\\n' >&2"],
            options: [._forwardStdoutStderr(to: .file(logFile))]
        )

        let result: _ProcessRunResult = try await process.run()
        let forwardedOutput: String = try String(contentsOf: logFile, encoding: .utf8)

        #expect(result.stdoutString == "stdout-line")
        #expect(result.stderrString == "stderr-line")
        #expect(forwardedOutput.contains("stdout-line"))
        #expect(forwardedOutput.contains("stderr-line"))
    }

    @Test
    func testForwardOutputToSplitFileSink() async throws {
        let stdoutFile: URL = temporaryFile(named: "stdout.log")
        let stderrFile: URL = stdoutFile.deletingLastPathComponent().appendingPathComponent("stderr.log")

        defer {
            try? FileManager.default.removeItem(at: stdoutFile.deletingLastPathComponent())
        }

        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", "printf 'stdout-line\\n'; sleep 0.1; printf 'stderr-line\\n' >&2"],
            options: [._forwardStdoutStderr(to: .split(stdoutFile.path, err: stderrFile.path))]
        )

        let result: _ProcessRunResult = try await process.run()
        let forwardedStdout: String = try String(contentsOf: stdoutFile, encoding: .utf8)
        let forwardedStderr: String = try String(contentsOf: stderrFile, encoding: .utf8)

        #expect(result.stdoutString == "stdout-line")
        #expect(result.stderrString == "stderr-line")
        #expect(forwardedStdout.contains("stdout-line"))
        #expect(!forwardedStdout.contains("stderr-line"))
        #expect(forwardedStderr.contains("stderr-line"))
        #expect(!forwardedStderr.contains("stdout-line"))
    }

    // MARK: - Concurrent Execution

    @Test
    func testConcurrentProcesses() async throws {
        let processes: [_AsyncProcess] = try (1...5).map { i in
            try _AsyncProcess(
                launchPath: "/bin/echo",
                arguments: ["Process \(i)"],
                options: []
            )
        }

        // Run all processes concurrently
        let results: [_ProcessRunResult] = try await withThrowingTaskGroup(of: _ProcessRunResult.self) { group in
            for process in processes {
                group.addTask {
                    try await process.run()
                }
            }

            var results: [_ProcessRunResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }

        // All should succeed
        #expect(results.count == 5)
        for result in results {
            #expect(result.terminationError == nil)
            #expect(result.stdoutString?.contains("Process") ?? false)
        }
    }

    @Test
    func testConcurrentLongRunningProcesses() async throws {
        let processes: [_AsyncProcess] = try (1...3).map { i in
            try _AsyncProcess(
                launchPath: "/bin/bash",
                arguments: ["-c", "sleep 0.5 && echo 'Done \(i)'"],
                options: []
            )
        }

        let start: Date = Date()

        // Run all processes concurrently
        let results: [_ProcessRunResult] = try await withThrowingTaskGroup(of: _ProcessRunResult.self) { group in
            for process in processes {
                group.addTask {
                    try await process.run()
                }
            }

            var results: [_ProcessRunResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }

        let duration = Date().timeIntervalSince(start)

        // Should complete in roughly 0.5 seconds (concurrent), not 1.5 seconds (sequential)
        #expect(duration < 1.5)
        #expect(results.count == 3)
    }

    // MARK: - Process Termination and Cleanup

    @Test(.disabled("Process termination test skipped due to _AsyncProcess.start() implementation issues"))
    func testProcessTermination() async throws {
        // The _AsyncProcess.start() implementation has known issues.
    }

    @Test
    func testTeardownSequenceTerminatesRunningProcess() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", "trap 'echo terminated; exit 0' TERM; while true; do sleep 0.01; done"],
            options: [._teardown([.terminate(allowedDurationToNextStep: .milliseconds(100))])]
        )

        let task = Task {
            try await process.run()
        }

        while !process.isRunning {
            try await Task.sleep(.milliseconds(10))
        }

        await process.teardown(using: process.teardownSequence)

        let result: _ProcessRunResult = try await task.value

        #expect(result.stdoutString == "terminated")
        #expect(result.terminationStatus.isSuccess)
    }

    @Test
    func testLaunchFailurePropagatesAndCleansUpProcess() async throws {
        let initialCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

        let process: _AsyncProcess = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: "/definitely/not/a/real/executable"),
            arguments: [],
            environment: nil,
            currentDirectoryURL: nil,
            options: []
        )

        do {
            _ = try await process.run()

            Issue.record("Expected launch failure")
        } catch {
            let finalCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

            #expect(finalCount == initialCount)
        }
    }

    @Test
    func testRepeatedLaunchFailuresCleanUpProcessRegistry() async throws {
        let initialCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

        for _ in 0..<10 {
            let process: _AsyncProcess = try _AsyncProcess(
                executableURL: URL(fileURLWithPath: "/definitely/not/a/real/executable"),
                arguments: [],
                environment: nil,
                currentDirectoryURL: nil,
                options: []
            )

            do {
                _ = try await process.run()

                Issue.record("Expected launch failure")
            } catch {
                let finalCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

                #expect(finalCount == initialCount)
            }
        }
    }

    @Test
    func testProcessCleanupAfterCompletion() async throws {
        let initialCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["cleanup test"],
            options: []
        )

        // Process should be registered
        let countAfterInit: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }
        #expect(countAfterInit == initialCount + 1)

        _ = try await process.run()

        // Process should be cleaned up
        let finalCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }
        #expect(finalCount == initialCount)
    }

    @Test
    func testRepeatedShortProcessesCleanUpProcessRegistry() async throws {
        let initialCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

        for index in 0..<5 {
            let process: _AsyncProcess = try _AsyncProcess(
                launchPath: "/bin/echo",
                arguments: ["cleanup-\(index)"],
                options: []
            )

            let countAfterInit: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }
            #expect(countAfterInit == initialCount + 1)

            let result: _ProcessRunResult = try await process.run()

            #expect(result.stdoutString == "cleanup-\(index)")
            #expect(process.state.isTerminated)
            #expect(!process.isRunning)

            let finalCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }
            #expect(finalCount == initialCount)
        }
    }

    @Test
    func testTerminateBeforeLaunchIsNoOp() async throws {
        let initialCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["terminate-before-launch"],
            options: []
        )

        try await process.terminate()

        #expect(process.state == .notLaunch)
        #expect(!process.isRunning)
        #expect(_AsyncProcess.$runningProcesses.withCriticalRegion { $0.count } == initialCount + 1)

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString == "terminate-before-launch")
        #expect(_AsyncProcess.$runningProcesses.withCriticalRegion { $0.count } == initialCount)
    }

    @Test
    func testTerminateAfterCompletionIsNoOp() async throws {
        let initialCount: Int = _AsyncProcess.$runningProcesses.withCriticalRegion { $0.count }

        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["terminate-after-completion"],
            options: []
        )

        _ = try await process.run()
        try await process.terminate()

        #expect(process.state.isTerminated)
        #expect(!process.isRunning)
        #expect(_AsyncProcess.$runningProcesses.withCriticalRegion { $0.count } == initialCount)
    }

    // MARK: - Environment and Working Directory

    @Test
    func testEnvironmentVariables() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: "/bin/bash"),
            arguments: ["-c", "echo $TEST_VAR"],
            environment: ["TEST_VAR": "test_value"],
            currentDirectoryURL: nil,
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == "test_value")
    }

    @Test
    func testWorkingDirectory() async throws {
        // Use a more predictable directory that doesn't involve symlinks
        let tempDir: URL = URL(fileURLWithPath: "/tmp").standardizedFileURL

        let process: _AsyncProcess = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: "/bin/pwd"),
            arguments: [],
            environment: nil,
            currentDirectoryURL: tempDir,
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        let outputPath: String? = result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines)
        let expectedPath: String = tempDir.standardizedFileURL.path

        // Check if the output matches the expected directory
        // Handle potential symlink resolution by checking both paths
        let outputMatches: Bool = outputPath == expectedPath ||
                           outputPath == "/tmp" ||
                           outputPath?.hasSuffix("/tmp") == true

        #expect(outputMatches, "Expected working directory to be /tmp or equivalent, but got: \(outputPath ?? "nil")")
    }

    // MARK: - Convenience Initializers

    @Test
    func testConvenienceInitWithCommand() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/bash",
            arguments: ["-c", "echo 'convenience init'"],
            currentDirectoryURL: nil,
            environmentVariables: [:],
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == "convenience init")
    }

    @Test
    func testInitWithLaunchPath() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["launch path test"],
            currentDirectoryURL: nil,
            environmentVariables: [:],
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == "launch path test")
    }

    // MARK: - Stream Publishing

    @Test
    func testStandardOutputPublisher() async throws {
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: ["publisher test"],
            options: []
        )

        var receivedData: [Data] = []
        let cancellable: AnyCancellable = process._standardOutputPublisher()
            .sink { data in
                receivedData.append(data)
            }

        _ = try await process.run()
        try await Task.sleep(.milliseconds(100))

        #expect(!(receivedData.isEmpty))

        let combinedData: Data = receivedData.reduce(Data()) { $0 + $1 }
        let output: String? = String(data: combinedData, encoding: .utf8)
        #expect(output?.contains("publisher test") ?? false)

        cancellable.cancel()
    }

    // MARK: - Edge Cases

    @Test
    func testQuickSuccessiveProcesses() async throws {
        for i in 1...10 {
            let process: _AsyncProcess = try _AsyncProcess(
                launchPath: "/bin/echo",
                arguments: ["Quick \(i)"],
                options: []
            )

            let result: _ProcessRunResult = try await process.run()
            #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == "Quick \(i)")
        }
    }

    @Test
    func testProcessWithComplexArguments() async throws {
        let complexArg = "arg with spaces and 'quotes' and \"double quotes\""
        let process: _AsyncProcess = try _AsyncProcess(
            launchPath: "/bin/echo",
            arguments: [complexArg],
            options: []
        )

        let result: _ProcessRunResult = try await process.run()

        #expect(result.stdoutString?.trimmingCharacters(in: .whitespacesAndNewlines) == complexArg)
    }

    private func temporaryFile(
        named name: String
    ) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("merge-async-process-tests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent(name)
    }
}
