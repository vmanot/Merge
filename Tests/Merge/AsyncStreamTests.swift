import Foundation
import Combine
import Testing
@testable import Merge

@Suite(.serialized)
struct AsyncStreamTests {
    @Test("AsyncStream cancellation propagates to publisher")
    func testCancellation() async throws {
        let publisher = PassthroughSubject<Int, Never>()

        try await confirmation { confirm in
            let cancellablePublisher = publisher.handleCancel {
                confirm()
            }

            let stream = cancellablePublisher.toAsyncStream()

            let task = Task {
                for await _ in stream {
                    _ = ()
                }
            }

            try await Task.sleep(for: .milliseconds(100))
            task.cancel()

            _ = await task.result
        }
    }
}
