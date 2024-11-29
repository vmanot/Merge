//
// Copyright (c) Vatsal Manot
//

import FoundationX

/// Represents the color support capabilities of a terminal environment
public enum TerminalColorCapability {
    /// No color support
    case dumb
    /// Basic 16-color ANSI support
    case ansi16
    /// Extended 256-color ANSI support
    case ansi256
    /// Full 24-bit true color support (16 million colors)
    case ansi16m
        
    private static var cachedCapability: TerminalColorCapability?
        
    /// The current terminal's color capability
    public static var current: TerminalColorCapability {
        if let cached = cachedCapability {
            return cached
        }
        
        let capability = determineColorCapability()
        cachedCapability = capability
        return capability
    }

    private static func determineColorCapability() -> TerminalColorCapability {
        let env = ProcessInfo.processInfo.environment
        
        // Early returns for special cases
        if isatty(fileno(stdout)) == 0 {
            return .dumb
        }
        
        if let xcodeService = env["XPC_SERVICE_NAME"], xcodeService.starts(with: "com.apple.dt.Xcode") {
            return .dumb
        }
        
        if let capability = checkCIEnvironment(env) {
            return capability
        }
        
        if let capability = checkTeamCity(env) {
            return capability
        }
        
        if env["COLORTERM"]?.lowercased() == "truecolor" {
            return .ansi16m
        }
        
        if let capability = checkTerminalProgram(env) {
            return capability
        }
        
        if let capability = checkTerminalType(env) {
            return capability
        }
        
        if env["COLORTERM"] != nil {
            return .ansi16
        }
        
        return env["TERM"] == "dumb" ? .dumb : .dumb
    }
    
    private static func checkCIEnvironment(
        _ env: [String: String]
    ) -> TerminalColorCapability? {
        guard env["CI"] != nil else { return nil }
        
        let ciPlatforms = ["TRAVIS", "CIRCLECI", "APPVEYOR", "GITLAB_CI"]
        
        return ciPlatforms.contains {
            env[$0] != nil
        } ? .ansi16 : TerminalColorCapability.dumb
    }
    
    private static func checkTeamCity(
        _ env: [String: String]
    ) -> TerminalColorCapability? {
        guard let version = env["TEAMCITY_VERSION"] else {
            return nil
        }
        
        return version.matches("^(9\\.(0*[1-9]\\d*)\\.|\\d{2,}\\.)") ? .ansi16 : TerminalColorCapability.dumb
    }
    
    private static func checkTerminalProgram(
        _ env: [String: String]
    ) -> TerminalColorCapability? {
        guard let program = env["TERM_PROGRAM"],
              let versionString = env["TERM_PROGRAM_VERSION"],
              let majorVersion = Int(versionString.split(separator: ".").first ?? "") else {
            return nil
        }
        
        switch program {
            case "iTerm.app":
                return majorVersion >= 3 ? .ansi16m : .ansi256
            case "Apple_Terminal":
                return .ansi256
            default:
                return nil
        }
    }
    
    private static func checkTerminalType(
        _ env: [String: String]
    ) -> TerminalColorCapability? {
        guard let term = env["TERM"]?.lowercased() else { return nil }
        
        if term.matches("-256(color)?$") {
            return .ansi256
        }
        
        let patterns = [
            "^screen", "^xterm", "^vt100", "^vt220",
            "^rxvt", "color", "ansi", "cygwin", "linux"
        ]
        
        return patterns.contains(where: { $0.matches("-256(color)?$") }) ? .ansi16 : nil
    }
}
