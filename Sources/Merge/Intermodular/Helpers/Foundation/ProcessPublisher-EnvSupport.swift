//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

/// The URL of `env` on a UNIXy system, used to execute commands via `$PATH`.
internal let envExecutableURL: URL = URL(fileURLWithPath: "/usr/bin/env")

/// Checks that the given arguments are appropriate for passing to `env`.
///
/// - There must be a command to run.
/// - No options can be passed to `env`.
/// - No new environment variables can be passed to `env`.
///
/// (The library *could* support some of these, but that would be an abstraction
/// violation, preventing future changes and leading clients to use the
/// `PATH`-based APIs when they really shouldn't.)
internal func validateArgumentsForEnv(_ arguments: [String]) {
	guard let first = arguments.first else {
		preconditionFailure("must provide the name of a command to run")
	}

	precondition(!first.starts(with: "-"), "command to run must not start with '-'")
	precondition(!first.contains("="), "command to run cannot have '=' in its name")
}

/// Checks that `env` didn't fail because it couldn't find the command.
///
/// If that *is* why it failed, it's considered a programmer error and the
/// program will be aborted.
internal func makeErrorCheckerForEnv<Failure>(
    _ arguments: [String],
    conversion: @escaping (ProcessExitFailure) -> Failure
) -> (ProcessExitFailure) -> Failure {
	let command = arguments.first!
	return { error in
		let commandNotFoundByEnvStatus: CInt = 127
		if case .exit(status: commandNotFoundByEnvStatus) = error {
			do {
				let check = try Process.run(URL(fileURLWithPath: "/usr/bin/which"), arguments: ["-s", command]) {
					precondition($0.terminationStatus == EXIT_SUCCESS, "command '\(command)' not found")
				}
				check.waitUntilExit()
			} catch {
				// Okay, if we failed to call `which` for some reason, just give up.
			}
		}
		return conversion(error)
	}
}

#endif
