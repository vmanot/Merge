//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Testing

@Suite("SystemShell process tracking", .serialized)
struct SystemShellProcessTrackingTests {
    @Test("Tracks running processes and completed run results")
    func tracksRunningProcessesAndCompletedRunResults() async throws {
        let shell = SystemShell(options: [])

        let task = Task {
            try await shell.run(command: "sleep 0.2; echo done")
        }

        while await shell.runningProcesses.isEmpty {
            try await Task.sleep(.milliseconds(10))
        }

        #expect(await shell.runningProcesses.count == 1, "The shell should expose the live process while it is running.")
        #expect(await shell.completedRunResults.isEmpty, "A running process should not be recorded as completed yet.")

        let result = try await task.value

        let completedRunResults = await shell.completedRunResults

        #expect(result.stdoutString == "done", "The shell should still return the captured run result to the caller.")
        #expect(await shell.runningProcesses.isEmpty, "Finished processes should be removed from the running set.")
        #expect(completedRunResults.count == 1, "Finished processes should be recorded exactly once.")
        #expect(completedRunResults.first?.stdoutString == "done", "The recorded result should preserve captured stdout.")
    }

    @Test("Tears down running processes owned by the shell")
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

        #expect(await shell.runningProcesses.isEmpty, "Teardown should remove terminated processes from the running set.")
        #expect(await shell.completedRunResults.count == 1, "Teardown should still record the terminated run result.")
    }
}
