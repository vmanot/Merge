//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct _CommandLineToolInvocationSummarySubject<SummaryCommand: AnyCommandLineTool> {
    var summaryCommand: SummaryCommand
    var parent: AnyCommandLineTool?
    var commandChain: _CommandLineToolCommandChain?

    var isCommandChainSubject: Bool {
        commandChain != nil
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    func _invocationSummarySubject() -> _CommandLineToolInvocationSummarySubject<SummaryContent.Command> {
        switch self {
            case let command as SummaryContent.Command:
                return _CommandLineToolInvocationSummarySubject(
                    summaryCommand: command,
                    parent: nil,
                    commandChain: nil
                )
            case let selectedTool as any _GenericSelectedCommandLineToolProtocol:
                guard let chain = _CommandLineToolCommandChain(resolving: self) else {
                    _preconditionFailureResolvingInvocationSummarySubject("selected tool chain")
                }

                guard let command = selectedTool._opaqueSelectedTool as? SummaryContent.Command else {
                    _preconditionFailureResolvingInvocationSummarySubject(
                        "selected tool \(type(of: selectedTool._opaqueSelectedTool)) as \(SummaryContent.Command.self)"
                    )
                }

                return _CommandLineToolInvocationSummarySubject(
                    summaryCommand: command,
                    parent: selectedTool._opaqueSelectingTool,
                    commandChain: chain
                )
            case let subcommand as any _GenericSubcommandProtocol:
                guard let chain = _CommandLineToolCommandChain(resolving: self) else {
                    _preconditionFailureResolvingInvocationSummarySubject("subcommand chain")
                }

                guard let command = subcommand.command as? SummaryContent.Command else {
                    _preconditionFailureResolvingInvocationSummarySubject(
                        "subcommand \(type(of: subcommand.command)) as \(SummaryContent.Command.self)"
                    )
                }

                return _CommandLineToolInvocationSummarySubject(
                    summaryCommand: command,
                    parent: subcommand.parent,
                    commandChain: chain
                )
            default:
                _preconditionFailureResolvingInvocationSummarySubject(
                    "\(type(of: self)) as \(SummaryContent.Command.self)"
                )
        }
    }

    var _shouldAppendDefaultInvocationSummary: Bool {
        !(self is any _GenericSubcommandProtocol)
            && !(self is any _GenericSelectedCommandLineToolProtocol)
            && !(SummaryContent.self == CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>.self)
    }

    private func _preconditionFailureResolvingInvocationSummarySubject(
        _ subject: String
    ) -> Never {
        preconditionFailure("Unable to resolve invocation summary subject \(subject) for \(type(of: self)).")
    }
}
