//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// A doubly linked list.
public final class _NaiveDoublyLinkedList<Element> {
    // first <-> node <-> ... <-> last
    private(set) var first: Node?
    private(set) var last: Node?
    
    public var isEmpty: Bool {
        last == nil
    }
    
    /// Adds an element to the end of the list.
    @discardableResult
    public func append(_ element: Element) -> Node {
        let node = Node(value: element)
        
        append(node)
        
        return node
    }
    
    /// Adds a node to the end of the list.
    public func append(_ node: Node) {
        if let last = last {
            last.next = node
            node.previous = last
            self.last = node
        } else {
            last = node
            first = node
        }
    }
    
    public func remove(_ node: Node) {
        node.next?.previous = node.previous // node.previous is nil if node=first
        node.previous?.next = node.next // node.next is nil if node=last
        if node === last {
            last = node.previous
        }
        if node === first {
            first = node.next
        }
        node.next = nil
        node.previous = nil
    }
    
    public func removeAllElements() {
        // avoid recursive Nodes deallocation
        var node = first
        while let next = node?.next {
            node?.next = nil
            next.previous = nil
            node = next
        }
        
        last = nil
        first = nil
    }
    
    public final class Node {
        public let value: Element
        
        public fileprivate(set) var next: Node?
        public fileprivate(set) var previous: Node?
        
        fileprivate init(value: Element) {
            self.value = value
        }
    }
    
    deinit {
        // This way we make sure that the deallocations do no happen recursively
        // (and potentially overflow the stack).
        removeAllElements()
    }
}
