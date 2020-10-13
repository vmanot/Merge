//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swallow

extension DispatchTime: CustomStringConvertible {
    public var nanosecondsSinceNow: Int {
        TODO.here(.addressEdgeCase, note: "possible overflow")
        return Int(uptimeNanoseconds) - Int(DispatchTime.now().uptimeNanoseconds)
    }
    
    public var secondsSinceNow: Double {
        TODO.here(.improve, note: "use a more precise floating point type")
        return Double(nanosecondsSinceNow) / Double(NSEC_PER_SEC)
    }
    
    public var description: String {
        return "(.now() + \(secondsSinceNow) seconds)"
    }
}

extension DispatchWallTime: CustomStringConvertible {
    public var description: String {
        return "(some dispatch wall time)"
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
    public func execute(style: DispatchWorkExecutionStyle, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], _ work: (@escaping @convention(block) () -> ())) {
        switch style  {
            case .asynchronous:
                async(group: group, qos: qos, flags: flags, execute: work)
            case .synchronous:
                group?.enter()
                sync(flags: flags, execute: work)
                group?.leave()
        }
    }
    
    public func execute(style: DispatchWorkExecutionStyle, workItem: DispatchWorkItem) {
        switch style  {
            case .asynchronous:
                async(execute: workItem)
            case .synchronous:
                sync(execute: workItem)
        }
    }
    
    public func executeAfter(deadline: DispatchTime, style: DispatchWorkExecutionStyle, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], _ work: (@escaping @convention(block) () -> ())) {
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
    
    public func executeAfter(deadline: DispatchTime, style: DispatchWorkExecutionStyle, workItem: DispatchWorkItem) {
        switch style  {
            case .asynchronous:
                asyncAfter(deadline: deadline, execute: workItem)
            case .synchronous:
                DispatchQueue.wait(deadline: deadline)
                sync(execute: workItem)
        }
    }
    
    public func executeAfter(wallDeadline: DispatchWallTime, style: DispatchWorkExecutionStyle, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], _ work: (@escaping @convention(block) () -> ())) {
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
    
    public func executeAfter(wallDeadline: DispatchWallTime, style: DispatchWorkExecutionStyle, workItem: DispatchWorkItem) {
        switch style  {
            case .asynchronous:
                asyncAfter(wallDeadline: wallDeadline, execute: workItem)
            case .synchronous:
                DispatchQueue.wait(wallDeadline: wallDeadline)
                sync(execute: workItem)
        }
    }
    
    public func execute(delay: DispatchWorkExecutionDelay, style: DispatchWorkExecutionStyle, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], _ work: (@escaping @convention(block) () -> ())) {
        switch delay {
            case .none:
                execute(style: style, group: group, qos: qos, flags: flags, work)
            case .some(let interval):
                executeAfter(deadline: DispatchTime.now() + interval, style: style, group: group, qos: qos, flags: flags, work)
            case .someWall(let interval):
                executeAfter(wallDeadline: DispatchWallTime.now() + interval, style: style, group: group, qos: qos, flags: flags, work)
        }
    }
    
    public func execute(delay: DispatchWorkExecutionDelay, style: DispatchWorkExecutionStyle, workItem: DispatchWorkItem) {
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
