//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct _CommandLineToolInvocationAssembly {
    var chain: [AnyCommandLineTool]
    var leafArguments: CommandLineToolInvocation.Arguments
    var context: CommandLineToolInvocationSummary.InvocationSummaryContext

    func makeInvocationArguments() throws -> CommandLineToolInvocation.Arguments {
        guard let root = chain.first else {
            return leafArguments
        }

        var result = CommandLineToolInvocation.Arguments()

        try appendRootCommand(root, to: &result)
        try appendCommandBoundaries(to: &result)
        appendLeafArguments(to: &result)
        try appendFinalCommandArguments(to: &result)

        return result
    }

    private func appendRootCommand(
        _ root: AnyCommandLineTool,
        to result: inout CommandLineToolInvocation.Arguments
    ) throws {
        result.append(CommandLineToolInvocation.Argument(root.requireCommandName().rawValue))
        try result.append(
            contentsOf: root._defaultInvocationArguments(
                context: context,
                positions: [.local]
            )
        )
    }

    private func appendCommandBoundaries(
        to result: inout CommandLineToolInvocation.Arguments
    ) throws {
        for (offset, command) in chain.dropFirst().enumerated() {
            let parent = chain[offset]

            result.append(CommandLineToolInvocation.Argument(command.requireCommandName().rawValue))
            try result.append(
                contentsOf: parent._defaultInvocationArguments(
                    context: context,
                    positions: [.nextCommand]
                )
            )

            if commandHasIntermediateLocalArguments(atOffsetFromRoot: offset + 1) {
                try result.append(
                    contentsOf: command._defaultInvocationArguments(
                        context: context,
                        positions: [.local]
                    )
                )
            }
        }
    }

    private func commandHasIntermediateLocalArguments(
        atOffsetFromRoot offset: Int
    ) -> Bool {
        offset < chain.count - 1
    }

    private func appendLeafArguments(
        to result: inout CommandLineToolInvocation.Arguments
    ) {
        result.elements.append(contentsOf: leafArguments.elements.filter { !$0.rawValue.isEmpty })
    }

    private func appendFinalCommandArguments(
        to result: inout CommandLineToolInvocation.Arguments
    ) throws {
        for command in chain.dropLast() {
            try result.append(
                contentsOf: command._defaultInvocationArguments(
                    context: context,
                    positions: [.lastCommand]
                )
            )
        }
    }
}
