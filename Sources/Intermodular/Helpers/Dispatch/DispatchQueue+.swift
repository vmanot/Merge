//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swallow

extension DispatchQueue {
    public final class _DebounceView {
        private let lock = OSUnfairLock()
        private let debounceInterval: DispatchTimeInterval
        private let queue: DispatchQueue
        
        private var workItem: DispatchWorkItem?
        
        fileprivate init(queue: DispatchQueue, debounceInterval: DispatchTimeInterval) {
            self.debounceInterval = debounceInterval
            self.queue = queue
        }
        
        public func schedule(_ action: @escaping () -> Void) {
            lock.withCriticalScope {
                workItem?.cancel()
                
                let newWorkItem = DispatchWorkItem { [weak self] in
                    action()
                    
                    self?.workItem = nil
                }
                
                workItem = newWorkItem
                
                queue.asyncAfter(deadline: .now() + debounceInterval, execute: newWorkItem)
            }
        }
    }
    
    public func _debounce(
        for debounceInterval: DispatchTimeInterval
    ) -> _DebounceView {
        .init(queue: self, debounceInterval: debounceInterval)
    }
}

extension DispatchTime: CustomStringConvertible {
    public var description: String {
        "(.now() + \(Double(Int(uptimeNanoseconds) - Int(DispatchTime.now().uptimeNanoseconds)) / Double(NSEC_PER_SEC)) seconds)"
    }
}

extension DispatchWallTime: CustomStringConvertible {
    public var description: String {
        "(some dispatch wall time)"
    }
}

extension DispatchTimeInterval: CustomStringConvertible {
    public var description: String {
        switch self {
            case .seconds(let value):
                return "\(value) second(s)"
            case .milliseconds(let value):
                return "\(value) millisecond(s)"
            case .microseconds(let value):
                return "\(value) microsecond(s)"
            case .nanoseconds(let value):
                return "\(value) nanosecond(s)"
            case .never:
                return "never"
            @unknown default:
                return "unknown"
        }
    }
}

public enum DispatchWorkExecutionDelay {
    case none
    case some(DispatchTimeInterval)
    case someWall(DispatchTimeInterval)
    
    public var descriptionIfSomeOrSomeWall: String? {
        switch self {
            case .some(let interval):
                return interval.description
            case .someWall(let interval):
                return interval.description + " (wall)"
            default:
                return nil
        }
    }
}

public enum DispatchWorkExecutionStyle: CustomStringConvertible {
    case asynchronous
    case synchronous
    
    public var description: String {
        switch self {
            case .asynchronous:
                return "asynchronous"
            case .synchronous:
                return "synchronous"
        }
    }
}

extension DispatchQueue {
    private static var globalSemaphore = DispatchSemaphore(value: 0)
    
    public static func wait(deadline: DispatchTime) {
        _ = globalSemaphore.wait(timeout: deadline)
    }
    
    public static func wait(wallDeadline: DispatchWallTime) {
        _ = globalSemaphore.wait(wallTimeout: wallDeadline)
    }
}

extension DispatchQueue {
    public func execute(
        style: DispatchWorkExecutionStyle,
        group: DispatchGroup? = nil,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [],
        _ work: (@escaping @convention(block) () -> ())
    ) {
        switch style  {
            case .asynchronous:
                async(group: group, qos: qos, flags: flags, execute: work)
            case .synchronous:
                group?.enter()
                sync(flags: flags, execute: work)
                group?.leave()
        }
    }
    
    public func execute(
        style: DispatchWorkExecutionStyle,
        workItem: DispatchWorkItem
    ) {
        switch style  {
            case .asynchronous:
                async(execute: workItem)
            case .synchronous:
                sync(execute: workItem)
        }
    }
    
    public func executeAfter(
        deadline: DispatchTime,
        style: DispatchWorkExecutionStyle,
        group: DispatchGroup? = nil,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [],
        _ work: (@escaping @convention(block) () -> ())
    ) {
        switch style  {
            case .asynchronous:
                group?.enter()
                asyncAfter(deadline: deadline, qos: qos, flags: flags) {
                    work()
                    group?.leave()
                }
            case .synchronous:
                group?.enter()
                DispatchQueue.wait(deadline: deadline)
                sync(flags: flags, execute: work)
                group?.leave()
        }
    }
    
    public func executeAfter(
        deadline: DispatchTime,
        style: DispatchWorkExecutionStyle,
        workItem: DispatchWorkItem
    ) {
        switch style  {
            case .asynchronous:
                asyncAfter(deadline: deadline, execute: workItem)
            case .synchronous:
                DispatchQueue.wait(deadline: deadline)
                sync(execute: workItem)
        }
    }
    
    public func executeAfter(
        wallDeadline: DispatchWallTime,
        style: DispatchWorkExecutionStyle,
        group: DispatchGroup? = nil,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [],
        _ work: (@escaping @convention(block) () -> ())
    ) {
        switch style  {
            case .asynchronous:
                group?.enter()
                asyncAfter(wallDeadline: wallDeadline, qos: qos, flags: flags) {
                    work()
                    group?.leave()
                }
            case .synchronous:
                group?.enter()
                DispatchQueue.wait(wallDeadline: wallDeadline)
                sync(flags: flags, execute: work)
                group?.leave()
        }
    }
    
    public func executeAfter(
        wallDeadline: DispatchWallTime,
        style: DispatchWorkExecutionStyle,
        workItem: DispatchWorkItem
    ) {
        switch style  {
            case .asynchronous:
                asyncAfter(wallDeadline: wallDeadline, execute: workItem)
            case .synchronous:
                DispatchQueue.wait(wallDeadline: wallDeadline)
                sync(execute: workItem)
        }
    }
    
    public func execute(
        delay: DispatchWorkExecutionDelay,
        style: DispatchWorkExecutionStyle,
        group: DispatchGroup? = nil,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = [], _
        work: (@escaping @convention(block) () -> ())
    ) {
        switch delay {
            case .none:
                execute(style: style, group: group, qos: qos, flags: flags, work)
            case .some(let interval):
                executeAfter(deadline: DispatchTime.now() + interval, style: style, group: group, qos: qos, flags: flags, work)
            case .someWall(let interval):
                executeAfter(wallDeadline: DispatchWallTime.now() + interval, style: style, group: group, qos: qos, flags: flags, work)
        }
    }
    
    public func execute(
        delay: DispatchWorkExecutionDelay,
        style: DispatchWorkExecutionStyle,
        workItem: DispatchWorkItem
    ) {
        switch delay {
            case .none:
                execute(style: style, workItem: workItem)
            case .some(let interval):
                executeAfter(deadline: DispatchTime.now() + interval, style: style, workItem: workItem)
            case .someWall(let interval):
                executeAfter(wallDeadline: DispatchWallTime.now() + interval, style: style, workItem: workItem)
        }
    }
}

extension Publisher {
    public func receiveOnMainQueue() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}
