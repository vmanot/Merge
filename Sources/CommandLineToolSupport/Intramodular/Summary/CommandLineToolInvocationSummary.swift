//
//  CommandLineToolInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public protocol InvocationSummary<Command> {
    associatedtype Command: AnyCommandLineTool
    typealias Context = InvocationSummaryContext
    
    func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> [String]
}

// MARK: - Tuple Invocation Summary

public struct TupleInvocationSummary<Command: AnyCommandLineTool, T>: InvocationSummary {
    public var value: T
    
    @inlinable public init(_ value: T) {
        self.value = value
    }
    
    private var summaries: [any InvocationSummary<Command>] {
        let metadata = TupleMetadata(T.self)
        guard let metadata else { return [] }
        
        var summaries: [any InvocationSummary<Command>] = []
        for i in 0 ..< metadata.elementCount {
            let element = metadata.element(at: Int(i))
            guard let elementType = element.type as? any InvocationSummary<Command>.Type else {
                preconditionFailure("element type \(element.type) at index \(i) doesn't conform to InvocationSummary.")
                continue
            }
            let summary = withUnsafeBytes(of: value) { buffer in
                func load<Summary: InvocationSummary>(_: Summary.Type) -> Summary {
                    buffer.baseAddress!
                        .advanced(by: Int(element.offset))
                        .load(as: Summary.self)
                }
               
                return load(elementType)
            }
            summaries.append(summary)
        }
        return summaries
    }
    
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        try summaries.flatMap({
            try $0.makeInvocationArguments(command: command, parent: parent, context: context)
        })
    }
}
