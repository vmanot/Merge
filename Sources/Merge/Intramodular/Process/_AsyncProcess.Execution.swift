//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import Darwin
import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public struct TeardownStep: Hashable, Sendable {
        public enum Action: Hashable, Sendable {
            case interrupt
            case terminate
            case kill
        }

        public let action: Action
        public let allowedDurationToNextStep: Duration

        public init(
            action: Action,
            allowedDurationToNextStep: Duration
        ) {
            self.action = action
            self.allowedDurationToNextStep = allowedDurationToNextStep
        }

        public static func interrupt(
            allowedDurationToNextStep: Duration
        ) -> Self {
            Self(
                action: .interrupt,
                allowedDurationToNextStep: allowedDurationToNextStep
            )
        }

        public static func terminate(
            allowedDurationToNextStep: Duration
        ) -> Self {
            Self(
                action: .terminate,
                allowedDurationToNextStep: allowedDurationToNextStep
            )
        }

        public static var kill: Self {
            Self(action: .kill, allowedDurationToNextStep: .zero)
        }
    }

    public var teardownSequence: [TeardownStep] {
        options.flatMap(\._teardownSequence)
    }

    /// Waits until the process exits and returns its collected output.
    @discardableResult
    public func waitUntilExit() async throws -> Process.RunResult {
        try await run()
    }

    /// Sends an interrupt signal to the process.
    public func interrupt() {
        process.interrupt()
    }

    /// Sends a kill signal to the process.
    public func kill() throws {
        guard Darwin.kill(process.processIdentifier, SIGKILL) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }

    /// Performs a sequence of teardown steps on the subprocess.
    public func teardown(
        using sequence: some Sequence<TeardownStep> & Sendable
    ) async {
        let sequence = Array(sequence) + [.kill]

        for step in sequence {
            guard process.isRunning else {
                return
            }

            switch step.action {
                case .interrupt:
                    interrupt()
                case .terminate:
                    process.terminate()
                case .kill:
                    try? kill()
            }

            guard step.allowedDurationToNextStep > .zero else {
                continue
            }

            try? await Task.sleep(for: step.allowedDurationToNextStep)
        }
    }
}
#endif
