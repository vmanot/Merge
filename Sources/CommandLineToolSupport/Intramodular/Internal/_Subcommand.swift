//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

@dynamicMemberLookup
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol _Subcommand {
    associatedtype ParentCommand: CommandLineTool
}

extension _Subcommand where Self: AnyCommandLineTool {
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<ParentCommand, Value>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<ParentCommand, Self, Value> {
        .init(keyPath: keyPath)
    }
}

#endif
