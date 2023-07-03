//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// An ordered, random access collection of observable objects.
///
/// `ObservableObject` subscribes to the `objectWillChange` publishers of all elements contained within it and forwards them to its own `objectWillChange` publisher.
@propertyWrapper
public final class ObservableArray<Element: ObservableObject>: MutablePropertyWrapper, Sequence, ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()
    
    private var cancellables: [ObjectIdentifier: AnyCancellable] = [:]
    
    fileprivate var storage: [Element] {
        willSet {
            objectWillChange.send()
        } didSet {
            resubscribeToAll()
        }
    }
    
    public var wrappedValue: [Element] {
        get {
            storage
        } set {
            storage = newValue
        }
    }
    
    private init(storage: [Element]) {
        self.storage = storage
        
        resubscribeToAll()
    }
    
    public convenience init() {
        self.init(storage: [])
    }
    
    public convenience init(wrappedValue: [Element]) {
        self.init(storage: wrappedValue)
    }
    
    public convenience init(_ elements: [Element]) {
        self.init(storage: elements)
    }
    
    private func resubscribeToAll() {
        let oldCancellables = self.cancellables
        var newCancellables = [ObjectIdentifier: AnyCancellable](minimumCapacity: storage.count)
        
        for element in storage {
            let id = ObjectIdentifier(element)
            
            if let cancellable = oldCancellables[id] {
                newCancellables[id] = cancellable
            } else {
                newCancellables[id] = element.objectWillChange.sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
            }
        }
        
        self.cancellables = newCancellables
    }
    
    private func subscribe(to element: Element) {
        let id = ObjectIdentifier(element)
        
        guard cancellables[id] == nil else {
            return
        }
        
        cancellables[id] = element.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    private func unsubscribe(from elementID: ObjectIdentifier) {
        cancellables[elementID] = nil
    }
}

// MARK: - Conformances

extension ObservableArray: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        try self.init(Array<Element>(from: decoder))
    }
}

extension ObservableArray: Equatable where Element: Equatable {
    public static func == (lhs: ObservableArray, rhs: ObservableArray) -> Bool {
        lhs.storage == rhs.storage
    }
}

extension ObservableArray: Encodable where Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        try storage.encode(to: encoder)
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
        hasher.combine(storage)
    }
}

extension ObservableArray: MutableCollection, RandomAccessCollection {
    public typealias Index = Array<Element>.Index
    public typealias Element = Array<Element>.Element
    
    public var startIndex: Index {
        storage.startIndex
    }
    
    public var endIndex: Index {
        storage.endIndex
    }
    
    public subscript(index: Index) -> Element {
        get {
            storage[index]
        } set {
            storage[index] = newValue
        }
    }
    
    public func index(after i: Index) -> Index {
        storage.index(after: i)
    }
}

extension ObservableArray: RangeReplaceableCollection {
    public func append(_ element: Element) {
        storage.append(element)
        
        subscribe(to: element)
    }
    
    public func replaceSubrange<C: Collection<Element>>(
        _ subrange: Range<Index>,
        with newElements: C
    ) {
        storage.replaceSubrange(subrange, with: newElements)
    }
    
    public func remove(atOffsets offsets: IndexSet) {
        storage.remove(at: offsets)
    }
}

// MARK: - Auxiliary

extension Array where Element: ObservableObject {
    public init(_ array: ObservableArray<Element>) {
        self = array.storage
    }
}
