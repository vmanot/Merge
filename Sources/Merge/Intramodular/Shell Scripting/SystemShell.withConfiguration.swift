//
// Copyright (c) Vatsal Manot
//

import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    public func withConfiguration<R>(
        applying differences: Configuration.Difference...,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withConfiguration(applying: differences, perform: operation)
    }

    public func withConfiguration<R>(
        applying differences: [Configuration.Difference],
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try _validateBorrowedLease()

        let difference = try differences.reduce(into: Configuration.Difference()) {
            try $0.mergeInPlace(with: $1)
        }

        guard let childConfiguration = configuration.applying(difference) else {
            throw _DeveloperError.conflictingConfigurationDifferences
        }

        let child = SystemShell(
            configuration: childConfiguration,
            options: _nonStandardStreamMirroringOptions,
            internalState: _internalState,
            ownership: ownership,
            borrowedLease: _borrowedLease
        )

        return try await operation(child)
    }
}
