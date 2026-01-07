//
//  _SubcommandOf.swift
//  Merge
//

import Foundation

@dynamicMemberLookup
public protocol _SubcommandOf {
    associatedtype ParentCommand: CommandLineTool
}

extension _SubcommandOf where Self: AnyCommandLineTool {
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<ParentCommand, InvocationSummaryValue<Value>>
    ) -> InvocationSummaryValueExpression<Self, Value> {
        .parent(keyPath)
    }
}
