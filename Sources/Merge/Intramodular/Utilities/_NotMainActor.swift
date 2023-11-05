//
// Copyright (c) Vatsal Manot
//

import Swift

@globalActor
public actor _NotMainActor {
    public actor ActorType {
        fileprivate init() {
            
        }
    }
    
    public static let shared: ActorType = ActorType()
}
