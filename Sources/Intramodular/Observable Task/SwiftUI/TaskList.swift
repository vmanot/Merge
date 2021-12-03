//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

public struct TaskPipelineView: View {
    public let pipeline: TaskPipeline
    
    public var body: some View {
        List {
            ForEach(pipeline.tasks.sorted(by: { $0.description < $1.description })) { task in
                Text(task.description)
            }
        }
    }
}
