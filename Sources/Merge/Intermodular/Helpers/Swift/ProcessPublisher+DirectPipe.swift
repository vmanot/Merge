//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension ProcessPublisher where Failure == ProcessExitFailure {
    /// Create a process that reads standard input **directly** from this
    /// publisher's standard output, using the first argument as the command to
    /// run.
    ///
    /// Unlike `pipe`, `directPipe` will redirect the current publisher's output
    /// directly into the new publisher, meaning it will not be available for
    /// other subscribers. The new publisher is also `autoconnect`ed to this one,
    /// meaning that both processes will be launched and terminated together. A
    /// ProcessPublisher can only have one direct-piped subscriber.
    ///
    /// The command will be found in `$PATH` as if run through `env`. It is a
    /// fatal error if the command cannot be found; if you want to handle this
    /// case, invoke `env` explicitly and handle the failure.
    ///
    /// Failures produced by this publisher will be passed through the resulting
    /// publisher, terminating its process.
    public func directPipe(
        _ arguments: [String]
    ) -> ProcessPublisher<Failure> {
        validateArgumentsForEnv(arguments)
        return ProcessPublisher(
            envExecutableURL,
            arguments: arguments,
            input: self.autoconnect().eraseToAnyPublisher(),
            directInput: self.prepareForDirectPipe(),
            errorHandler: makeErrorCheckerForEnv(arguments) {
                $0
            }
        )
    }
    
    /// Create a process to run the given command, which must refer to an
    /// executable the user has permission to run. The process will read its
    /// standard input **directly** from this publisher.
    ///
    /// Unlike `pipe`, `directPipe` will redirect the current publisher's output
    /// directly into the new publisher, meaning it will not be available for
    /// other subscribers. The new publisher is also `autoconnect`ed to this one,
    /// meaning that both processes will be launched and terminated together. A
    /// ProcessPublisher can only have one direct-piped subscriber.
    ///
    /// Failures produced by this publisher will be passed through the resulting
    /// publisher, terminating its process.
    public func directPipe(
        _ command: URL,
        arguments: [String] = []
    ) -> ProcessPublisher<Failure> {
        return ProcessPublisher(
            command,
            arguments: arguments,
            input: self.autoconnect().eraseToAnyPublisher(),
            directInput: self.prepareForDirectPipe(),
            errorHandler: {
                $0
            }
        )
    }
}

extension ProcessPublisher where Failure == Error {
    /// Create a process that reads standard input **directly** from this
    /// publisher's standard output, using the first argument as the command to
    /// run.
    ///
    /// Unlike `pipe`, `directPipe` will redirect the current publisher's output
    /// directly into the new publisher, meaning it will not be available for
    /// other subscribers. The new publisher is also `autoconnect`ed to this one,
    /// meaning that both processes will be launched and terminated together. A
    /// ProcessPublisher can only have one direct-piped subscriber.
    ///
    /// The command will be found in `$PATH` as if run through `env`. It is a
    /// fatal error if the command cannot be found; if you want to handle this
    /// case, invoke `env` explicitly and handle the failure.
    ///
    /// Failures produced by this publisher will be passed through the resulting
    /// publisher, terminating its process.
    public func directPipe(_ arguments: [String]) -> ProcessPublisher<Failure> {
        validateArgumentsForEnv(arguments)
        return ProcessPublisher(envExecutableURL, arguments: arguments, input: self.autoconnect().eraseToAnyPublisher(), directInput: self.prepareForDirectPipe(), errorHandler: makeErrorCheckerForEnv(arguments) { $0 })
    }
    
    /// Create a process to run the given command, which must refer to an
    /// executable the user has permission to run. The process will read its
    /// standard input **directly** from this publisher.
    ///
    /// Unlike `pipe`, `directPipe` will redirect the current publisher's output
    /// directly into the new publisher, meaning it will not be available for
    /// other subscribers. The new publisher is also `autoconnect`ed to this one,
    /// meaning that both processes will be launched and terminated together. A
    /// ProcessPublisher can only have one direct-piped subscriber.
    ///
    /// Failures produced by this publisher will be passed through the resulting
    /// publisher, terminating its process.
    public func directPipe(_ command: URL, arguments: [String] = []) -> ProcessPublisher<Failure> {
        return ProcessPublisher(command, arguments: arguments, input: self.autoconnect().eraseToAnyPublisher(), directInput: self.prepareForDirectPipe(), errorHandler: { $0 })
    }
}

#endif
