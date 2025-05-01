import Foundation
import Combine
import Testing
@testable import Merge

@Suite
struct AsyncStreamTests {
    @Test("AsyncStream cancellation propagates to publisher")
    func testCancellation() async throws {
        let publisher = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()

        try await confirmation { confirm in
            var count: Int = 0
            
            let cancellablePublisher = publisher.handleCancel {
                print("✅ Publisher was canceled")
                confirm()
            }
            
            let stream = cancellablePublisher.toAsyncStream()
            
            let task = Task {
                for await _ in stream {
                    print("value")
                    count += 1
                }
            }
            
            try await Task.sleep(for: .milliseconds(300))
            
            task.cancel()
        }
    }
}
