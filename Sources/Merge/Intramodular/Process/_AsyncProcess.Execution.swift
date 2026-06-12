//
// Copyright (c) Vatsal Manot
//

import Darwin
import Foundation

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct _AsyncProcessTeardownStep: Hashable, Sendable {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public typealias TeardownStep = _AsyncProcessTeardownStep
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var teardownSequence: [TeardownStep] {
        options.flatMap(\._teardownSequence)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    /// Waits until the process exits and returns its collected output.
    @discardableResult
    public func waitUntilExit() async throws -> _ProcessRunResult {
        try await run()
    }

    /// Sends an interrupt signal to the process.
    public func interrupt() {
        #if os(macOS)
        process.interrupt()
        #else
        fatalError(.unavailable)
        #endif
    }

    /// Sends a kill signal to the process.
    public func kill() throws {
        #if os(macOS)
        guard Darwin.kill(process.processIdentifier, SIGKILL) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        #else
        fatalError(.unavailable)
        #endif
    }

    /// Performs a sequence of teardown steps on the subprocess.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func teardown(
        using sequence: some Sequence<TeardownStep> & Sendable
    ) async {
        #if os(macOS)
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
        #else
        fatalError(.unavailable)
        #endif
    }
}
