//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Foundation

/// Implementation of the `lines()` operator (via LinesOperator).
/// See there for details.
fileprivate final class LinesSubscription<Downstream: Subscriber>: NonSynchronousOperatorBase<Data, Downstream> where Downstream.Input == String {
    var workingData = Data()
    
    override func receiveWhileLocked(_ input: Data) {
        self.workingData += input
    }
    
    override func popValueToSendWhileLocked() -> String? {
        let line: Data
        if let newlineIndex = self.workingData.firstIndex(of: "\n".utf8.first!) {
            let upToNewline = self.workingData[..<newlineIndex]
            if upToNewline.last == "\r".utf8.first {
                line = upToNewline.dropLast()
            } else {
                line = upToNewline
            }
            self.workingData = self.workingData[newlineIndex...].dropFirst()
            
        } else if !self.workingData.isEmpty && self.completion != nil {
            // Last line is unterminated.
            line = self.workingData
            self.workingData = Data()
            
        } else {
            // No data in our buffer.
            return nil
        }
        
        return String(decoding: line, as: UTF8.self)
    }
    
    override var hasSentAllValuesLocked: Bool {
        return self.workingData.isEmpty
    }
    
    override var supportsUnlimitedUpstreamDemand: Bool {
        return true
    }
    
    override var shouldImmediatelyCompleteOnFailureLocked: Bool {
        return false
    }
    
    override func releaseResourcesWhileLocked() {
        self.workingData = Data()
    }
}

/// Implementation of the `lines()` operator. See there for details.
public struct LinesOperator<Upstream: Publisher>: Publisher where Upstream.Output == Data {
    public typealias Output = String
    public typealias Failure = Upstream.Failure
    
    public let upstream: Upstream
    public let shouldBuffer: Bool
    
    public func receive<Downstream>(subscriber: Downstream) where Downstream: Subscriber, Self.Failure == Downstream.Failure, Self.Output == Downstream.Input {
        upstream.subscribe(LinesSubscription(subscriber, shouldBuffer: shouldBuffer))
    }
}

extension Publisher where Output == Data {
    /// Splits incoming data into String lines (separated by `\n` or `\r\n`).
    ///
    /// If `shouldBuffer` is false, this operator does not request values from
    /// upstream until values are requested from it. That is, it passes
    /// backpressure up through the subscription chain. If `shouldBuffer` is true,
    /// it immediately sends unlimited demand upstream when it's connected.
    ///
    /// The line terminator is not included in the generated values.
    /// Invalid UTF-8 in the input Data will be replaced with
    /// U+FFFD REPLACEMENT CHARACTER.
    ///
    /// A line may be split over multiple upstream values; it will not be sent
    /// until a terminator is seen. The exception is the last line, which is
    /// "terminated" by the completion of the upstream publisher.
    ///
    /// Failures in the upstream publisher are passed through *after* any
    /// outstanding output. This is contrary to the Reactive Streams
    /// specification, item 4.2, which states that failure must be immediately
    /// passed through; however, the primary use of this operator to handle
    /// output from a ProcessPublisher means that not losing data is preferable.
    ///
    /// - SeeAlso: [Reactive Streams v1.0.3 for Java](https://github.com/reactive-streams/reactive-streams-jvm/blob/v1.0.3/README.md#4processor-code)
    public func lines(buffering shouldBuffer: Bool = false) -> LinesOperator<Self> {
        return LinesOperator(upstream: self, shouldBuffer: shouldBuffer)
    }
}

#endif
