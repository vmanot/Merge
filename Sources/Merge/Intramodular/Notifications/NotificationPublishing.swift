//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol NotificationPublishing {
    associatedtype NotificationPublisherType: Publisher where NotificationPublisherType.Failure == Never
    
    var notificationPublisher: NotificationPublisherType { get }
}

extension NotificationPublishing where Self: ObservableObject {
    public func onNotification(
        _ x: NotificationPublisherType.Output,
        perform action: @escaping () -> Void
    ) where NotificationPublisherType.Output: Equatable {
        _onReceiveOfValueEmittedBy(notificationPublisher.filter({ $0 == x })) { _ in
            action()
        }
    }
    
    public func onNotification(
        _ type: NotificationPublisherType.Output.TypeDiscriminator,
        perform action: @escaping () -> Void
    ) where NotificationPublisherType.Output: TypeDiscriminable {
        _onReceiveOfValueEmittedBy(notificationPublisher.filter(type)) { _ in
            action()
        }
    }
}
