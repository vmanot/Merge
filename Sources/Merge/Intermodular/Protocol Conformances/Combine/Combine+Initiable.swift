//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension CurrentValueSubject where Output: Swallow.Initiable {
    public convenience init() {
        self.init(Output())
    }
}

extension PassthroughSubject: Swallow._ThrowingInitiable, Swallow.Initiable {
    
}
