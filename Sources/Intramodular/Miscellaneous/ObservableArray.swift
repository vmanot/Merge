//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// An ordered, random access collection of observable objects.
///
/// `ObservableObject` subscribes to the `objectWillChange` publishers of all elements contained within it and forwards them to its own `objectWillChange` publisher.
public final class ObservableArray<Element: ObservableObject>: Sequence, ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var cancellables: [ObjectIdentifier: AnyCancellable] = [:]

    fileprivate var elements = [Element]() {
        willSet {
            objectWillChange.send()
        }
    }
        
    public init(_ elements: [Element]) {
        self.elements = elements
        
        for element in elements {
            subscribe(to: element)
        }
    }
    
    public init() {
        
    }
    
    private func subscribe(to element: Element) {
        cancellables[ObjectIdentifier(element)] = element.objectWillChange.sink { [unowned self] _ in
            self.objectWillChange.send()
        }
    }
    
    private func unsubscribe(from elementID: ObjectIdentifier) {
        cancellables[elementID] = nil
    }
}

// MARK: - Conformances -

extension ObservableArray: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        try self.init(Array<Element>(from: decoder))
    }
}

extension ObservableArray: Equatable where Element: Equatable {
    public static func == (lhs: ObservableArray, rhs: ObservableArray) -> Bool {
        lhs.elements == rhs.elements
    }
}

extension ObservableArray: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

extension ObservableArray: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
    
    public convenience init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(elements)
    }
}

extension ObservableArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
    }
}

extension ObservableArray: MutableCollection, RandomAccessCollection {
    public typealias Index = Array<Element>.Index
    public typealias Element = Array<Element>.Element
    
    public var startIndex: Index {
        return elements.startIndex
    }
    
    public var endIndex: Index {
        return elements.endIndex
    }
    
    public subscript(index: Index) -> Element {
        get {
            elements[index]
        } set {
            elements[index] = newValue
        }
    }
    
    public func index(after i: Index) -> Index {
        elements.index(after: i)
    }
}

extension ObservableArray: RangeReplaceableCollection {
    public func append(_ element: Element) {
        elements.append(element)
        
        subscribe(to: element)
    }
    
    public func replaceSubrange<C>(
        _ subrange: Range<Array<Element>.Index>,
        with newElements: C
    ) where C : Collection, Array<Element>.Element == C.Element {
        let newElementsMap = Dictionary(newElements.map({ (ObjectIdentifier($0), $0) }), uniquingKeysWith: { lhs, rhs in lhs })
        
        let difference = newElements.map({ ObjectIdentifier($0) }).difference(from: subrange.map({ ObjectIdentifier(self[$0]) }))
        
        for insertion in difference.insertions + difference.removals {
            switch insertion {
                case .insert(_, let element, _):
                    subscribe(to: newElementsMap[element]!)
                case .remove(_, let element, _):
                    unsubscribe(from: element)
            }
        }
        
        elements.replaceSubrange(subrange, with: newElements)
    }
    
    public func remove(atOffsets offsets: IndexSet) {
        elements.remove(at: offsets)
    }
}

// MARK: - Auxiliary -

extension Array where Element: ObservableObject {
    public init(_ array: ObservableArray<Element>) {
        self = array.elements
    }
}
