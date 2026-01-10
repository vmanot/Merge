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

// MARK: - Auxiliary

// Copied from Swallow since it's private and no `@_spi` available.

private let pointerSize = MemoryLayout<UnsafeRawPointer>.size

private struct MetadataKind: Equatable {
    var rawValue: UInt
    
    // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataValues.h
    // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataKind.def
    static var enumeration: Self { .init(rawValue: 0x201) }
    static var optional: Self { .init(rawValue: 0x202) }
    static var tuple: Self { .init(rawValue: 0x301) }
    static var existential: Self { .init(rawValue: 0x303) }
}

private struct TupleMetadata {
    let ptr: UnsafeRawPointer
    
    init?(_ type: Any.Type) {
        self.ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
        guard self.ptr.load(as: MetadataKind.self) == .tuple else { return nil }
    }
    
    var elementCount: UInt {
        self.ptr
            .advanced(by: pointerSize)  // kind
            .load(as: UInt.self)
    }
    
    var labels: UnsafePointer<UInt8>? {
        self.ptr
            .advanced(by: pointerSize)  // kind
            .advanced(by: pointerSize)  // elementCount
            .load(as: UnsafePointer<UInt8>?.self)
    }
    
    func element(at i: Int) -> Element {
        Element(
            ptr:
                self.ptr
                .advanced(by: pointerSize)  // kind
                .advanced(by: pointerSize)  // elementCount
                .advanced(by: pointerSize)  // labels pointer
                .advanced(by: i * 2 * pointerSize)
        )
    }
}

extension TupleMetadata {
    struct Element: Equatable {
        let ptr: UnsafeRawPointer
        
        var type: Any.Type { self.ptr.load(as: Any.Type.self) }
        
        var offset: UInt32 { self.ptr.load(fromByteOffset: pointerSize, as: UInt32.self) }
        
        static func == (lhs: Element, rhs: Element) -> Bool {
            lhs.type == rhs.type && lhs.offset == rhs.offset
        }
    }
}
