//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public var _attachedOutputFormatterTool: (any CommandLineToolOutputFormatterTool)? {
        get {
            _attachedOutputFormatterToolStorage
        } set {
            guard newValue == nil || _attachedOutputFormatterToolStorage == nil else {
                let error = _DeveloperError.outputFormatterToolAlreadyAttached

                runtimeIssue(error)
                preconditionFailure(error.description)
            }

            _attachedOutputFormatterToolStorage = newValue
        }
    }

    public var _attachedHostTool: _AttachedToolHost? {
        get {
            _attachedHostToolStorage
        } set {
            guard newValue == nil || _attachedHostToolStorage == nil else {
                let error = _DeveloperError.hostToolAlreadyAttached

                runtimeIssue(error)
                preconditionFailure(error.description)
            }

            _attachedHostToolStorage = newValue
        }
    }

    public var _attachedStandardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? {
        get {
            _attachedStandardStreamWiringStorage
        } set {
            _attachedStandardStreamWiringStorage = newValue
        }
    }

    public func _attachOutputFormatterTool(
        _ tool: (any CommandLineToolOutputFormatterTool)?
    ) throws {
        guard tool == nil || _attachedOutputFormatterToolStorage == nil else {
            let error = _DeveloperError.outputFormatterToolAlreadyAttached

            runtimeIssue(error)
            throw error
        }

        _attachedOutputFormatterToolStorage = tool
    }

    public func _attachHostTool(
        _ tool: _AttachedToolHost?
    ) throws {
        guard tool == nil || _attachedHostToolStorage == nil else {
            let error = _DeveloperError.hostToolAlreadyAttached

            runtimeIssue(error)
            throw error
        }

        _attachedHostToolStorage = tool
    }

    public func _attachHostToolThatResolvesAndInvokesSelectedTool(
        _ selectingTool: any AnyCommandLineToolWithSelectedTool & CommandLineTool,
        selectedToolCommandName: CommandLineTool.Name? = nil
    ) throws {
        try _attachHostTool(
            .toolThatResolvesAndInvokesSelectedTool(
                selectingTool,
                selectedToolCommandName: selectedToolCommandName?.rawValue
            )
        )
    }

    public func _detachOutputFormatterTool() {
        _attachedOutputFormatterToolStorage = nil
    }

    public func _detachHostTool() {
        _attachedHostToolStorage = nil
    }

    public func _detachStandardStreamWiring() {
        _attachedStandardStreamWiringStorage = nil
    }
}
