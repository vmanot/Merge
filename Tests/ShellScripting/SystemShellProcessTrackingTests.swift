//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Testing

@Suite(.serialized)
struct SystemShellProcessTrackingTests {
    @Test
    func tracksRunningProcessesAndCompletedRunResults() async throws {
        let shell = SystemShell(options: [])

        let task = Task {
            try await shell.run(command: "sleep 0.2; echo done")
        }

        while await shell.runningProcesses.isEmpty {
            try await Task.sleep(.milliseconds(10))
        }

        #expect(await shell.runningProcesses.count == 1)
        #expect(await shell.completedRunResults.isEmpty)

        let result = try await task.value

        #expect(result.stdoutString == "done")
        #expect(await shell.runningProcesses.isEmpty)
        #expect(await shell.completedRunResults.count == 1)
        #expect(await shell.completedRunResults.first?.stdoutString == "done")
    }

    @Test
    func tearsDownRunningProcessesOwnedByShell() async throws {
        let shell = SystemShell(options: [._teardown([.terminate(allowedDurationToNextStep: .milliseconds(100))])])

        let task = Task {
            try await shell.run(command: "trap 'echo terminated; exit 0' TERM; while true; do sleep 1; done")
        }

        while await shell.runningProcesses.isEmpty {
            try await Task.sleep(.milliseconds(10))
        }

        try await shell.teardownRunningProcesses()

        _ = try await task.value

        #expect(await shell.runningProcesses.isEmpty)
        #expect(await shell.completedRunResults.count == 1)
    }
}
