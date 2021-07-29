//
// Copyright (c) Vatsal Manot
//

import Dispatch
import FoundationX
import Foundation
import Swallow

extension DispatchQueue {
    public convenience init(
        qos: DispatchQoS = .unspecified,
        attributes: DispatchQueue.Attributes = [],
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
        target: DispatchQueue? = nil
    ) {
        self.init(label: UUID().uuidString, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
    }
    
    public convenience init(
        qosClass: DispatchQoS.QoSClass = .unspecified,
        attributes: DispatchQueue.Attributes = [],
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
        target: DispatchQueue? = nil
    ) {
        self.init(
            qos: .init(qosClass: qosClass, relativePriority: 0),
            attributes: attributes, autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
    
    public convenience init<T>(
        label: T.Type,
        qos: DispatchQoS = .unspecified,
        attributes: DispatchQueue.Attributes = [],
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
        target: DispatchQueue? = nil
    ) {
        let labelPrefix = Bundle.current?.bundleIdentifier ?? "com.vmanot.Merge"
        let label = labelPrefix + "." + String(describing: label)
        self.init(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
    }
    
    public convenience init<T>(
        label: T.Type,
        qosClass: DispatchQoS.QoSClass = .unspecified,
        attributes: DispatchQueue.Attributes = [],
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
        target: DispatchQueue? = nil
    ) {
        self.init(
            label: label,
            qos: .init(qosClass: qosClass, relativePriority: 0),
            attributes: attributes, autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
}

extension DispatchQueue {
    public subscript<T>(_ key: DispatchSpecificKey<T>) -> T? {
        get {
            return getSpecific(key: key)
        } set {
            setSpecific(key: key, value: newValue)
        }
    }
}

extension DispatchQueue {
    public var isMain: Bool {
        DispatchQueue.tagGlobalQueues()
        return getSpecific(key: DispatchQueue.mainQueueTagKey) != nil
    }
    
    public static var isMain: Bool {
        DispatchQueue.tagGlobalQueues()
        return getSpecific(key: DispatchQueue.mainQueueTagKey) != nil
    }
    
    public var globalQoSClass: DispatchQoS.QoSClass? {
        DispatchQueue.tagGlobalQueues()
        return getSpecific(key: DispatchQueue.queueIdentifierKey)?.value
    }
    
    public static var globalQoSClass: DispatchQoS.QoSClass? {
        DispatchQueue.tagGlobalQueues()
        return getSpecific(key: DispatchQueue.queueIdentifierKey)?.value
    }
    
    public var isGlobal: Bool {
        return globalQoSClass != nil
    }
    
    public static var isGlobal: Bool {
        return globalQoSClass != nil
    }
    
    private static let queueObjectKey = DispatchSpecificKey<Weak<DispatchQueue>>()
    
    public func tagForCurrentQueueQuery() {
        setSpecific(key: DispatchQueue.queueObjectKey, value: .init(Weak(self)))
    }
    
    public static var currentIfPossible: DispatchQueue? {
        if let globalQoSClass = globalQoSClass {
            return DispatchQueue.global(qos: globalQoSClass)
        } else if isMain {
            return DispatchQueue.main
        } else if let queue = getSpecific(key: DispatchQueue.queueObjectKey) {
            return queue.value
        } else {
            return nil
        }
    }
    
    private static let queueIdentifierKey = DispatchSpecificKey<DispatchGlobalQueueIdentifier>()
    private static let mainQueueTagKey = DispatchSpecificKey<Void>()
    private static var areAllKnownQueuesIdentified: MutexProtectedValue<Bool, OSUnfairLock> = .init(wrappedValue: false)
    
    private final class DispatchGlobalQueueIdentifier: WrapperBase<DispatchQoS.QoSClass> {
        deinit {
            areAllKnownQueuesIdentified.mutate({ $0 = false })
        }
    }
    
    private static func tagGlobalQueues() {
        areAllKnownQueuesIdentified.mutate { value in
            guard !value else {
                return
            }
            
            for qosClass in DispatchQoS.QoSClass.allCases {
                DispatchQueue.global(qos: qosClass).setSpecific(key: DispatchQueue.queueIdentifierKey, value: .init(qosClass))
            }
            
            DispatchQueue.main.setSpecific(key: mainQueueTagKey, value: ())
            value = true
        }
    }
}

extension DispatchQueue {
    public func concurrentPerform(iterations: Int, execute work: (@escaping (Int) -> ())) {
        sync(execute: { DispatchQueue.concurrentPerform(iterations: iterations, execute: work) })
    }
    
    @usableFromInline
    static func asyncOnMainIfNecessary(execute work: @escaping () -> ()) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
