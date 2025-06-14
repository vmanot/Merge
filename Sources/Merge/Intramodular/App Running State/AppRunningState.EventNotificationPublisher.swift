//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import UIKit
import WatchKit
#endif

extension AppRunningState {
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public struct EventNotificationPublisher: Publisher {
        public enum Output {
            case didFinishLaunching
            case willBecomeActive
            case didBecomeActive
            case willBecomeInactive
            case didBecomeInactive
            case willTerminate
        }

        public typealias Failure = Never

        public init() {
            
        }
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {
            let notificationCenter = NotificationCenter.default

            #if os(iOS) || os(tvOS)
            Publishers.MergeMany(
                notificationCenter.publisher(for: UIApplication.didFinishLaunchingNotification).mapTo(Output.didFinishLaunching),
                notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification).mapTo(Output.willBecomeActive),
                notificationCenter.publisher(for: UIApplication.didBecomeActiveNotification).mapTo(Output.didBecomeActive),
                notificationCenter.publisher(for: UIApplication.willResignActiveNotification).mapTo(Output.willBecomeInactive),
                notificationCenter.publisher(for: UIApplication.didEnterBackgroundNotification).mapTo(Output.didBecomeInactive),
                notificationCenter.publisher(for: UIApplication.willTerminateNotification).mapTo(Output.willTerminate)
            )
            .receive(subscriber: subscriber)
            #elseif os(macOS)
            Publishers.MergeMany(
                notificationCenter.publisher(for: NSApplication.didFinishLaunchingNotification).mapTo(Output.didFinishLaunching),
                notificationCenter.publisher(for: NSApplication.willBecomeActiveNotification).mapTo(Output.willBecomeActive),
                notificationCenter.publisher(for: NSApplication.didBecomeActiveNotification).mapTo(Output.didBecomeActive),
                notificationCenter.publisher(for: NSApplication.willResignActiveNotification).mapTo(Output.willBecomeInactive),
                notificationCenter.publisher(for: NSApplication.didResignActiveNotification).mapTo(Output.didBecomeInactive),
                notificationCenter.publisher(for: NSApplication.willTerminateNotification).mapTo(Output.willTerminate)
            )
            .receive(subscriber: subscriber)
            #elseif os(watchOS)
            Publishers.MergeMany(
                notificationCenter.publisher(for: WKExtension.applicationDidFinishLaunchingNotification).mapTo(Output.didFinishLaunching),
                notificationCenter.publisher(for: WKExtension.applicationWillEnterForegroundNotification).mapTo(Output.willBecomeActive),
                notificationCenter.publisher(for: WKExtension.applicationDidBecomeActiveNotification).mapTo(Output.didBecomeActive),
                notificationCenter.publisher(for: WKExtension.applicationWillResignActiveNotification).mapTo(Output.willBecomeInactive),
                notificationCenter.publisher(for: WKExtension.applicationDidEnterBackgroundNotification).mapTo(Output.didBecomeInactive)
            )
            .receive(subscriber: subscriber)
            #endif
        }
    }
}
