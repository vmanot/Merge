//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    package func _sendTeardownStepForSystemShellReporting(
        _ step: _AsyncProcessTeardownStep
    ) -> SystemShell.ControlResult {
        #if os(macOS)
        switch step.action {
            case .interrupt:
                process.interrupt()

                return .sent
            case .terminate:
                process.terminate()

                return .sent
            case .kill:
                do {
                    try kill()

                    return .sent
                } catch {
                    return .failed(String(describing: error))
                }
        }
        #else
        fatalError(.unavailable)
        #endif
    }
}
