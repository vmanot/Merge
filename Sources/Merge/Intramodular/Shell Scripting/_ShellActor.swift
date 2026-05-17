//
// Copyright (c) Vatsal Manot
//

@globalActor
public actor _ShellActor {
    public actor ActorType {
        fileprivate init() {

        }
    }

    public static let shared: ActorType = ActorType()
}
