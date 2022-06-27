//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public struct MainThreadScheduler: Scheduler {
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    public typealias SchedulerOptions = DispatchQueue.SchedulerOptions
    
    public static var shared: Self {
        .init()
    }
    
    private let base = DispatchQueue.main
    
    private init() {
        
    }
    
    public var now: SchedulerTimeType {
        base.now
    }
    
    public var minimumTolerance: SchedulerTimeType.Stride {
        base.minimumTolerance
    }
    
    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            base.schedule(options: options, action)
        }
    }
    
    public func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        base.schedule(
            after: date,
            tolerance: tolerance,
            options: options,
            action
        )
    }
    
    /// Performs the action at some time after the specified date, at the specified frequency, optionally taking into account tolerance if possible.
    public func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> Cancellable {
        base.schedule(
            after: date,
            interval: interval,
            tolerance: tolerance,
            options: options,
            action
        )
    }
}

extension Publisher {
    public func receiveOnMainThread() -> Publishers.ReceiveOn<Self, MainThreadScheduler> {
        receive(on: MainThreadScheduler.shared)
    }
}
