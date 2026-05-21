//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge

public struct _CommandLineToolResolutionContext {
    var resolvingID: _ResolvedCommandLineToolDescription.ArgumentID
    var commandKeyConversion: _CommandLineToolOptionKeyConversion?

    init(
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        defaultKeyConversion: _CommandLineToolOptionKeyConversion? = nil
    ) {
        self.resolvingID = resolvingID
        self.commandKeyConversion = defaultKeyConversion
    }
    
    func implicitKeyConversion(for name: String) -> _CommandLineToolOptionKeyConversion {
        if let commandKeyConversion {
            return commandKeyConversion
        }
        
        return name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}
