//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension SystemShell {
    public struct Configuration: Hashable, Sendable {
        public var environmentVariables: EnvironmentVariables
        public var currentDirectoryURL: URL?
        public var standardStreamMirroring: StandardStreamMirroring

        public init(
            environmentVariables: EnvironmentVariables = .inherited,
            currentDirectoryURL: URL? = nil,
            standardStreamMirroring: StandardStreamMirroring = .disabled
        ) {
            self.environmentVariables = environmentVariables
            self.currentDirectoryURL = currentDirectoryURL
            self.standardStreamMirroring = standardStreamMirroring
        }
    }
}

extension SystemShell.Configuration: Diffable {
    public struct Difference: Hashable, Sendable, _DiffableDifferenceType, ThrowingMergeOperatable {
        package var environmentVariables: Field<SystemShell.EnvironmentVariables>
        package var currentDirectoryURL: OptionalField<URL>
        package var standardStreamMirroring: Field<SystemShell.StandardStreamMirroring>

        public var isEmpty: Bool {
            environmentVariables.isUnchanged
                && currentDirectoryURL.isUnchanged
                && standardStreamMirroring.isUnchanged
        }

        public init() {
            self.environmentVariables = .unchanged
            self.currentDirectoryURL = .unchanged
            self.standardStreamMirroring = .unchanged
        }

        package init(
            environmentVariables: Field<SystemShell.EnvironmentVariables> = .unchanged,
            currentDirectoryURL: OptionalField<URL> = .unchanged,
            standardStreamMirroring: Field<SystemShell.StandardStreamMirroring> = .unchanged
        ) {
            self.environmentVariables = environmentVariables
            self.currentDirectoryURL = currentDirectoryURL
            self.standardStreamMirroring = standardStreamMirroring
        }

        public static func environmentVariables(
            _ value: SystemShell.EnvironmentVariables
        ) -> Self {
            Self(environmentVariables: .set(value))
        }

        public static func currentDirectoryURL(
            _ value: URL?
        ) -> Self {
            Self(currentDirectoryURL: .set(value))
        }

        public static func standardStreamMirroring(
            _ value: SystemShell.StandardStreamMirroring
        ) -> Self {
            Self(standardStreamMirroring: .set(value))
        }

        /// Collect process output without mirroring standard streams to the terminal.
        public static var _collectingOutput: Self {
            .standardStreamMirroring(.disabled)
        }

        public mutating func mergeInPlace(
            with other: Self
        ) throws {
            try environmentVariables.mergeInPlace(with: other.environmentVariables)
            try currentDirectoryURL.mergeInPlace(with: other.currentDirectoryURL)
            try standardStreamMirroring.mergeInPlace(with: other.standardStreamMirroring)
        }
    }

    public func difference(
        from source: Self
    ) -> Difference {
        var result = Difference()

        if environmentVariables != source.environmentVariables {
            result.environmentVariables = .set(environmentVariables)
        }

        if currentDirectoryURL != source.currentDirectoryURL {
            result.currentDirectoryURL = .set(currentDirectoryURL)
        }

        if standardStreamMirroring != source.standardStreamMirroring {
            result.standardStreamMirroring = .set(standardStreamMirroring)
        }

        return result
    }

    public func applying(
        _ difference: Difference
    ) -> Self? {
        var result = self

        if case let .set(value) = difference.environmentVariables {
            result.environmentVariables = value
        }

        if case let .set(value) = difference.currentDirectoryURL {
            result.currentDirectoryURL = value
        }

        if case let .set(value) = difference.standardStreamMirroring {
            result.standardStreamMirroring = value
        }

        return result
    }
}

extension SystemShell.Configuration.Difference {
    package enum Field<Value: Hashable & Sendable>: Hashable, Sendable, ThrowingMergeOperatable {
        case unchanged
        case set(Value)

        package var isUnchanged: Bool {
            guard case .unchanged = self else {
                return false
            }

            return true
        }

        package mutating func mergeInPlace(
            with other: Self
        ) throws {
            switch (self, other) {
                case (_, .unchanged):
                    return
                case (.unchanged, .set):
                    self = other
                case let (.set(lhs), .set(rhs)) where lhs == rhs:
                    return
                case (.set, .set):
                    throw SystemShell._DeveloperError.conflictingConfigurationDifferences
            }
        }
    }

    package enum OptionalField<Value: Hashable & Sendable>: Hashable, Sendable, ThrowingMergeOperatable {
        case unchanged
        case set(Value?)

        package var isUnchanged: Bool {
            guard case .unchanged = self else {
                return false
            }

            return true
        }

        package mutating func mergeInPlace(
            with other: Self
        ) throws {
            switch (self, other) {
                case (_, .unchanged):
                    return
                case (.unchanged, .set):
                    self = other
                case let (.set(lhs), .set(rhs)) where lhs == rhs:
                    return
                case (.set, .set):
                    throw SystemShell._DeveloperError.conflictingConfigurationDifferences
            }
        }
    }
}

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

        let childScope: _ShellScope?

        if let shellScopeID = _shellScopeID {
            let parentScope = await _internalState._shellScope(id: shellScopeID)

            childScope = _ShellScope(
                parentID: shellScopeID,
                rootID: parentScope?.rootID ?? shellScopeID,
                kind: .configurationScope
            )
        } else {
            childScope = nil
        }

        if let childScope {
            await _internalState._insertShellScope(childScope)
        }

        let child = SystemShell(
            configuration: childConfiguration,
            options: _nonStandardStreamMirroringOptions,
            internalState: _internalState,
            ownership: ownership,
            borrowedLease: _borrowedLease,
            shellScopeID: childScope?.id
        )

        do {
            let result = try await operation(child)

            if let childScope {
                await _internalState._completeShellScope(id: childScope.id)
            }

            return result
        } catch {
            if let childScope {
                await _internalState._completeShellScope(id: childScope.id)
            }

            throw error
        }
    }
}
