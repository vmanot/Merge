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
        self.init(
            label: UUID().uuidString,
            qos: qos,
            attributes: attributes,
            autoreleaseFrequency: autoreleaseFrequency,
            target: target
        )
    }
    
    @_disfavoredOverload
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
    
    @_disfavoredOverload
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
    
    public static func globalConcurrent(
        label: String,
        qos: DispatchQoS
    ) -> DispatchQueue {
        DispatchQueue(
            label: label,
            attributes: .concurrent,
            target: .global(qos: qos.qosClass)
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
    public func concurrentPerform(iterations: Int, execute work: (@escaping (Int) -> ())) {
        sync(execute: { DispatchQueue.concurrentPerform(iterations: iterations, execute: work) })
    }
    
    @usableFromInline
    static func asyncOnMainIfNecessary(execute work: @escaping () -> ()) {
        if Thread.isMainThread {
            work()
        } else {
            Task { @MainActor in
                work()
            }
        }
    }
}
