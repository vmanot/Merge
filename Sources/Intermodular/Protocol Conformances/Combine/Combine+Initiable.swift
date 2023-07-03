//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension CurrentValueSubject where Output: Initiable {
    public convenience init() {
        self.init(Output())
    }
}

extension PassthroughSubject: Initiable {
    
}
