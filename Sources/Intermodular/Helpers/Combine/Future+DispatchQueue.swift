//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

extension Future where Failure == Never {
    // Schedules a block asynchronously for execution.
    public static func async(
        qos: DispatchQoS.QoSClass,
        execute work: @escaping () -> Output
    ) -> Future<Output, Failure>  {
        .init { attemptToFulfill in
            DispatchQueue.global(qos: qos).async {
                attemptToFulfill(.success(work()))
            }
        }
    }
    
    // Schedules a block asynchronously for execution.
    public static func async(
        priority: TaskPriority?,
        execute work: @escaping () async -> Output
    ) -> Future<Output, Failure>  {
        .init { attemptToFulfill in
            Task.detached(priority: priority) {
                await attemptToFulfill(.success(work()))
            }
        }
    }
}

extension Future where Failure == Error {
    // Schedules a block asynchronously for execution.
    public static func async(
        qos: DispatchQoS.QoSClass,
        execute work: @escaping () throws -> Output
    ) -> Future<Output, Failure>  {
        .init { attemptToFulfill in
            DispatchQueue.global(qos: qos).async {
                do {
                    attemptToFulfill(.success(try work()))
                } catch {
                    attemptToFulfill(.failure(error))
                }
            }
        }
    }
    
    // Schedules a block asynchronously for execution.
    public static func async(
        priority: TaskPriority?,
        execute work: @escaping () async throws -> Output
    ) -> Future<Output, Failure>  {
        .init { attemptToFulfill in
            Task.detached(priority: priority) {
                do {
                    let result = try await work()
                    
                    attemptToFulfill(.success(result))
                } catch {
                    attemptToFulfill(.failure(error))
                }
            }
        }
    }
}
