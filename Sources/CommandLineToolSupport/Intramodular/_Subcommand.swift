//
//  _Subcommand.swift
//  Merge
//

import Foundation

@dynamicMemberLookup
public protocol _Subcommand {
    associatedtype ParentCommand: CommandLineTool
}

extension _Subcommand where Self: AnyCommandLineTool {
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<ParentCommand, InvocationSummaryValueReference<ParentCommand, Value>>
    ) -> InvocationSummaryValueReferenceFromParent<ParentCommand, Self, Value> {
        .init(keyPath: keyPath)
    }
}
