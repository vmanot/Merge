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
    var chain: _CommandLineToolCommandChain
    var leafComponents: [CommandLineToolInvocation.Component]
    var context: CommandLineToolInvocationSummary.InvocationSummaryContext

    func makeInvocationArguments() throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            try makeInvocationComponents().flatMap(\.argumentValues)
        )
    }

    func makeInvocationComponents() throws -> [CommandLineToolInvocation.Component] {
        guard let root = chain.first else {
            return leafComponents
        }

        var result: [CommandLineToolInvocation.Component] = []

        try appendRootCommand(root, to: &result)
        try appendCommandBoundaries(to: &result)
        appendLeafComponents(to: &result)
        try appendFinalCommandArguments(to: &result)

        return result
    }

    private func appendRootCommand(
        _ root: AnyCommandLineTool,
        to result: inout [CommandLineToolInvocation.Component]
    ) throws {
        result.append(.executable(CommandLineToolInvocation.Argument(root.requireCommandName().rawValue)))
        try result.append(
            contentsOf: root._defaultInvocationComponents(
                context: context,
                positions: [.local]
            )
        )
    }

    private func appendCommandBoundaries(
        to result: inout [CommandLineToolInvocation.Component]
    ) throws {
        for (offset, command) in chain.dropFirst().enumerated() {
            let parent = chain[offset]

            result.append(.subcommand(CommandLineToolInvocation.Argument(command.requireCommandName().rawValue)))
            try result.append(
                contentsOf: parent._defaultInvocationComponents(
                    context: context,
                    positions: [.nextCommand]
                )
            )

            if commandHasIntermediateLocalArguments(atOffsetFromRoot: offset + 1) {
                try result.append(
                    contentsOf: command._defaultInvocationComponents(
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

    private func appendLeafComponents(
        to result: inout [CommandLineToolInvocation.Component]
    ) {
        result.append(contentsOf: leafComponents.filter { !$0.argumentValues.isEmpty })
    }

    private func appendFinalCommandArguments(
        to result: inout [CommandLineToolInvocation.Component]
    ) throws {
        for command in chain.dropLast() {
            try result.append(
                contentsOf: command._defaultInvocationComponents(
                    context: context,
                    positions: [.lastCommand]
                )
            )
        }
    }
}
