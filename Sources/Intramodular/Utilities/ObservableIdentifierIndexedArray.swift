//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// An ordered, random access collection of observable objects.
///
/// `ObservableObject` subscribes to the `objectWillChange` publishers of all elements contained within it and forwards them to its own `objectWillChange` publisher.
public final class ObservableIdentifierIndexedArray<Element: Identifiable & ObservableObject>: Sequence, ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var cancellables: [Element.ID: AnyCancellable] = [:]
    
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
        cancellables[element.id] = element.objectWillChange.sink { [unowned self] _ in
            self.objectWillChange.send()
        }
    }
    
    private func unsubscribe(from elementID: Element.ID) {
        cancellables[elementID] = nil
    }
}

// MARK: - Conformances -

extension ObservableIdentifierIndexedArray: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        try self.init(Array<Element>(from: decoder))
    }
}

extension ObservableIdentifierIndexedArray: Equatable where Element: Equatable {
    public static func == (lhs: ObservableIdentifierIndexedArray, rhs: ObservableIdentifierIndexedArray) -> Bool {
        lhs.elements == rhs.elements
    }
}

extension ObservableIdentifierIndexedArray: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

extension ObservableIdentifierIndexedArray: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
    
    public convenience init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(elements)
    }
}

extension ObservableIdentifierIndexedArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
    }
}

extension ObservableIdentifierIndexedArray: MutableCollection, RandomAccessCollection {
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

extension ObservableIdentifierIndexedArray: RangeReplaceableCollection {
    public func append(_ element: Element) {
        elements.append(element)
        
        subscribe(to: element)
    }
    
    public func replaceSubrange<C>(
        _ subrange: Range<Array<Element>.Index>,
        with newElements: C
    ) where C : Collection, Array<Element>.Element == C.Element {
        let newElementsMap = Dictionary(newElements.map({ ($0.id, $0) }), uniquingKeysWith: { lhs, rhs in lhs })
        
        let difference = newElements.map({ $0.id }).difference(from: subrange.map({ self[$0].id }))
        
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

// MARK: - Auxiliary Implementation -

extension Array where Element: Identifiable & ObservableObject {
    public init(_ array: ObservableIdentifierIndexedArray<Element>) {
        self = array.elements
    }
}
