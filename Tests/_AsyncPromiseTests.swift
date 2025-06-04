//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Dispatch
import Swallow
import Testing

@Suite("AsyncPromise Tests")
struct _AsyncPromiseTests {
    @Test("Basic stress test")
    func basicStressTest() async throws {
        for _ in 0..<100 {
            let promise: _AsyncPromise<Int, Never> = _AsyncPromise<Int, Never>()
            
            Task.detached(priority: .userInitiated) {
                promise.fulfill(with: .success(1))
            }
            
            let result: Int = await promise.get()
            
            #expect(result == 1)
        }
    }
    
    // MARK: - Basic Functionality Tests
    
    @Test("Basic promise fulfillment and value retrieval")
    func testBasicFulfillment() async throws {
        let promise: _AsyncPromise<String, Never> = _AsyncPromise<String, Never>()
        
        #expect(!promise.isFulfilled)
        #expect(promise.fulfilledValue == nil)
        
        promise.fulfill(with: "test value")
        
        #expect(promise.isFulfilled)
        #expect(promise.fulfilledValue == "test value")
        
        let result: String = await promise.get()
        #expect(result == "test value")
    }
    
    @Test("Promise initialized with immediate value")
    func testImmediateFulfillmentInitializer() async throws {
        let promise: _AsyncPromise<Int, Never> = _AsyncPromise(42)
        
        #expect(promise.isFulfilled)
        #expect(promise.fulfilledValue == 42)
        
        let result: Int = await promise.get()
        #expect(result == 42)
    }
    
    @Test("Void promise fulfillment")
    func testVoidFulfillment() async throws {
        let promise: _AsyncPromise<Void, Never> = _AsyncPromise<Void, Never>()
        
        #expect(!promise.isFulfilled)
        
        promise.fulfill()
        
        #expect(promise.isFulfilled)
        
        let result: Void = await promise.get()
        _ = result // Void result
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Promise fulfillment with custom error")
    func testErrorFulfillment() async throws {
        enum TestError: Error {
            case testFailure
        }
        
        let promise: _AsyncPromise<String, TestError> = _AsyncPromise<String, TestError>()
        
        #expect(!promise.isFulfilled)
        
        promise.fulfill(throwing: TestError.testFailure)
        
        #expect(promise.isFulfilled)
        
        do {
            let _: String = try await promise.get()
            Issue.record("Expected promise to throw error")
        } catch TestError.testFailure {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test("Promise fulfillment with generic error type")
    func testGenericErrorFulfillment() async throws {
        let promise: _AsyncPromise<Int, Error> = _AsyncPromise<Int, Error>()
        
        struct CustomError: Error, Equatable {
            let message: String
        }
        
        let testError: CustomError = CustomError(message: "test error")
        promise.fulfill(with: .failure(testError))
        
        #expect(promise.isFulfilled)
        
        do {
            let _: Int = try await promise.get()
            Issue.record("Expected promise to throw error")
        } catch let error as CustomError {
            #expect(error.message == "test error")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Async Initializer Tests
    
    @Test("Async value initializer with Never failure")
    func testAsyncValueInitializer() async throws {
        let promise: _AsyncPromise<String, Never> = _AsyncPromise {
            try! await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return "async value"
        }
        
        #expect(!promise.isFulfilled)
        
        let result: String = await promise.get()
        #expect(result == "async value")
        #expect(promise.isFulfilled)
    }
    
    @Test("Async throwing initializer with Error failure")
    func testAsyncThrowingInitializer() async throws {
        enum AsyncError: Error {
            case asyncFailure
        }
        
        let successPromise: _AsyncPromise<Int, Error> = _AsyncPromise {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return 100
        }
        
        let result: Int = try await successPromise.get()
        #expect(result == 100)
        
        let failurePromise: _AsyncPromise<Int, Error> = _AsyncPromise {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            throw AsyncError.asyncFailure
        }
        
        do {
            let _: Int = try await failurePromise.get()
            Issue.record("Expected promise to throw error")
        } catch AsyncError.asyncFailure {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test("Continuation-based promise initializer")
    func testContinuationInitializer() async throws {
        let promise: _AsyncPromise<String, Error> = _AsyncPromise { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                continuation.resume(returning: "continuation result")
            }
        }
        
        let result: String = try await promise.get()
        #expect(result == "continuation result")
    }
    
    // MARK: - Concurrency Tests
    
    @Test("Multiple concurrent waiters on same promise")
    func testMultipleWaiters() async throws {
        let promise: _AsyncPromise<Int, Never> = _AsyncPromise<Int, Never>()
        let waiterCount: Int = 10
        
        // Start multiple waiters
        let waitTasks: [Task<Int, Never>] = (0..<waiterCount).map { _ in
            Task {
                await promise.get()
            }
        }
        
        // Give waiters time to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Fulfill the promise
        promise.fulfill(with: 999)
        
        // All waiters should get the same result
        for task in waitTasks {
            let result: Int = await task.value
            #expect(result == 999)
        }
    }
}
