//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

struct TaskPipelineViewSubscriber: ViewModifier {
    @Environment(\.taskPipeline) var pipeline
    
    let filter: TaskIdentifier
    let action: (TaskStatusDescription) -> ()
    
    func body(content: Content) -> some View {
        content.onReceive(self.pipeline.objectWillChange) {
            if let status = self.pipeline[self.filter]?.statusDescription {
                self.action(status)
            }
        }
    }
}

// MARK: - API -

extension View {
    public func onStatusChange(
        of name: TaskIdentifier,
        perform action: @escaping (TaskStatusDescription) -> Void
    ) -> some View {
        modifier(TaskPipelineViewSubscriber(filter: name) {
            action($0)
        })
    }
}
