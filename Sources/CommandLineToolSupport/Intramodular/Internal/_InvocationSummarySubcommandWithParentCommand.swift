//
// Copyright (c) Vatsal Manot
//

import Foundation

@dynamicMemberLookup
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol _InvocationSummarySubcommandWithParentCommand {
    associatedtype ParentCommand: CommandLineTool
}

extension _InvocationSummarySubcommandWithParentCommand where Self: AnyCommandLineTool {
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<ParentCommand, Value>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<ParentCommand, Self, Value> {
        .init(keyPath: keyPath)
    }
}
