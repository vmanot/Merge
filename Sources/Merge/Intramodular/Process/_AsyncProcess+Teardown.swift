//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    package func _sendTeardownStepForSystemShellReporting(
        _ step: TeardownStep
    ) -> SystemShell.ControlResult {
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
    }
}
#endif
