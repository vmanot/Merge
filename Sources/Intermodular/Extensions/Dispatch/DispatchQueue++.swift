//
// Copyright (c) Vatsal Manot
//

import Dispatch
import FoundationX
import Foundation
import Swallow

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
    public convenience init<T>(
        label: T.Type, qos: DispatchQoS = .default,
        attributes: DispatchQueue.Attributes = [],
        autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
        target: DispatchQueue? = nil
    ) {
        let labelPrefix = Bundle.current?.bundleIdentifier ?? "com.vmanot.Merge"
        let label = labelPrefix + "." + String(describing: label)
        self.init(label: label, qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
    }
}

extension DispatchQueue {
    public static var qosClass: DispatchQoS.QoSClass {
        return DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .unspecified
    }
    
    public var qosClass: DispatchQoS.QoSClass {
        return sync { DispatchQueue.qosClass }
    }
}

extension DispatchQueue {
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
}

extension DispatchQueue {
    private static let queueIdentifierKey = DispatchSpecificKey<DispatchGlobalQueueIdentifier>()
    private static let mainQueueTagKey = DispatchSpecificKey<Void>()
    private static var areAllKnownQueuesIdentified: OSUnfairMutexProtectedWrapper<Bool> = false
    
    private final class DispatchGlobalQueueIdentifier: WrapperBase<DispatchQoS.QoSClass> {
        deinit {
            areAllKnownQueuesIdentified.value = false
        }
    }
    
    private static func tagGlobalQueues() {
        areAllKnownQueuesIdentified.mutate { value in
            guard !value else {
                return
            }
            
            for qosClass in DispatchQoS.QoSClass.allCases {
                let queue = DispatchQueue.global(qos: qosClass)
                queue.setSpecific(key: DispatchQueue.queueIdentifierKey, value: .init(qosClass))
            }
            
            DispatchQueue.main.setSpecific(key: mainQueueTagKey, value: ())
            value = true
        }
    }
    
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
}

extension DispatchQueue {
    public static func initiallyInactiveSerial(label: String, qos: DispatchQoS = .default, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) -> DispatchQueue {
        return .init(
            label: label,
            qos: qos,
            attributes: .initiallyInactive,
            autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
    
    public static func serial(label: String, qos: DispatchQoS = .default, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) -> DispatchQueue {
        return .init(
            label: label,
            qos: qos,
            autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
    
    public static func initiallyInactiveConcurrent(label: String, qos: DispatchQoS = .default, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) -> DispatchQueue {
        return .init(
            label: label,
            qos: qos,
            attributes: [.concurrent, .initiallyInactive],
            autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
    
    public static func concurrent(label: String, qos: DispatchQoS = .default, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) -> DispatchQueue {
        return .init(
            label: label,
            qos: qos,
            attributes: .concurrent,
            autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
}

extension DispatchQueue {
    public func async<T>(flags: DispatchWorkItemFlags = [], expression: @autoclosure @escaping () -> T) {
        return async(flags: flags, execute: { _ = expression() })
    }
    
    public func sync<T>(flags: DispatchWorkItemFlags = [], expression: @autoclosure () -> T) -> T {
        return sync(flags: flags, execute: expression)
    }
    
    public func concurrentPerform(iterations: Int, execute work: (@escaping (Int) -> ())) {
        sync(execute: { DispatchQueue.concurrentPerform(iterations: iterations, execute: work) })
    }
}
