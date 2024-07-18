//
// Copyright (c) Vatsal Manot
//

import Foundation
import Combine
import Swallow

public final class ObjectWillChangePublisherRelay<Source, Destination>: ObservableObject {
    private let _objectWillChange = ObservableObjectPublisher()
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        .init(erasing: _objectWillChange)
    }
    
    public var isUninitialized: Bool {
        source == nil && destination == nil
    }
    
    @Weak
    public var source: Source? {
        didSet {
            if let oldValue = oldValue as? AnyObject, let newValue = source as? AnyObject, oldValue === newValue {
                return
            }
            
            updateSubscription()
        }
    }
    
    @Weak
    public var destination: Destination? {
        didSet {
            if let oldValue = oldValue as? AnyObject, let newValue = destination as? AnyObject, oldValue === newValue {
                return
            }
            
            updateSubscription()
        }
    }
    
    private var destinationObjectWillChangePublisher: _opaque_VoidSender?
    private var subscription: AnyCancellable?
    
    public var _allowPublishingChangesFromBackgroundThreads: Bool = false
    
    public init(
        source: Source? = nil,
        destination: Destination? = nil
    ) {
        self.source = source
        self.destination = destination
    }
    
    public convenience init() where Source == Any, Destination == Any {
        self.init(source: nil, destination: nil)
    }
    
    public func send() {
        guard let destinationObjectWillChangePublisher else {
            if subscription != nil, destination != nil {
                updateSubscription()
            }
            
            return
        }
        
        if _allowPublishingChangesFromBackgroundThreads {
            DispatchQueue.asyncOnMainIfNecessary {
                destinationObjectWillChangePublisher.send()
            }
        } else {
            if !Thread.isMainThread {
                runtimeIssue("Publishing changes from background threads is not allowed.")
            }
            
            destinationObjectWillChangePublisher.send()
        }
    }
    
    private func updateSubscription() {
        destinationObjectWillChangePublisher = nil
        subscription?.cancel()
        subscription = nil
        
        guard
            let destination = toObservableObject(destination),
            let destinationObjectWillChange = (destination.objectWillChange as any Publisher) as? _opaque_VoidSender
        else {
            return
        }
        
        destinationObjectWillChangePublisher = destinationObjectWillChange
        
        guard let source = toObservableObject(source) else {
            return
        }
        
        assert(source !== destination)
        
        subscription = source
            .eraseObjectWillChangePublisher()
            .publish(to: _objectWillChange)
            .publish(to: destinationObjectWillChange)
            .sink()
    }
    
    private func toObservableObject(_ thing: Any?) -> (any ObservableObject)? {
        do {
            let object: (any ObservableObject)?
            
            if let wrappedValue = thing as? (any OptionalProtocol) {
                if let _wrappedValue = wrappedValue._wrapped as? any ObservableObject {
                    object = _wrappedValue
                } else {
                    object = nil
                }
            } else {
                object = try cast(destination, to: (any ObservableObject).self)
            }
            
            return object
        } catch {
            assertionFailure()
            
            return nil
        }
    }
}
