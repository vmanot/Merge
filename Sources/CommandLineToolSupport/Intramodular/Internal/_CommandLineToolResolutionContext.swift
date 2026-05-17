#if os(macOS)
//
//  _CommandLineToolResolutionContext.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/12.
//

import Foundation

public struct _CommandLineToolResolutionContext {
    var resolvingID: _ResolvedCommandLineToolDescription.ArgumentID
    var commandKeyConversion: _CommandLineToolOptionKeyConversion?
    
//    var argumentPositions: Set<_CommandLineToolArgumentPosition> = [.local, .nextCommand, .lastCommand]
//    var traverseDepth: Int = 0
    
    init(
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        defaultKeyConversion: _CommandLineToolOptionKeyConversion? = nil,
//        argumentPositions: Set<_CommandLineToolArgumentPosition> = [.local, .nextCommand, .lastCommand],
//        traverseDepth: Int = 0
    ) {
        self.resolvingID = resolvingID
        self.commandKeyConversion = defaultKeyConversion
//        self.argumentPositions = argumentPositions
//        self.traverseDepth = traverseDepth
    }
    
    func implicitKeyConversion(for name: String) -> _CommandLineToolOptionKeyConversion {
        if let commandKeyConversion {
            return commandKeyConversion
        }
        
        return name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}

#endif
