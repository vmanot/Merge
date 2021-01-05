//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Foundation

extension Publisher where Output == Data, Failure == Never {
	/// Create a process that reads standard input from this publisher,
	/// using the first argument as the command to run.
	///
	/// The command will be found in `$PATH` as if run through `env`. It is a
	/// fatal error if the command cannot be found; if you want to handle this
	/// case, invoke `env` explicitly and handle the failure.
	public func pipe(_ arguments: [String]) -> ProcessPublisher<ProcessExitFailure> {
		return self.setFailureType(to: ProcessExitFailure.self).pipe(arguments)
	}

	/// Create a process to run the given command, which must refer to an
	/// executable the user has permission to run. The process will read its
	/// standard input from this publisher.
	public func pipe(_ command: URL, arguments: [String] = []) -> ProcessPublisher<ProcessExitFailure> {
		return self.setFailureType(to: ProcessExitFailure.self).pipe(command, arguments: arguments)
	}
}

extension Publisher where Output == Data, Failure == ProcessExitFailure {
	/// Create a process that reads standard input from this publisher,
	/// using the first argument as the command to run.
	///
	/// The command will be found in `$PATH` as if run through `env`. It is a
	/// fatal error if the command cannot be found; if you want to handle this
	/// case, invoke `env` explicitly and handle the failure.
	///
	/// Failures produced by this publisher will be passed through the resulting
	/// publisher, terminating its process.
	public func pipe(_ arguments: [String]) -> ProcessPublisher<ProcessExitFailure> {
		validateArgumentsForEnv(arguments)
		return ProcessPublisher(envExecutableURL, arguments: arguments, input: self.eraseToAnyPublisher(), errorHandler: makeErrorCheckerForEnv(arguments) { $0 })
	}

	/// Create a process to run the given command, which must refer to an
	/// executable the user has permission to run. The process will read its
	/// standard input from this publisher.
	///
	/// Failures produced by this publisher will be passed through the resulting
	/// publisher, terminating its process.
	public func pipe(_ command: URL, arguments: [String] = []) -> ProcessPublisher<ProcessExitFailure> {
		return ProcessPublisher(command, arguments: arguments, input: self.eraseToAnyPublisher(), errorHandler: { $0 })
	}
}

extension Publisher where Output == Data, Failure == Error {
	/// Create a process that reads standard input from this publisher,
	/// using the first argument as the command to run.
	///
	/// The command will be found in `$PATH` as if run through `env`. It is a
	/// fatal error if the command cannot be found; if you want to handle this
	/// case, invoke `env` explicitly and handle the failure.
	///
	/// Failures produced by this publisher will be passed through the resulting
	/// publisher, terminating its process.
	public func pipe(_ arguments: [String]) -> ProcessPublisher<Error> {
		validateArgumentsForEnv(arguments)
		return ProcessPublisher(envExecutableURL, arguments: arguments, input: self.eraseToAnyPublisher(), errorHandler: makeErrorCheckerForEnv(arguments) { $0 })
	}

	/// Create a process to run the given command, which must refer to an
	/// executable the user has permission to run. The process will read its
	/// standard input from this publisher.
	///
	/// Failures produced by this publisher will be passed through the resulting
	/// publisher, terminating its process.
	public func pipe(_ command: URL, arguments: [String] = []) -> ProcessPublisher<Error> {
		return ProcessPublisher(command, arguments: arguments, input: self.eraseToAnyPublisher(), errorHandler: { $0 })
	}
}

#endif
