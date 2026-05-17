#if os(macOS)
//
//  TupleMetadata.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation

// Copied from Swallow since it's private and no `@_spi` available.

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct TupleMetadata {
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

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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

fileprivate let pointerSize = MemoryLayout<UnsafeRawPointer>.size

fileprivate struct MetadataKind: Equatable {
    var rawValue: UInt

    // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataValues.h
    // https://github.com/apple/swift/blob/main/include/swift/ABI/MetadataKind.def
    static var enumeration: Self { .init(rawValue: 0x201) }
    static var optional: Self { .init(rawValue: 0x202) }
    static var tuple: Self { .init(rawValue: 0x301) }
    static var existential: Self { .init(rawValue: 0x303) }
}

#endif
