//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import Diagnostics
import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    package typealias TeardownStep = _AsyncProcess.TeardownStep

    package struct RunningProcess: Hashable, Sendable {
        package struct ID: Hashable, Sendable {
            package let rawValue: ObjectIdentifier

            package init(_ process: _AsyncProcess) {
                self.rawValue = ObjectIdentifier(process)
            }
        }

        package let id: ID
        package let processIdentifier: _AsyncProcess.ProcessIdentifier?

        package init(_ process: _AsyncProcess) {
            self.id = ID(process)
            self.processIdentifier = process.state == .notLaunch ? nil : process.processIdentifier
        }
    }

    package struct RunningProcessTeardownReport: Sendable {
        package let processReports: [ProcessTeardownReport]

        package var fullySucceeded: Bool {
            processReports.allSatisfy(\.finalState.isComplete)
        }

        package var partiallySucceeded: Bool {
            processReports.contains(where: { $0.finalState.isComplete })
                && processReports.contains(where: { !$0.finalState.isComplete })
        }

        package var failedProcesses: [ProcessTeardownReport] {
            processReports.filter { !$0.finalState.isComplete }
        }

        package var alreadyExitedProcesses: [ProcessTeardownReport] {
            processReports.filter { $0.finalState == .alreadyExited }
        }
    }

    package struct ProcessTeardownReport: Sendable {
        package let processID: RunningProcess.ID
        package let processIdentifier: _AsyncProcess.ProcessIdentifier?
        package let stepReports: [TeardownStepReport]
        package let finalState: FinalState
    }

    package struct TeardownStepReport: Sendable {
        package let step: TeardownStep
        package let controlResult: ControlResult
        package let observedTerminationStatus: _AsyncProcess.TerminationStatus?
    }

    package enum ControlResult: Sendable, Hashable {
        case sent
        case skippedAlreadyExited
        case failed(String)
        case timedOut
    }

    package enum FinalState: Sendable, Hashable {
        case alreadyExited
        case exitedAfterStep(TeardownStep)
        case killed
        case stillRunning
        case unknown

        package var isComplete: Bool {
            switch self {
                case .alreadyExited, .exitedAfterStep, .killed:
                    return true
                case .stillRunning, .unknown:
                    return false
            }
        }
    }

    package func teardownRunningProcessesReporting(
        using sequence: some Sequence<TeardownStep> & Sendable
    ) async throws -> RunningProcessTeardownReport {
        try _preconditionCanTeardownRunningProcesses()

        let processes = await runningProcesses
        var reports: [ProcessTeardownReport] = []

        for process in processes {
            reports.append(await Self._teardown(process, using: sequence))
        }

        return RunningProcessTeardownReport(processReports: reports)
    }

    package func teardownRunningProcessesReporting() async throws -> RunningProcessTeardownReport {
        try _preconditionCanTeardownRunningProcesses()

        let processes = await runningProcesses
        var reports: [ProcessTeardownReport] = []

        for process in processes {
            reports.append(await Self._teardown(process, using: process.teardownSequence))
        }

        return RunningProcessTeardownReport(processReports: reports)
    }

    public func kill() async throws {
        _preconditionCanPerformOwnedShellOperation(.kill)

        let report = try await teardownRunningProcessesReporting()

        guard report.fullySucceeded else {
            throw _DeveloperError.failedToKillRunningCommands(
                failedProcessCount: report.failedProcesses.count,
                totalProcessCount: report.processReports.count
            )
        }
    }

    package static func _teardown(
        _ process: _AsyncProcess,
        using sequence: some Sequence<TeardownStep> & Sendable
    ) async -> ProcessTeardownReport {
        let processID = RunningProcess.ID(process)
        let processIdentifier = process.state == .notLaunch ? nil : process.processIdentifier
        var stepReports: [TeardownStepReport] = []

        guard process.isRunning else {
            return ProcessTeardownReport(
                processID: processID,
                processIdentifier: processIdentifier,
                stepReports: [
                    TeardownStepReport(
                        step: .kill,
                        controlResult: .skippedAlreadyExited,
                        observedTerminationStatus: process._observedTerminationStatus
                    )
                ],
                finalState: .alreadyExited
            )
        }

        let finalSequence = Array(sequence) + [.kill]

        for step in finalSequence {
            guard process.isRunning else {
                return ProcessTeardownReport(
                    processID: processID,
                    processIdentifier: processIdentifier,
                    stepReports: stepReports,
                    finalState: .alreadyExited
                )
            }

            let controlResult = process._sendTeardownStepForSystemShellReporting(step)

            if step.allowedDurationToNextStep > .zero {
                try? await Task.sleep(for: step.allowedDurationToNextStep)
            } else if step.action == .kill {
                try? await Task.sleep(for: .milliseconds(100))
            }

            if !process.isRunning {
                stepReports.append(
                    TeardownStepReport(
                        step: step,
                        controlResult: controlResult,
                        observedTerminationStatus: process._observedTerminationStatus
                    )
                )

                return ProcessTeardownReport(
                    processID: processID,
                    processIdentifier: processIdentifier,
                    stepReports: stepReports,
                    finalState: step.action == .kill ? .killed : .exitedAfterStep(step)
                )
            } else {
                stepReports.append(
                    TeardownStepReport(
                        step: step,
                        controlResult: controlResult == .sent ? .timedOut : controlResult,
                        observedTerminationStatus: nil
                    )
                )
            }
        }

        return ProcessTeardownReport(
            processID: processID,
            processIdentifier: processIdentifier,
            stepReports: stepReports,
            finalState: process.isRunning ? .stillRunning : .unknown
        )
    }

    package func _preconditionCanTeardownRunningProcesses() throws {
        try _validateCanAttemptOwnedShellOperation(.teardownRunningProcesses)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell._InternalState {
    package func _teardownRunningProcessesReportingForOwningCommandLineTool() async -> SystemShell.RunningProcessTeardownReport {
        let processes = runningProcesses
        var reports: [SystemShell.ProcessTeardownReport] = []

        for process in processes {
            reports.append(await SystemShell._teardown(process, using: process.teardownSequence))
        }

        return SystemShell.RunningProcessTeardownReport(processReports: reports)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    fileprivate var _observedTerminationStatus: _AsyncProcess.TerminationStatus? {
        guard state.isTerminated else {
            return nil
        }

        return _AsyncProcess.TerminationStatus(_from: process)
    }

}
#endif
