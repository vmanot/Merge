#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    package enum _LifecycleStatus: Hashable, Sendable {
        case active
        case killed
    }
}
#endif
