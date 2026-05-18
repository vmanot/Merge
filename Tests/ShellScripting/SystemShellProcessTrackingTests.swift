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

    @Test("Kills running commands owned by the shell")
    func killsRunningCommandsOwnedByShell() async throws {
        let shell = SystemShell(options: [._teardown([.terminate(allowedDurationToNextStep: .milliseconds(100))])])

        let task = Task {
            try await shell.run(command: "trap 'echo terminated; exit 0' TERM; while true; do sleep 1; done")
        }

        while await shell.runningProcesses.isEmpty {
            try await Task.sleep(.milliseconds(10))
        }

        try await shell.kill()

        _ = try await task.value

        #expect(await shell.runningProcesses.isEmpty, "kill() should remove terminated commands from the running set.")
        #expect(await shell.completedRunResults.count == 1, "kill() should still record the terminated run result.")
    }

    @Test("Reports teardown outcomes for tracked running processes")
    func reportsTeardownOutcomesForTrackedRunningProcesses() async throws {
        let shell = SystemShell(options: [._teardown([.terminate(allowedDurationToNextStep: .milliseconds(100))])])

        let task = Task {
            try await shell.run(command: "trap 'echo terminated; exit 0' TERM; while true; do sleep 1; done")
        }

        while await shell.runningProcesses.isEmpty {
            try await Task.sleep(.milliseconds(10))
        }

        let report = try await shell.teardownRunningProcessesReporting()
        let processReport = try #require(
            report.processReports.first,
            "The shell should report the tracked process it attempted to tear down."
        )

        _ = try await task.value

        #expect(report.fullySucceeded, "A process that exits during teardown should make the aggregate report successful.")
        #expect(!report.partiallySucceeded, "A single successful teardown should not be marked partial.")
        #expect(report.failedProcesses.isEmpty, "Successful teardown should not produce failed process reports.")
        #expect(processReport.finalState == .exitedAfterStep(.terminate(allowedDurationToNextStep: .milliseconds(100))))
        #expect(
            processReport.stepReports.first?.controlResult == .sent,
            "The report should record that the terminate control operation was sent."
        )
        #expect(
            processReport.stepReports.first?.observedTerminationStatus != nil,
            "The report should include the observed termination status."
        )
    }
}
