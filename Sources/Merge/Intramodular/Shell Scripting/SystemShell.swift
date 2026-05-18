//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
import Swallow

public final class SystemShell: Logging, ObjectDidChangeObservableObject {
    package enum Ownership {
        case local
        case borrowedFromCommandLineTool
    }

    private var _configuration: Configuration
    private var _options: [_AsyncProcessOption]?

    public var configuration: Configuration {
        _configuration
    }

    public var environmentVariables: EnvironmentVariables {
        get {
            _configuration.environmentVariables
        } set {
            _preconditionCanMutateBorrowedShell(property: .environmentVariables)

            _configuration.environmentVariables = newValue
        }
    }

    public var currentDirectoryURL: URL? {
        get {
            _configuration.currentDirectoryURL
        } set {
            _preconditionCanMutateBorrowedShell(property: .currentDirectoryURL)

            _configuration.currentDirectoryURL = newValue
        }
    }

    public var options: [_AsyncProcessOption]? {
        get {
            let forwardingOption = try? _configuration.standardStreamMirroring._legacyForwardingOption()
            var result = _options ?? []

            if let forwardingOption {
                result.append(forwardingOption)
            }

            return result.isEmpty ? nil : result
        } set {
            _preconditionCanMutateBorrowedShell(property: .options)
            _setOptionsAssumingCanMutate(newValue)
        }
    }

    package var _nonStandardStreamMirroringOptions: [_AsyncProcessOption]? {
        _options
    }

    package let _internalState: _InternalState
    package let _borrowedLease: _BorrowedLease?
    package let _shellScopeID: _ShellScope.ID?
    package var ownership: Ownership = .local

    public var objectWillChange: AnyPublisher<Void, Never> {
        _internalState.objectWillChange.eraseToAnyPublisher()
    }

    public var objectDidChange: AnyPublisher<Void, Never> {
        _internalState.objectDidChange.eraseToAnyPublisher()
    }

    public init(
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcessOption]? = nil
    ) {
        self._configuration = Configuration(
            environmentVariables: .inherited(overriding: environment ?? [:]),
            currentDirectoryURL: currentDirectoryURL,
            standardStreamMirroring: StandardStreamMirroring(options: options)
        )
        self._options = options?.filter({ !$0._isStandardStreamForwardingOption })
        self._internalState = _InternalState()
        self._borrowedLease = nil
        self._shellScopeID = nil
    }

    public init(
        environmentVariables: EnvironmentVariables,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcessOption]? = nil
    ) {
        self._configuration = Configuration(
            environmentVariables: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
            standardStreamMirroring: StandardStreamMirroring(options: options)
        )
        self._options = options?.filter({ !$0._isStandardStreamForwardingOption })
        self._internalState = _InternalState()
        self._borrowedLease = nil
        self._shellScopeID = nil
    }

    public init(
        configuration: Configuration,
        options: [_AsyncProcessOption]? = nil
    ) {
        self._configuration = configuration
        self._options = options?.filter({ !$0._isStandardStreamForwardingOption })
        self._internalState = _InternalState()
        self._borrowedLease = nil
        self._shellScopeID = nil
    }

    package init(
        configuration: Configuration,
        options: [_AsyncProcessOption]? = nil,
        internalState: _InternalState,
        ownership: Ownership,
        borrowedLease: _BorrowedLease?,
        shellScopeID: _ShellScope.ID? = nil
    ) {
        self._configuration = configuration
        self._options = options?.filter({ !$0._isStandardStreamForwardingOption })
        self._internalState = internalState
        self.ownership = ownership
        self._borrowedLease = borrowedLease
        self._shellScopeID = shellScopeID
    }

    package func _optionsForProcessLaunch() throws -> [_AsyncProcessOption]? {
        var result = _options ?? []

        if let forwardingOption = try _configuration.standardStreamMirroring._legacyForwardingOption() {
            result.append(forwardingOption)
        }

        return result.isEmpty ? nil : result
    }

    package func _validateBorrowedLease() throws {
        guard ownership == .borrowedFromCommandLineTool else {
            return
        }

        guard _borrowedLease?.isValid == true else {
            let error = _DeveloperError.invalidBorrowedShellLease

            runtimeIssue(error)

            throw error
        }
    }

    package func _preconditionCanPerformOwnedShellOperation(
        _ operation: _OwnedOperation
    ) {
        guard ownership == .borrowedFromCommandLineTool else {
            return
        }

        let error = _DeveloperError.borrowedShellOwnedOperation(operation)

        runtimeIssue(error)
        preconditionFailure(error.description)
    }

    package func _validateCanAttemptOwnedShellOperation(
        _ operation: _OwnedOperation
    ) throws {
        guard ownership == .borrowedFromCommandLineTool else {
            return
        }

        let error = _DeveloperError.borrowedShellOwnedOperation(operation)

        runtimeIssue(error)
        throw error
    }

    private func _setOptionsAssumingCanMutate(
        _ options: [_AsyncProcessOption]?
    ) {
        self._configuration.standardStreamMirroring = StandardStreamMirroring(options: options)
        self._options = options?.filter({ !$0._isStandardStreamForwardingOption })
    }

    private func _preconditionCanMutateBorrowedShell(
        property: _MutableProperty
    ) {
        guard ownership == .borrowedFromCommandLineTool else {
            return
        }

        let error = _DeveloperError.borrowedShellMutation(property)

        runtimeIssue(error)
        preconditionFailure(error.description)
    }
}

extension _AsyncProcessOption {
    package var _isStandardStreamForwardingOption: Bool {
        guard case ._forwardStdoutStderr = self else {
            return false
        }

        return true
    }
}

extension SystemShell {
    package final class _BorrowedLease: @unchecked Sendable {
        private let lock = NSLock()
        private var _isValid: Bool = true

        package var isValid: Bool {
            lock.lock()
            defer {
                lock.unlock()
            }

            return _isValid
        }

        package init() {

        }

        package func invalidate() {
            lock.lock()
            defer {
                lock.unlock()
            }

            _isValid = false
        }
    }
}
