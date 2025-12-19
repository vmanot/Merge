//
//  _CommandLineToolResolutionContext.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/12.
//

import Foundation

public struct _CommandLineToolResolutionContext {
    var argumentPositions: Set<_CommandLineToolArgumentPosition> = [.local, .nextCommand, .lastCommand]
    var traverseDepth: Int = 0
    
    public init() {
        
    }
    
    internal init(
        argumentPositions: Set<_CommandLineToolArgumentPosition> = [.local, .nextCommand, .lastCommand],
        traverseDepth: Int = 0
    ) {
        self.argumentPositions = argumentPositions
        self.traverseDepth = traverseDepth
    }
}
