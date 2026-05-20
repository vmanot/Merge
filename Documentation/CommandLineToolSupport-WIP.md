# CommandLineToolSupport WIP

Working notes for the CommandLineToolSupport API, current implementation, migrated review context, and remaining completion work.

## Table Of Contents

- [Summary](#summary)
- [Status](#status)
- [Current Execution Increment](#current-execution-increment)
  - [Structured Invocation Arguments](#structured-invocation-arguments)
  - [Collected Output Convenience](#collected-output-convenience)
  - [Fresh Ideation After Execution Records](#fresh-ideation-after-execution-records)
- [Core Concepts](#core-concepts)
  - [Problem Shape](#problem-shape)
  - [`swiftc`](#swiftc)
  - [Design Direction](#design-direction)
- [Current Holes In The Modeling Effort](#current-holes-in-the-modeling-effort)
  - [1. Semantic Argv Is Stored, But Direct Launch Is Partial](#1-semantic-argv-is-stored-but-direct-launch-is-partial)
  - [2. Argument Conversion Still Mixes Semantic Values With Shell Escaping](#2-argument-conversion-still-mixes-semantic-values-with-shell-escaping)
  - [3. Resolved Descriptions Are Close, But Not Yet A Real Intermediate Representation](#3-resolved-descriptions-are-close-but-not-yet-a-real-intermediate-representation)
  - [4. Execution Has Records And Initial Plans, But Plans Are Thin](#4-execution-has-records-and-initial-plans-but-plans-are-thin)
  - [5. Shell Strings Still Carry Too Much Semantic Weight](#5-shell-strings-still-carry-too-much-semantic-weight)
  - [6. Tool Selection Is Modeled, But Composition Boundaries Remain Thin](#6-tool-selection-is-modeled-but-composition-boundaries-remain-thin)
  - [7. Output Formatter Tools Need Standard-Stream Wiring](#7-output-formatter-tools-need-standard-stream-wiring)
  - [8. Invocation Summary Needs Sharper Runtime Diagnostics](#8-invocation-summary-needs-sharper-runtime-diagnostics)
  - [9. Runtime Discipline Is Ahead Of Modeling Discipline](#9-runtime-discipline-is-ahead-of-modeling-discipline)
  - [10. Diagnostics Are Not Yet A First-Class Product](#10-diagnostics-are-not-yet-a-first-class-product)
  - [11. Macro Support Is Alias-Level Only](#11-macro-support-is-alias-level-only)
  - [12. Client Migration Is Still Proving The Abstractions](#12-client-migration-is-still-proving-the-abstractions)
- [Merge Runtime](#merge-runtime)
  - [`CommandLineTool`](#commandlinetool)
  - [`@Parameter`](#parameter)
  - [`@Flag`](#flag)
  - [Key Conversion And Separators](#key-conversion-and-separators)
  - [Multi-Value Encoding](#multi-value-encoding)
  - [Subcommands](#subcommands)
  - [Tool-Selecting Tools](#tool-selecting-tools)
  - [Placement](#placement)
  - [Resolved Description](#resolved-description)
  - [Structured Invocation](#structured-invocation)
  - [Invocation Summary](#invocation-summary)
  - [Output Formatter Tools](#output-formatter-tools)
- [Usage](#usage)
  - [Merge Example: `swift build`](#merge-example-swift-build)
  - [DeveloperAutomation Example: `xcrun swiftc`](#developerautomation-example-xcrun-swiftc)
  - [DeveloperAutomation Example: `git2`](#developerautomation-example-git2)
- [Prior Art And Signals](#prior-art-and-signals)
  - [Comparable Ecosystems](#comparable-ecosystems)
  - [Swift-Specific Signals](#swift-specific-signals)
  - [Swift-Side Read](#swift-side-read)
  - [What To Borrow](#what-to-borrow)
  - [What Not To Copy](#what-not-to-copy)
- [Design Decisions](#design-decisions)
- [Completion Work](#completion-work)
- [Suggested Plan](#suggested-plan)
- [DeveloperAutomation Models](#developerautomation-models)
  - [`xcrun`](#xcrun)
  - [`xcrun swiftc`](#xcrun-swiftc)
  - [`ModuleTrace`](#moduletrace)
  - [`git`](#git)
  - [`tar`](#tar)
  - [`xcodebuild`](#xcodebuild)
- [DeveloperAutomation Completion Work](#developerautomation-completion-work)
- [DeveloperAutomation Plan](#developerautomation-plan)
- [Original Author Review Context](#original-author-review-context)
- [Assessment](#assessment)

## Summary

CommandLineToolSupport is a Swift model for **importing existing command line tools** into Swift. It is the reverse direction of Swift Argument Parser:

| Tooling | Direction |
| --- | --- |
| Swift Argument Parser | Swift code -> exported CLI |
| CommandLineToolSupport | Existing CLI -> Swift model |

The goal is to replace hand-built shell strings with typed command models:

```swift
try xcrun(sdk: sdkPath).swiftc()
    .with(\.target, "arm64e-apple-macos26.1")
    .with(\.moduleName, "Dummy")
    .with(\.inputFiles, [sourceFileURL])
    .with(\.mode, .typecheck)
    .with(\.emitLoadedModuleTracePath, .stdout)
    .invocation
```

Current implementation spans:

- **Merge:** reusable `CommandLineToolSupport` runtime.
- **DeveloperAutomation:** real wrappers and examples: `xcrun swiftc`, `xcodebuild`, `git`, `tar`, small fixtures.

## Status

| Area | Current State | Remaining Work |
| --- | --- | --- |
| Core runtime | Property wrappers, resolution, subcommands, structured invocation, summaries. | Public naming, typed errors, argv semantics, more edge tests. |
| `@Parameter` | Named options, positional args, separators, key conversion, optionals, arrays, placement. | Per-argument override tests, multi-value tests. |
| `@Flag` | Bool, optional inversion, counters, custom typed flags, mode flags, explicit render-default initializer for constructor-backed models. | Decide accumulating flag/option API; improve inference diagnostics/ergonomics. |
| Subcommands | `@Subcommand`, `GenericSubcommand`, nested command chains. | Lighter inline/simple-subcommand path; keep distinct from selected tools. |
| Resolved model | `_ResolvedCommandLineToolDescription` for args/options/flags/subcommands. | Preserve model structure while deriving flattened argv/rendering. |
| Invocation summaries | Property references, parent refs, `When`, `Switch`, `Case`, `DefaultCase`; parent projection is now covered by Merge tests. | API review: naming, lowering, diagnostics, parent projection visibility. |
| `xcrun swiftc` | Primary real-world model, loaded-module-trace invocation renders. | Finish actual execution/decoding and replace manual call site. |
| `xcodebuild` | Partially migrated to typed parameters/env vars. | Preserve compatibility while replacing manual serialization. |
| `git` / `tar` | Stress tests for placement, subcommands, counters, typed flags. | Move generic examples into Merge tests or proper modules. |
| `xcbeautify` | Implemented in DeveloperAutomation as `CLT.xcbeautify`; conforms to Merge WIP `CommandLineToolOutputFormatterTool`. | Move from compatibility attachment into a first-class composition API once execution strategy is clearer. |
| Shell execution | Still real-shell coupled. | Make testable, preferably with injectable executor on concrete `SystemShell`. |
| Execution records | Provisional `_CommandLineToolExecutionRecord<Tool>` and `_CommandLineToolExecutionSource` exist; `_run` is additive and underscored on `CommandLineTool`; `_runCollectingOutput` now captures without terminal mirroring. | Decide operation identity, public promotion path, external-client extension story, and structured argv vs shell-string split. |
| Output formatter tools | WIP `CommandLineToolOutputFormatterTool` exists under `Intramodular (WIP)`; execution plans can carry nested `StandardStreamWiring`. | Decide public composition API without exposing the compatibility attachment used by `CLT.xcodebuild`. |

## Current Execution Increment

The first execution-model increment is intentionally conservative and additive.

Implemented shape:

```swift
public struct _CommandLineToolExecutionRecord<Tool: AnyCommandLineTool> {
    public let tool: Tool
    public let source: _CommandLineToolExecutionSource
    public let processResult: Process.RunResult
    public let selectedToolInvocation: _CommandLineToolSelectedToolInvocation?
}

public enum _CommandLineToolExecutionSource: Hashable, Sendable {
    case modeledInvocation(CommandLineToolInvocation)
    case shellCommandLine(String)
}
```

`CommandLineTool._run(applying:)` records `.modeledInvocation`.
`CommandLineTool._run(command:input:applying:)` records `.shellCommandLine`.
The existing `callAsFunction() async throws -> Process.RunResult` surface remains source-compatible.

This is not the final public execution API. It creates a typed carrier that clients can extend while preserving current call sites:

```swift
let record = try await CLT.xcodebuild(...)._run(
    command: serializedCommand(action: "-showBuildSettings -json"),
    applying: .standardStreamMirroring(.disabled)
)

let settings = try record.decode([CLT.xcodebuild.BuildSettings].self)
```

The source split matters because several real wrappers still render pipelines or hand-built command lines. Those calls should not pretend to have a complete `CommandLineToolInvocation`.

Important Swift constraint: class methods cannot return `_CommandLineToolExecutionRecord<Self>` from `AnyCommandLineTool`, because covariant `Self` cannot appear nested inside a generic result. The typed `_run` API therefore lives on `CommandLineTool` for now.

Open design work after this increment:

- whether operation identity should become `_CommandLineToolExecutionRecord<Tool, Operation>` or remain client-owned wrapper metadata;
- how external modules customize/extend records when they do not own the tool model;
- whether a provider-at-call-site hook is worth adding before the carrier stabilizes;
- how to separate semantic argv from shell-rendered strings without breaking existing string-heavy wrappers;
- when, if ever, underscored `_run` becomes public `run`.

### Structured Invocation Arguments

`CLT.git` exposed a useful boundary problem: a wrapper can have a valid modeled root command while still not deserving fully typed nested models for every subcommand/action. The bad shape is:

```swift
git model -> serializedCommand(action: String) -> shell string -> execution record
```

The specific smell is not that `git` has domain methods. Domain methods are the point of that wrapper. The smell is that each method has to manually reconstruct root identity and root options before appending a raw action blob.

The WIP middle layer is `CommandLineToolInvocation.Arguments`:

```swift
let record = try await CLT.git(localRepositoryURL: checkoutURL)._run(
    appending: ["checkout", "-b", branchName]
)
```

That is the target shape, but it is not fully true for `CLT.git` yet. In the current DeveloperAutomation migration, `CLT.git` still uses a small `_runGit(_:)` bridge because its root `-C` URL needs to be rendered as a semantic path component instead of going through legacy `URL.argumentValue` shell escaping.

The desired composition is:

```swift
git -C <checkoutURL> checkout -b <branchName>
```

with `git -C <checkoutURL>` coming from the modeled root tool and `checkout -b <branchName>` coming from appended arguments. The remaining blocker is not `git` itself; it is that argument conversion, invocation storage, and POSIX rendering still overlap.

This deliberately does not make `git checkout`, `git push`, or `git rev-parse` full nested command types yet. `git` has a huge, irregular surface, and most local client value is in domain methods like `currentBranch()`, `origin()`, and `pull()`. Appended invocation arguments let those methods stop hand-rendering command lines while still leaving high-value subcommands free to graduate into real models later.

The implemented WIP API is:

```swift
extension CommandLineToolInvocation {
    public struct Arguments {
        public var elements: [CommandLineToolInvocation.Argument]
    }
}

extension CommandLineTool {
    public func _invocation(
        appending arguments: CommandLineToolInvocation.Arguments
    ) throws -> CommandLineToolInvocation

    public func _run(
        appending arguments: CommandLineToolInvocation.Arguments,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self>
}
```

Important semantics:

- Appended-argument execution records `.modeledInvocation`, not `.shellCommandLine`.
- The source record still uses `CommandLineToolInvocation`, so existing execution record helpers keep working.
- Plain modeled invocations now have a first direct executable-plus-argv lowering path. Selected-tool invocations intentionally still use rendered command lines until selected-tool resolution semantics are represented in the launch plan.
- `_run(command:)` remains the honest escape hatch for pipelines, shell operators, and legacy hand-rendered strings.

This gives clients an incremental migration ladder:

| Current Shape | Better Increment | Later Graduation |
| --- | --- | --- |
| `serializedCommand(action: "checkout -b \"\(name)\"")` | `_run(appending: ["checkout", "-b", name])` | typed `GitCheckoutTool` if repeated enough |
| `serializedCommand(action: "rev-parse --abbrev-ref HEAD")` | `_run(appending: ["rev-parse", "--abbrev-ref", "HEAD"])` | domain `currentBranch()` keeps returning `Branch` |
| `serializedCommand(action: "diff -- ... | parser")` | keep `_run(command:)` | explicit pipeline/formatter model later |

The next pressure point is execution correctness across the hard cases. `CommandLineToolInvocation.Argument` is now the stored carrier, and plain modeled invocations can execute without shell stringification, but selected tools, formatter pipelines, builtins, and shell operators still require explicit modeling before they can honestly become direct launch plans.

### Collected Output Convenience

The current execution increment also adds a shared spelling for the common "capture output, do not mirror to terminal" mode:

```swift
try await tool._runCollectingOutput(appending: ["status", "--porcelain"])
```

This lowers to the existing configuration difference:

```swift
SystemShell.Configuration.Difference._collectingOutput
```

which is currently equivalent to:

```swift
.standardStreamMirroring(.disabled)
```

This name borrows the Swift Subprocess vocabulary of "collected output" instead of introducing tool-specific helpers like `runQuietGit`. It is still provisional and underscored. The important semantic point is that "collecting output" does **not** mean discarding stdout/stderr; it means stdout/stderr are captured in the returned record without also being mirrored to the terminal.

### Fresh Ideation After Execution Records

The agent review after the first `_CommandLineToolExecutionRecord` increment produced a few useful design constraints. These are not final decisions, but they are the current best candidates to evaluate next.

#### Working Principles

- Keep the base record factual: tool, execution source, process result, and eventually launch plan / operation identity.
- Do not force every command into a modeled invocation while real wrappers still use pipelines and hand-rendered shell text.
- Do not add provider protocols or associated result types until operation-specific wrappers prove repeated boilerplate.
- Put domain semantics near domain operations first: `git.pull`, `xcodebuild.build`, `gh.executeGitHubCommand`, `defaults.read`.
- Keep compatibility wrappers returning `Process.RunResult` or decoded domain values until downstream clients have adopted richer APIs.

#### 1. Structured Launch Representation Before Richer Records

The next likely Merge increment is a launch/source value that can represent executable-plus-argv separately from shell text. This lets wrappers migrate `gh`, `defaults`, and simple `git` calls without pretending pipelines are argv-safe.

Sketch:

```swift
public enum _CommandLineToolExecutionSource: Hashable, Sendable {
    case modeledInvocation(CommandLineToolInvocation)
    case executable(name: String, arguments: [String])
    case shellCommandLine(String)
}
```

Possible execution API:

```swift
extension CommandLineTool {
    public func _run(
        executable name: String,
        arguments: [String],
        input: String? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self>
}
```

Examples:

```swift
try await CLT.gh()._run(
    executable: "gh",
    arguments: ["auth", "status"],
    applying: .standardStreamMirroring(.disabled)
)

try await CLT.defaults()._run(
    executable: "defaults",
    arguments: ["read", domain, key]
)
```

Shell strings remain necessary for pipelines and legacy renderings:

```swift
try await xcodebuild._run(
    command: serializedCommand(action: "-list -json | awk '/^{/,/^}/'")
)
```

This should not be framed as “replace shell strings everywhere.” It is a safer path for invocations that do not require shell grammar.

#### 2. Operation Identity Should Be Value Metadata First

Do not make operation identity a second generic parameter yet:

```swift
// Too early:
_CommandLineToolExecutionRecord<Tool, Operation>
```

That would make storage/erasure harder before launch semantics are stable. A lower-risk direction is optional value metadata:

```swift
public struct _CommandLineToolOperationIdentity: Hashable, Sendable {
    public let name: String
    public let kind: Kind

    public enum Kind: Hashable, Sendable {
        case modeledCommand
        case domainMethod
        case helper
    }
}
```

Examples:

| Operation | Candidate identity |
| --- | --- |
| `xcodebuild.build()` | `name: "build", kind: .domainMethod` |
| `xcodebuild.list()` | `name: "list", kind: .domainMethod` |
| `git.pull()` | `name: "pull", kind: .domainMethod` |
| `gh.executeGitHubCommand(...)` | `name: "gh", kind: .helper` |
| `defaults.read(...)` | `name: "read", kind: .domainMethod` |

This lets clients inspect operation intent without committing to a full operation type hierarchy.

#### 3. Operation Records Should Start In Client Packages

A base `_CommandLineToolExecutionRecord<Tool>` is not enough to represent `git pull` fallback state, `xcodebuild build` formatter use, or decoded `xcodebuild -showBuildSettings` values. Those should begin as explicit operation records near the domain methods:

```swift
extension CLT.git {
    public struct PullExecutionRecord {
        public let primary: _CommandLineToolExecutionRecord<CLT.git>
        public let fallback: _CommandLineToolExecutionRecord<CLT.git>?
        public let remoteOrigin: Remote?
        public let usedHTTPSOverride: Bool

        public var processResult: Process.RunResult {
            fallback?.processResult ?? primary.processResult
        }
    }
}
```

```swift
extension CLT.xcodebuild {
    public struct DecodedExecutionRecord<Value> {
        public let execution: _CommandLineToolExecutionRecord<CLT.xcodebuild>
        public let value: Value
    }
}
```

Compatibility shape:

```swift
public func pull(...) async throws -> Process.RunResult {
    try await pullExecution(...).processResult
}

public func showBuildSettings() async throws -> [BuildSettings] {
    try await showBuildSettingsExecution().value
}
```

This gives diagnostics and fallback metadata to clients that need it while leaving existing APIs intact.

#### 4. Defer Provider Protocols And Associated Result Types

Associated result types make cross-module customization and existential use worse. Provider protocols are implementable, but premature. Prefer plain wrappers and small transform ergonomics first:

```swift
let record = try await tool._run(command: command)
let domainRecord = XcodebuildBuildRecord(record)
```

Possible lightweight transform API:

```swift
extension _CommandLineToolExecutionRecord {
    public func map<T>(
        _ transform: (_CommandLineToolExecutionRecord<Tool>) throws -> T
    ) rethrows -> T {
        try transform(self)
    }

    public func mapValidated<T>(
        _ transform: (_CommandLineToolExecutionRecord<Tool>) throws -> T
    ) throws -> T {
        try validate()
        return try transform(self)
    }
}
```

If repeated provider-style construction eventually appears, prefer putting provider conversion on the record rather than infecting `CommandLineTool`:

```swift
public protocol _CommandLineToolExecutionRecordProvider {
    associatedtype Tool: AnyCommandLineTool
    associatedtype Record

    static func makeRecord(
        from record: _CommandLineToolExecutionRecord<Tool>
    ) throws -> Record
}
```

This remains a later option, not the immediate next step.

#### 5. Macro Affordances Should Stay Inert

Macros should keep declaring boilerplate, not running things. The current macro spelling is `@CommandLineTool`, and its job is deliberately small: synthesize the obvious `CommandLineTool` conformance for old and new model styles without generating execution behavior.

```swift
@CommandLineTool
final class swiftc: AnyCommandLineTool {
    override var _commandName: String { "swiftc" }
}
```

Useful boundary:

- Do not generate `_run`.
- Do not generate typealiases for execution records.
- Do not infer operation identity from method bodies.
- Do not generate validation, decoding, retries, or shell configuration.
- Do not attempt semantic conformance checking from SwiftSyntax.

If operation identity becomes real, a macro can generate explicit inert metadata only:

```swift
@_CommandLineToolOperation("build")
public func build() async throws -> Process.RunResult { ... }
```

That macro should require explicit string literals and should not parse function bodies looking for `serializedCommand(action:)`.

#### 6. Live Tool Reference vs Execution Snapshot

`_CommandLineToolExecutionRecord.tool` is useful for typed ergonomics but is a live class reference, not a snapshot. The trustworthy execution snapshot is:

```swift
record.source
record.commandLine
record.processResult
```

If this becomes painful, add a value snapshot rather than making the full record `Sendable`/`Hashable` prematurely:

```swift
public struct _CommandLineToolExecutionSnapshot {
    public let source: _CommandLineToolExecutionSource
    public let processResult: Process.RunResult

    public var commandLine: String {
        source.commandLine
    }
}
```

#### 7. Erased Base-Class Execution Is Separate From Typed `_run`

Because `AnyCommandLineTool` is a class, it cannot expose `_CommandLineToolExecutionRecord<Self>`. If base-class execution becomes necessary, use a separate erased record:

```swift
public struct _AnyCommandLineToolExecutionRecord {
    public let tool: AnyCommandLineTool
    public let source: _CommandLineToolExecutionSource
    public let processResult: Process.RunResult
}
```

Do not contort `AnyCommandLineTool` into a generic/protocol-only root just to preserve a typed `Self` return.

#### 8. Concrete Client Pressure Points

| Area | Remaining friction | Candidate next API |
| --- | --- | --- |
| `xcodebuild list` / `showBuildSettings` / `showSDKs` | Decode failures lose command/stderr context; error extraction is inconsistent. | `DecodedExecutionRecord<Value>` siblings and consistent `CLT.xcodebuild.Error(from:)` handling. |
| `xcodebuild build` | Return value cannot tell whether output formatting/pipelines were used. | `BuildExecutionRecord` with formatter/pipeline metadata. |
| `git pull` | Final `Process.RunResult` hides fallback attempt and remote URL context. | `PullExecutionRecord` with primary/fallback records and override metadata. |
| `gh` | Joins `[String]` with spaces; cwd/PATH/sink disappear after execution. | `_run(executable:arguments:)` and `CommandExecutionRecord`. |
| `defaults` | `read/write` are raw/stringly typed; downstream bypasses wrapper for bools. | `readString`, `readBool`, `write(... bool:)`, `write(... string:)`. |

#### 9. Suggested Increment Order

1. Merge: add structured executable-plus-argv source/execution.
2. Merge: add snapshot/transform ergonomics only if immediately useful.
3. DeveloperAutomation: add operation records for `git.pull`, `xcodebuild` decoded operations, and `gh` command execution.
4. DeveloperAutomation: add typed `defaults` conveniences and migrate bypassing call sites.
5. Macro: add extension-aware `_CommandLineToolModel` aliases if the alias boilerplate appears in real code.

## Core Concepts

### Problem Shape

Real automation code shells out to tools like `xcrun`, `swiftc`, `xcodebuild`, `git`, `tar`, `codesign`, `lipo`, `plutil`, and `simctl`. Without a model, invocations become string concatenation. That hurts reviewability, testability, autocomplete, diagnostics, and future parsing.

The intended model should:

- reflect CLI parameters/options/flags as Swift properties;
- preserve real CLI syntax differences;
- support nested subcommands;
- preserve enough resolved metadata for diagnostics/autocomplete/parsing;
- allow custom invocation summaries for tools whose rendering is not simple declaration order.

### `swiftc`

`swiftc` has the shape:

```console
swiftc [MODE] [OPTIONS...] files...
```

Important constraints:

- `[MODE]` acts like a mode selector, not a normal bool flag.
- Multiple modes can appear; the last matching mode wins.
- Modes should be typed, not raw strings.
- `xcrun swiftc` is the primary proving ground.

### Design Direction

Use command/subcommand composition:

```swift
xcrun().swiftc()
```

means:

```console
xcrun swiftc
```

Avoid pure argument-group modeling as the only design because:

- command order is not reliably captured by property declaration order;
- argument groups may need command names, which conflicts with command types;
- not every command has arguments, but every command still has a command name.

Use option groups only where they reduce duplication without pretending shared arguments are global.

## Current Holes In The Modeling Effort

This section is intentionally blunt. CommandLineToolSupport is trying to model the missing Swift ecosystem layer between "I have a typed command schema" and "I launched a child process." The current implementation has many useful pieces, but several boundaries are still too soft.

The target pipeline should become:

```swift
tool model -> resolved description -> semantic invocation -> launch plan -> execution record -> domain record/value
```

The current pipeline is closer to:

```swift
tool model -> runtime reflection -> [String] -> shell command line -> Process.RunResult
```

That is why clients like `CLT.git`, `CLT.xcodebuild`, `CLT.gh`, and `CLT.defaults` still leak rendering/execution mechanics into domain methods.

### 1. Semantic Argv Is Stored, But Direct Launch Is Partial

`CommandLineToolInvocation.Argument` now exists and can store strings or raw bytes, and `CommandLineToolInvocation` itself now stores grammar-aware components:

```swift
public var components: [CommandLineToolInvocation.Component]
```

This fixes the old storage bug where `CommandLineToolInvocation(components: [Argument])` immediately mapped arguments to `rawValue` and lost storage identity. The remaining modeling hole is making sure every lowering layer preserves whether a value is:

- a semantic argv token;
- a shell-rendered word;
- an opaque byte sequence;
- a display-only component;
- a joined `--key=value` token that actually contains both key and value.

The first direct launch path now uses these arguments for plain executable-plus-argv modeled invocations. The remaining durable shape is preserving the same argument identity through selected tools, formatters, shell builtins, and other executions that cannot be honestly lowered to a single executable plus argv yet.

### 2. Argument Conversion Still Mixes Semantic Values With Shell Escaping

`CLT.ArgumentValueConvertible.argumentValue` should mean "semantic argv value." It currently still carries legacy shell-rendering behavior for `URL`:

```swift
extension URL: CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        path.replacing(" ", with: "\\ ")
    }
}
```

That is why `CLT.git` cannot blindly rely on the modeled `@Parameter(name: "C")` root path while the new POSIX shell renderer is active: the path may already contain backslash escaping before it reaches `CommandLineToolInvocation.Argument`.

The compatibility-preserving migration should be:

| Layer | Meaning |
| --- | --- |
| `argumentValue` | Semantic, unescaped argv value. |
| shell renderer | Escapes semantic values for a chosen shell dialect. |
| display renderer | Produces readable command text for logs/docs. |
| deprecated URL behavior | Preserved only behind explicit legacy API, not as the default semantic conversion. |

This also applies to `String`, raw bytes, `Process.ArgumentLiteral`, and future path/file abstractions. Quoting belongs at a rendering boundary, not inside domain value conversion.

### 3. Resolved Descriptions Are Close, But Not Yet A Real Intermediate Representation

`_ResolvedCommandLineToolDescription` is the right direction: it preserves arguments, flags, options, subcommands, IDs, and placement. But it still flattens too early:

```swift
var invocationArgumentValues: [CommandLineToolInvocation.Argument]
var invocationArguments: [String]
var invocationArgument: String?
```

The resolved model should become a durable IR with enough structure to answer:

- Which property produced this token?
- Is this an option key, option value, flag, positional argument, command name, selected-tool name, separator, or subcommand token?
- Did this value come from a default, an explicit user assignment, a summary branch, or a parent projection?
- Is this argument repeated because the property is an array, because the flag is a counter, or because a summary intentionally emitted it more than once?
- Can this resolved value be parsed back into the model?

The immediate risk is that `_ResolvedCommandLineToolDescription.Option` currently creates joined tokens for non-space separators:

```swift
"\(key)\(separator.rawValue)\(convertible.argumentValue)"
```

That is valid argv for many tools, but semantically it hides the key/value boundary. The IR should preserve both and let renderers decide whether to join.

### 4. Execution Has Records And Initial Plans, But Plans Are Thin

`_CommandLineToolExecutionRecord<Tool>` is useful, but it records after the fact:

```swift
public let source: _CommandLineToolExecutionSource
public let processResult: Process.RunResult
```

The first pre-execution value now exists as `_CommandLineToolExecutionPlan<Tool>`. It carries the tool, source, standard input, configuration differences, and selected-tool metadata, and it is the right place to keep moving execution decisions before they become a `Process.RunResult`.

The remaining thinness is deliberate:

- modeled invocations can lower directly only when they are plain executable-plus-argv shapes;
- selected-tool invocations still fall back to rendered command lines until selecting-tool resolution becomes explicit;
- formatter/pipeline composition still has nowhere honest to live;
- records do not yet expose whether a process was shell-mediated or directly launched.

The next plan increment is not a richer result first. It is making the plan expose execution strategy explicitly:

```swift
public enum _CommandLineToolExecutionStrategy {
    case directExecutable(CommandLineToolInvocation.ExecutableInvocation)
    case shellCommandLine(String)
}
```

That should stay separate from `_CommandLineToolExecutionSource`, which is still compatibility-sensitive metadata about where the execution came from.

### 5. Shell Strings Still Carry Too Much Semantic Weight

`CommandLineTool.invocation` returns a string, `callAsFunction()` executes that string, and several domain clients still produce pipelines or quoted fragments manually.

This is acceptable for compatibility, but it should not be the conceptual center. There are at least three renderers hiding under one name:

| Renderer | Purpose | Example |
| --- | --- | --- |
| Display renderer | Human-readable logs/docs. | `git -C /tmp/repo status` |
| Shell renderer | Safe command line for a specific shell dialect. | `'git' '-C' '/tmp/a b' 'status'` |
| Argv renderer | Direct executable plus argv. | executable `git`, argv `["-C", "/tmp/a b", "status"]` |

`commandLine` should not be treated as proof that a value is safe to execute. Existing APIs can remain, but newer APIs should name which renderer they mean.

### 6. Tool Selection Is Modeled, But Composition Boundaries Remain Thin

Selected-tool modeling now distinguishes `xcrun swiftc` from `git remote`, which is correct. The remaining holes are:

- selected-tool metadata is a sidecar on execution records rather than part of the invocation IR;
- selected-tool wrappers forward `withUnsafeSystemShell` to the selected tool, which may be surprising for ownership/session tracking;
- selected-tool command names can be overridden, but this override is not represented as an IR token distinct from the selected tool's underlying `_commandName`;
- execution through selecting tool vs direct resolved executable is described semantically but not implemented as a launch distinction.

The sidecar strategy is a good compatibility increment. It should not become the final model if selected-tool chains need parsing, documentation, completion, or launch-plan behavior.

### 7. Output Formatter Tools Need Standard-Stream Wiring

`CommandLineToolOutputFormatterTool` names the concept, and `CLT.xcbeautify` proves the concrete pressure. But there is still no model for:

- piping stdout from one modeled invocation into another;
- preserving both the base tool record and formatter tool record;
- representing formatter failure separately from base process failure;
- mirroring or collecting pre-format vs post-format output;
- keeping current hardcoded `CLT.xcodebuild` behavior source-compatible.

The abstraction should not be "formatter as argument." It is closer to execution wiring:

```swift
xcodebuild invocation -> stdout stream -> xcbeautify invocation -> terminal / collected output
```

The current increment is `_CommandLineToolExecutionPlan.StandardStreamWiring`. The name is deliberately nested under the execution plan: it is not a general process-graph type, not a Foundation `Pipe`, and not an OS port concept.

```swift
_CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring(
    stages: [
        .init(role: .primaryInvocation, commandName: "xcrun xcodebuild"),
        .init(role: .external, commandName: "xcodebuild-build-progress-observation"),
        .init(
            role: .outputFormatterTool,
            commandName: "xcbeautify",
            streamEffects: [.humanReadableFormatting]
        )
    ],
    streamConnections: [
        .init(
            output: .init(stageID: xcodebuildStage.id, stream: .standardOutput),
            input: .init(stageID: buildProgressObservationStage.id, stream: .standardInput)
        ),
        .init(
            output: .init(stageID: buildProgressObservationStage.id, stream: .standardOutput),
            input: .init(stageID: formatterStage.id, stream: .standardInput)
        )
    ]
)
```

The standard-stream vocabulary is nested inside `StandardStreamWiring`. There is intentionally no global `_CommandLineToolStandardStream` enum; a standalone stream enum would be too broad and would invite unrelated code to depend on an underfledged noun.

Validation currently checks:

- every referenced stage exists;
- connection outputs are producer-side endpoints: `standardOutput` or `standardError`, not `standardInput`;
- connection inputs are consumer-side endpoints: `standardInput`, not `standardOutput` or `standardError`;
- one output endpoint does not fan out accidentally;
- one input endpoint does not receive multiple upstream outputs accidentally;
- stage traversal is acyclic;
- repeated exclusive formatter stream effects fail.

Current runtime errors are intentionally conservative. Accidental fanout/fanin is rejected because we do not yet have a first-class tee/broadcast/merge model. Backwards endpoint directions are rejected because a standard input stream cannot produce bytes for another stage, and a standard output/error stream should not be treated as a receiving side of a connection.

The model does allow independent stream walks to apply the same exclusive stream effect. This matters for scenarios where one execution plan carries multiple unrelated producer/formatter chains; exclusivity is per stream walk, not global across the entire plan.

The formatter remains semantic metadata on the command-line tool model. The stream connection is topology: stdout flows into stdin. Those are related, but they are not the same abstraction.

The first public increment can stay smaller, but the model must not erase the distinction between a command's arguments and a downstream output transformer.

### 8. Invocation Summary Needs Sharper Runtime Diagnostics

Invocation summaries are important because declaration order is not enough. Runtime reflection and preconditions are not inherently bad pressure here: they are valid tools for encoding framework invariants and developer discipline when static Swift cannot express the shape. The problem is weaker diagnostics when reflection-derived failures are far from the declaration that caused them.

Holes:

- poor typed diagnostics when a summary references a property incompatible with the active command/parent;
- unclear story for illegal combinations that should be runtime developer errors;
- unclear story for schema export/documentation;
- unclear story for command-line parsing back into a model;
- parent projection is useful but still not cleanly exposed as public API vocabulary.

The AppIntents-style direction remains good: summaries should be inspectable syntax trees, not arbitrary Swift control flow. Runtime checks should stay, but the failure surface should become sharper and more local: declaration metadata, resolved descriptions, and command invocation components should carry enough structure to explain exactly which modeled argument could not lower.

New coverage from the WIP suite sharpened a few rules:

- explicit value references suppress default fallback rendering for that same modeled argument;
- `.isPresent` treats empty strings and empty collections as absent;
- ordinary Swift result-builder branches are supported, but the first-class `When` / `Switch` nodes remain the preferred inspectable shape;
- `Switch` can now be expressed without a `DefaultCase`, and a non-matching value throws at runtime instead of silently producing an invocation.

That last point is useful for dogfooding, but the diagnostic is still too weak. A production-grade reverse argument parser should say which summary switch failed, which modeled value was inspected, and which cases were available.

### 9. Runtime Discipline Is Ahead Of Modeling Discipline

`AnyCommandLineTool` and `SystemShell` now have useful runtime discipline around borrowed shells, shell sessions, lifecycle state, observable change, and kill semantics. That work is ahead of the modeling layer.

The gap: command modeling does not yet produce enough structured launch metadata for the runtime to reason about ownership and process trees at the command-model level.

Eventually, a command execution should be able to answer:

- Which modeled tool initiated this process?
- Was it selected through another tool?
- Was output formatted through another modeled tool?
- Which shell/session/scope owns the launched process?
- Which high-level domain operation produced this process?

Execution records are the first carrier, but launch plans and operation records are the missing connective tissue.

### 10. Diagnostics Are Not Yet A First-Class Product

Today, many failures are still assertions, preconditions, force casts, or generic process failures. For a modeling framework, diagnostics are product surface:

- invalid wrapper type;
- unsupported value type;
- duplicate/conflicting option emission;
- parent reference cannot resolve;
- selected tool cannot be rendered;
- shell rendering impossible for raw bytes;
- execution failed after formatter succeeded/failed;
- decoded stdout failed validation.

These should become typed rendering/modeling errors where they can be caused by client code. Assertions should be reserved for impossible internal corruption.

### 11. Macro Support Is Alias-Level Only

The macro story is intentionally conservative right now: aliases only. That is correct for the current stage, but it leaves holes:

- no compile-time check that a command model has a valid `_commandName`;
- no generated schema metadata;
- no generated operation identity;
- no help/docs export;
- no warnings for property wrappers that cannot resolve.

This should not be fixed by making macros execute or infer behavior from method bodies. If expanded, macros should generate inert metadata that the runtime can inspect and validate.

### 12. Client Migration Is Still Proving The Abstractions

The real test is not whether examples render. It is whether DeveloperAutomation clients get simpler:

| Client Pressure | Current Lesson |
| --- | --- |
| `CLT.git` | Needs structured appended arguments, semantic URL/path rendering, collected output, and domain records for fallback-heavy operations like `pull`. |
| `CLT.xcodebuild` | Needs formatter composition, decoded execution records, and a way to preserve hardcoded behavior while moving toward explicit metadata. |
| `CLT.gh` | Needs executable-plus-argv execution and scoped environment/PATH without shell string joining. |
| `CLT.defaults` | Needs typed read/write conveniences and collected output as the default for probes. |
| `xcrun`/selected tools | Needs selected-tool metadata to move from sidecar into the invocation/launch model. |

The near-term rule should be: every new helper added to a client should either disappear after a shared abstraction lands, or document the exact shared abstraction it is waiting on.

## Merge Runtime

### `CommandLineTool`

Core shape:

```swift
public protocol CommandLineTool: AnyCommandLineTool {
    associatedtype SummaryContent: CommandLineToolInvocationSummary.InvocationSummary

    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command>
    var invocationSummary: SummaryContent { get }
}
```

Default behavior renders reflected arguments:

```swift
public var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
    CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>()
}
```

### `@Parameter`

Models named options and positional arguments.

Supports:

- `name == nil` for positional arguments;
- command-level and per-argument key conversion;
- separators: space, equal, plus, colon;
- optional values;
- arrays;
- multi-value encoding;
- placement hints.

Example:

```swift
@Parameter(name: "target")
public var target: String? = nil

@Parameter(name: "emit-loaded-module-trace-path")
public var emitLoadedModuleTracePath: EmitLoadedModuleTracePath? = nil

@Parameter(name: nil)
public var inputFiles: [URL] = []
```

### `@Flag`

Must support more than `Bool`.

Supported:

- bool flags;
- optional bool inversion: `--no-*`, `--enable-*`, `--disable-*`;
- counter flags: `-v`, `-vv`;
- typed flags via `CLT.OptionKeyConvertible`;
- arrays of typed flags.

Examples:

```swift
@Flag(name: "enable-library-evolution")
public var enableLibraryEvolution: Bool = false

@Flag(name: "sandbox", inversion: .prefixedNo)
var sandbox: Bool? = nil

@Flag(name: "v")
var verbose: Int = 0

@Flag
public var mode: Mode? = nil
```

Typed mode:

```swift
public enum Mode: String, CaseIterable, Sendable, CLT.OptionKeyConvertible {
    public var name: String { rawValue }
    public var conversion: _CommandLineToolOptionKeyConversion { .hyphenPrefixed }

    case typecheck = "typecheck"
    case dumpAST = "dump-ast"
    case emitSIL = "emit-sil"
}
```

Constructor-backed boolean flags now have an explicit render-default initializer. This matters when a model initializes property-wrapper storage in `init`: the current value to render and the value that suppresses rendering are not always the same thing.

```swift
@Flag(name: "disable-colored-output")
var disableColoredOutput: Bool = false

init(disableColoredOutput: Bool = false) {
    self._disableColoredOutput = Flag(
        wrappedValue: disableColoredOutput,
        defaultValue: false,
        name: "disable-colored-output"
    )

    super.init()
}
```

This preserves the ordinary declaration-site default behavior:

```swift
@Flag(name: "verbose")
var verbose: Bool = false
```

Friction still visible:

- a `@Flag` property without a declaration-site default can produce poor wrapper-overload inference;
- constructor-backed wrappers still require touching underscored storage;
- `defaultValue` should be documented as the render-suppression value, not necessarily as the initial current value.

### Key Conversion And Separators

Keep these independent:

| Concern | Examples |
| --- | --- |
| Key spelling | `-sdk`, `--sdk`, `/out` |
| Separator | `-o path`, `--color=auto`, `/out:program.exe` |
| Value conversion | `URL`, enum raw values, custom values |
| Multi-value encoding | `-Xcc a -Xcc b` vs `--platform ios macOS` |

Example:

```swift
@Parameter(name: "triple", separator: .equal)
var triple: String? = nil
```

renders:

```console
--triple=arm64-apple-macosx15.0
```

### Multi-Value Encoding

Current model:

```swift
public enum MultiValueParameterEncodingStrategy {
    case singleValue
    case spaceSeparated
}
```

Important unresolved modeling choice:

| Representation | Resolved Items | Empty/Nil Expressible | ID Uniqueness |
| --- | --- | --- | --- |
| Flatten each value | `-H a`, `-H b` become two resolved items | No | No |
| Preserve modeled property | `headers` is one resolved item with many values | Yes | Yes |

Preferred direction: preserve modeled structure; flatten separately for rendering/argv.

### Subcommands

Purpose: model a CLI grammar path as typed property access.

```console
xcrun swiftc ...
git remote update ...
swift build ...
```

should be represented as:

```swift
xcrun().swiftc()
git2().remote().update()
ExampleSwiftTool().build()
```

This matters because subcommands are not just arguments. A selected subcommand changes which options are valid, where parent arguments render, and what later completion/documentation/diagnostics should expose.

Older experimental style used `@Subcommand` for `xcrun.swiftc`/`xcrun.simctl`. That was convenient but semantically wrong for tools selected through `xcrun`: `swiftc` and `simctl` are independent command-line tools, not children in `xcrun`'s own command grammar.

Correct subcommand style remains appropriate for real grammar-owned subcommands:

```swift
public final class git: AnyCommandLineTool, CommandLineTool {
    @Subcommand(of: git.self, name: "remote", command: remote())
    public var remote
}

extension git {
    public final class remote: AnyCommandLineTool, CommandLineTool {
        @Subcommand(of: remote.self, name: "update", command: update())
        public var update
    }
}
```

Subcommand wrappers name three things:

| Piece | Example | Meaning |
| --- | --- | --- |
| Parent type | `git` | Owns command-local options and grammar. |
| Property | `remote` | Swift access point used by clients. |
| Rendered command name | `"remote"` | Token inserted into the command path. |

Nested:

```swift
extension xcrun {
    public class simctl: AnyCommandLineTool, CommandLineTool {
        @Subcommand(of: simctl.self, name: "io")
        public var io
    }
}
```

Call shape:

```swift
git()
    .remote()
    .update()
```

`xcrun` uses selected tools instead:

```swift
public final class xcrun: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    @Parameter(name: "sdk")
    public var sdk: String? = nil

    @SelectedTool(of: xcrun.self, name: "simctl", tool: simctl())
    public var simctl

    @SelectedTool(of: xcrun.self, name: "swiftc", tool: swiftc())
    public var swiftc
}
```

Selection is structural. Once `.swiftc()` or `.selecting(swiftc())` is selected, later `.with(...)` calls target the selected tool model; parent values already set on `xcrun` remain part of the selected command chain:

```swift
try xcrun(sdk: sdkPath).swiftc()
    .with(\.target, "arm64e-apple-macos26.1")
    .with(\.mode, .typecheck)
    .invocation
```

Expected path:

```console
xcrun -sdk <sdkPath> swiftc -target arm64e-apple-macos26.1 -typecheck
```

Legacy execution still returns `Process.RunResult`, but execution spelling and richer return metadata remain under review.

Current implementation note: `GenericSubcommand.callAsFunction() -> Self` makes subcommand call syntax work today. The async executing `callAsFunction() async throws -> Process.RunResult` also still exists, and underscored `_run` now returns `_CommandLineToolExecutionRecord`. The long-term execution spelling should be reviewed because `()` now primarily reads as command selection in this DSL.

Open design question: declaration currently requires `@Subcommand(of:name:command:)`. The API might want lighter syntax for common cases, but the explicit spelling has useful information for reflection and diagnostics.

### Tool-Selecting Tools

Some command paths look like subcommands but are actually one command line tool selecting another command line tool:

```console
xcrun swiftc ...
xcrun simctl io ...
env FOO=bar swift build ...
bundle exec rspec ...
npm exec -- tap ...
rustup run nightly rustc ...
python -m venv ...
```

Prior art vocabulary:

| Source | Spelling | Native Vocabulary | Parse Shape | Swift Mapping |
| --- | --- | --- | --- | --- |
| Xcode | `xcrun --sdk macosx swiftc ...` | locate and invoke developer tools | selecting-tool options, selected developer tool, forwarded tool args | Best direct precedent. `xcrun` is itself a command line tool that selects another tool; `swiftc` is not an `xcrun` subcommand. |
| POSIX | `env NAME=value command ...` | invoke utility in modified environment | tool context, utility operand, forwarded args | Supports selected-tool vocabulary. Avoids pretending the utility is part of `env` grammar. |
| npm | `npm exec -- tap ...`, `npx tap ...` | package runner / exec | package resolution context, command, command args | Strong precedent for selected command/tool; also shows `exec` is common but execution-flavored. |
| Ruby Bundler | `bundle exec rspec ...` | execute command in bundle context | bundle context, command, command args | Precedent for context tool. In Swift, “with bundle/context” maps better than “subcommand”. |
| Rustup | `rustup run nightly rustc ...` | run command with toolchain environment | toolchain context, command, command args | Precedent for `withToolchain`-style context plus selected executable. |
| Cargo | `cargo run -- args` | run selected binary, pass args after `--` | build options, selected binary, forwarded args boundary | Useful for explicit parse-boundary concepts; less useful for naming because `run` is execution. |
| Python | `python -m venv ...` | run module as script | interpreter options, selected module, module args | Precedent for interpreter-as-runner; suggests selected entity may be a module, not only a binary. |
| Node.js | `spawn(command, args)`, `execFile(file, args)` | spawn/execute file | executable identity separate from argv | Process API precedent: reserve `spawn`/`exec` for actual execution, not just modeling. |
| Python subprocess | `subprocess.run(args, executable:)` | run child program | argv list, optional replacement executable | Reinforces argv/executable separation; avoid shell-string-first APIs. |
| Rust `Command` | `Command::new("git").arg("status")` | command builder, spawn/status/output | executable builder, args, execution method | Strong precedent for builder first, execution as explicit terminal method. |
| Go `os/exec` | `exec.Command(name, arg...)` | command object | executable name plus args, then `Run`/`Output` | Good model for separating modeled command from execution. |

The important distinction:

| Concept | Example | Meaning |
| --- | --- | --- |
| Subcommand | `git remote update` | Child command belongs to the parent tool's grammar. |
| Selected tool | `xcrun simctl io` | One command line tool selects/configures another tool and forwards the rest. |

Recommended vocabulary:

- **Tool-selecting command line tool:** a command line tool whose grammar includes selecting another command line tool.
- **Selected tool:** the modeled command line tool selected by the outer tool.
- **Selecting-tool options:** arguments consumed by the outer tool before the selected tool.
- **Forwarded arguments:** arguments consumed by the selected tool.
- **Tool chain:** the rendered sequence when one tool selects another tool.
- Avoid protocol names like `CommandLineToolRunner` unless we deliberately want execution connotations. In Merge, `Runner` / `Executor` can mean the thing that actually runs a process; `xcrun` is still a `CommandLineTool`.

Implemented base hook:

```swift
open class AnyCommandLineToolWithSelectedTool: AnyCommandLineTool {
    open var toolSelectionSemantics: ToolSelectionSemantics {
        .staticExplicitArgument
    }
}
```

`AnyCommandLineToolWithSelectedTool` intentionally does **not** conform to `CommandLineToolWithSelectedTool`; the associated `SelectedTool` requirement must be supplied by concrete subclasses/protocol conformers.

Implemented protocol sketch:

```swift
public protocol CommandLineToolWithSelectedTool: AnyObject {
    associatedtype SelectedTool: CommandLineTool

    var selectedTool: SelectedTool { get }
    var toolSelectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics { get }
}

public protocol CommandLineToolThatResolvesAndInvokesSelectedTool: CommandLineToolWithSelectedTool {
    var selectedToolResolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics { get }
}
```

This split is deliberate:

| Type | Role | Example | Notes |
| --- | --- | --- | --- |
| `AnyCommandLineToolWithSelectedTool` | Shared base class for tool-selection semantics | `xcrun` base model | Keeps class inheritance and existing `AnyCommandLineTool` behavior intact. |
| `CommandLineToolWithSelectedTool` | Typed selected-tool relationship | `xcrun` selecting `swiftc` or `simctl` | Concrete conformers provide `SelectedTool`; the base class cannot honestly know it. |
| `CommandLineToolThatResolvesAndInvokesSelectedTool` | Typed relationship plus resolver/invoker semantics | `xcrun swiftc`, `rustup run nightly rustc` | Represents tools whose job includes resolving/selecting another tool and invoking it. |

The selection policy type is nested:

```swift
AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics
```

Current cases track when selection happens, whether it can change, how it is disclosed, and where the argument boundary lives. The default preset is `.staticExplicitArgument`, matching `xcrun swiftc`: selected before invocation, fixed once selected, explicitly present in argv, and consuming remaining selected-tool arguments.

The dynamic preset, `.dynamicRuntimeSelection`, is reserved for tools whose selected tool may change during invocation, e.g. a hypothetical:

```console
foorun bartool --next-tool=baztool
```

Resolution/invocation policy is separate from selection policy:

```swift
AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics
```

Current cases track:

| Field | Meaning | Examples |
| --- | --- | --- |
| `phase` | When selected-tool resolution happens | `xcrun --find swiftc` resolves before invocation; a wrapper that discovers the target after startup is runtime-only. |
| `invocation` | Whether execution goes through the selecting tool or directly through the resolved executable | `xcrun swiftc ...` invokes through `xcrun`; an API that resolves a path and launches it directly would use direct executable invocation. |
| `executableDisclosure` | What the API can truthfully expose | selected tool name, resolved executable path, or only runtime observation. |

Default refinement behavior:

```swift
extension CommandLineToolThatResolvesAndInvokesSelectedTool {
    public var selectedToolResolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics {
        .resolvesBeforeInvocationAndInvokesThroughSelectingTool
    }
}
```

This matches the common `xcrun swiftc ...` shape: the selected tool is explicit in the command line, the outer tool is still the process being launched, and the selected tool receives forwarded arguments.

Implemented WIP API direction:

```swift
xcrun()
    .selecting(swiftc())
    .with(\.target, "arm64-apple-macosx15.0")

xcrun()
    .swiftc()
    .with(\.target, "arm64-apple-macosx15.0")
```

The first form is the semantic primitive. The second form is sugar for common selected tools. The sugar is implemented with `@SelectedTool`, not `@Subcommand`, so the selected tool stays an independent model.

Do not model `xcrun swiftc` as the same concept as `git remote`. Both render as command paths, but only `git remote` is a true subcommand in the parent command grammar.

API spelling candidates:

| Candidate | Prior-Art Pressure | Swift Read | Strength | Risk |
| --- | --- | --- | --- | --- |
| `xcrun().tool(swiftc())` | `env command`, `npm exec -- command`, process APIs separate executable from args | Tool selects tool | Honest primitive; compact; easy to make generic | Configuration can become nested or require temporary values |
| `xcrun().withTool { swiftc() }` | Bundler/rustup/env all imply contextual execution; Swift uses `with...` for scoped configuration | Tool with configured selected tool | Best closure form; keeps tool options in the tool's own lexical scope | `with` can imply mutation/borrowing rather than selection |
| `xcrun().running { swiftc() }` | `cargo run`, `rustup run`, subprocess `run` | Tool running tool | Good English | Sounds like process execution now, not invocation modeling |
| `xcrun().exec { swiftc() }` | `npm exec`, `bundle exec`, POSIX `exec` lineage | Tool execs tool | Strong prior-art signal; terse | In Swift, `exec` is low-level/Unixy and strongly execution-loaded |
| `xcrun().invoke { swiftc() }` | `xcrun` docs use invoke-style language | Tool invokes tool | Accurate for `xcrun`; less Unixy than `exec` | Still sounds like immediate execution |
| `xcrun().selectTool { swiftc() }` | Models the semantic act directly | Select tool through outer tool | Precise | Clunky and UI-flavored |
| `xcrun().resolve { swiftc() }` | `xcrun` resolves developer tools | Resolve selected tool | Good for `xcrun --find` / SDK lookup | Too specific to `xcrun`; wrong for `env`/`bundle exec` |
| `swiftc().through(xcrun())` | Reads like composition / adapter | Tool through selecting tool | Tool-first intent; clear distinction from subcommand | Selecting-tool options become awkward; autocomplete on `xcrun` loses known-tool affordances |
| `xcrun().swiftc()` | npm/npx-style convenience commands | Known selected tool | Best ergonomics and autocomplete | Must be documented as sugar over selected tool, not true subcommand |
| `xcrun { swiftc { ... } }` | Swift result builders, ArgumentParser command trees | DSL command graph | Can be elegant if the whole package becomes builder-oriented | Too magical unless we commit to a full DSL |

Recommended split:

| Layer | Spelling | Purpose |
| --- | --- | --- |
| Semantic primitive | `xcrun().tool(swiftc())` or `xcrun().withTool { swiftc() }` | Represents a command line tool selecting another tool without lying about subcommands. |
| Ergonomic sugar | `xcrun().swiftc()` | Common known tools get autocomplete and short call sites. |
| Execution terminal | `.run()` / `.execute()` | Actual process execution should be explicit and not confused with selected-tool `()`. |

The former closure shape remains an alternative, not the current implementation:

```swift
xcrun(sdk: sdkPath)
    .withTool {
        swiftc()
            .with(\.target, "arm64-apple-macosx15.0")
            .with(\.mode, .typecheck)
    }
```

This has the best balance so far: the selecting command line tool remains outermost, the selected tool remains a real tool model, and tool-owned options stay inside the tool's configuration scope.

Current test-backed behavior:

```swift
try ExampleXcrunTool()
    .with(\.sdk, "macosx")
    .swiftc()
    .with(\.typecheck, true)
    .with(\.inputFiles, ["Foo.swift"])
    .invocation
// xcrun -sdk macosx swiftc -typecheck Foo.swift

try ExampleXcrunTool()
    .with(\.sdk, "macosx")
    .selecting(ExampleSwiftCompilerTool())
    .with(\.typecheck, true)
    .with(\.inputFiles, ["Foo.swift"])
    .invocation
// xcrun -sdk macosx swiftc -typecheck Foo.swift

try ExampleXcrunTool()
    .selecting(ExampleSimulatorControlTool())
    .with(\.verbose, true)
    .io()
    .invocation
// xcrun simctl --verbose io
```

Two correctness details are now explicit in tests:

- `@SelectedTool(name:)` and `.selecting(_:name:)` override the rendered selected-tool token without changing the selected tool's underlying `_commandName`.
- selected-tool-local arguments render before selected-tool subcommands (`xcrun simctl --verbose io`), because `--verbose` belongs to `simctl`, not `io` or `xcrun`.

Execution-record tie-in:

`_CommandLineToolExecutionRecord` currently records either a modeled invocation or a shell command line:

```swift
public enum _CommandLineToolExecutionSource {
    case modeledInvocation(CommandLineToolInvocation)
    case shellCommandLine(String)
}
```

That remains a good conservative increment, but selected-tool execution should not be flattened into the same semantic bucket as ordinary subcommands. These two command lines both render as paths, but they are different:

| Command | Current render shape | Semantic shape |
| --- | --- | --- |
| `git remote update` | command name plus subcommand path | `remote` and `update` belong to `git`'s grammar. |
| `xcrun swiftc -typecheck Foo.swift` | command name plus selected command name plus forwarded args | `swiftc` is a selected tool resolved/invoked through `xcrun`. |

Implemented WIP direction: keep `_CommandLineToolExecutionSource` unchanged for source compatibility, and attach selected-tool metadata as an optional sidecar on `_CommandLineToolExecutionRecord`.

```swift
public struct _CommandLineToolSelectedToolInvocation: Hashable, Sendable {
    public var renderedInvocation: CommandLineToolInvocation
    public var selectingToolCommandName: String
    public var selectedToolCommandName: String
    public var selectedToolCommandPath: [String]
    public var selectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics
    public var resolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics
}
```

The first implementation supports both known selected tools and decoupled selection:

```swift
ExampleXcrunTool().swiftc()
ExampleXcrunTool().selecting(ExampleSwiftCompilerTool())
```

Both render the same selected-tool command line and produce equivalent sidecar metadata. A future source-case or launch-plan model can still replace the sidecar if the execution record graduates into a non-underscored API.

For selected-tool subcommands, `selectedToolCommandName` remains the selected tool's rendered operand and `selectedToolCommandPath` contains the selected tool plus its own subcommand path:

```swift
let record = try await ExampleXcrunTool()
    .selecting(ExampleSimulatorControlTool())
    .io()
    ._run(applying: .standardStreamMirroring(.disabled))

record.selectedToolInvocation?.selectingToolCommandName // "xcrun"
record.selectedToolInvocation?.selectedToolCommandName  // "simctl"
record.selectedToolInvocation?.selectedToolCommandPath  // ["simctl", "io"]
```

### Placement

Current anchors:

```swift
public enum Anchor {
    case local
    case nextCommand
    case lastCommand
}
```

Aliases:

```swift
.declaringCommand
.local
.selectedCommand
.nextCommand
.finalCommand
.lastCommand
```

Example:

```swift
@Flag(name: "tags", inversion: .prefixedNo, defaultPosition: .lastCommand)
public var tags: Bool? = nil

@Flag(name: "verbose", defaultPosition: .nextCommand)
public var verbose: Bool = false
```

Placement is useful for default rendering, but summaries should handle more intentional/dynamic rendering.

### Resolved Description

Current lowered model:

```swift
public struct _ResolvedCommandLineToolDescription {
    public struct Argument: _ResolvedCommandLineToolInvocationArgument { ... }
    public struct Option: _ResolvedCommandLineToolInvocationArgument { ... }
    public struct BooleanFlag: _ResolvedCommandLineToolInvocationArgument { ... }
    public struct CounterFlag: _ResolvedCommandLineToolInvocationArgument { ... }
    public struct CustomFlag: _ResolvedCommandLineToolInvocationArgument { ... }
    public struct Subcommand: Identifiable { ... }

    public var toolName: String
    public var arguments: ResolvedArguments
    public var subcommands: ResolvedSubcommands
}
```

Needs to support:

- diagnostics;
- autocomplete;
- illegal-combination validation;
- eventual command-line parsing back into Swift;
- separating semantic model from shell rendering.

Resolution now preserves rendered argument components:

```swift
public protocol _ResolvedCommandLineToolInvocationArgument {
    var invocationArgumentValues: [CommandLineToolInvocation.Argument] { get }
    var invocationArguments: [String] { get }
    var invocationArgument: String? { get }
}
```

`invocationArgumentValues` is the more faithful lowered representation. It uses the lightweight `CommandLineToolInvocation.Argument` carrier so the resolved model is no longer string-array-first. `invocationArguments` and `invocationArgument` remain compatibility/display views for older call sites.

Invocation-summary value references also use stable property-derived `ArgumentID`s instead of temporary UUIDs. This matters because summary lowering and default lowering must agree on what has already been intentionally rendered.

Open question: whether actions/subcommands should carry return-type metadata.

### Structured Invocation

Current shape:

```swift
public struct CommandLineToolInvocation: CustomStringConvertible, Hashable, Sendable {
    public var components: [Argument]
    public var rawComponents: [String]
    public var commandName: String?
    public var arguments: [Argument]
    public var commandLine: String
    public var posixShellCommandLine: String
}
```

There is also a nested carrier:

```swift
public struct CommandLineToolInvocation.Argument {
    public enum Storage {
        case string(String)
        case rawBytes([UInt8])
    }
}
```

Current caveat: `components` are now semantic argument values, and plain modeled invocations have a direct executable-plus-argv path, but selected tools, shell operators, and formatter-style compositions still need explicit strategy before they can avoid rendered command lines.

Current renderers:

| API | Meaning | Safety |
| --- | --- | --- |
| `commandLine` | Display/debug rendering by joining components with spaces. | Not safe as a shell command when components contain spaces or shell syntax. |
| `posixShellCommandLine` | POSIX single-quoted rendering of each component. | Safer for string arguments in a POSIX shell; still not a direct argv execution model. |
| `arguments` | Semantic argument values excluding command name. | Useful for inspection and later direct argv execution. |
| `rawComponents` | String projection of semantic components. | Compatibility/display view; not the source of truth. |

### Invocation Summary

Purpose: intentional rendering when declaration order is insufficient.

Use cases:

- conditional emission;
- implied flags/options;
- mode-specific renderings;
- parent-property references;
- partial summaries plus default fallback.

Example:

```swift
public var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
    \.$target
    self.$sdk
    \.$mode

    Switch(\.$emitLoadedModuleTracePath) {
        DefaultCase {
            ""
        }
        Case(value: .stdout) {
            "-emit-loaded-module-trace"
            \.$emitLoadedModuleTracePath
        }
    }
}
```

Conditional example:

```swift
var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
    When(\.$output, .isPresent) {
        "write"
        \.$output
    } else: {
        "dry-run"
    }

    \.$verbose
}
```

Equality conditions have both predicate and initializer spellings so call sites can stay readable:

```swift
When(\.$format, equals: "json") {
    "--json"
} else: {
    "--text"
}
```

Preferred direction: first-class `When` / `Switch` nodes, not arbitrary Swift `if` / `switch`, so summaries can be inspected, diagnosed, lowered, and eventually parsed.

Current semantics:

- `\.$value` renders that modeled property and marks it rendered in `InvocationSummaryContext`.
- Default fallback renders unresolved modeled properties after the custom summary.
- Literal strings are additive and do not mark any modeled property rendered.
- `.isPresent` means non-`nil`, non-empty string, and non-empty collection.
- `Switch` without `DefaultCase` is allowed; if no case matches, invocation lowering throws.
- Parent references use the parent command's key conversion, not the child command's key conversion.
- Multi-value options preserve their encoding strategy: `.singleValue` repeats key/value pairs, while `.spaceSeparated` emits one key followed by many values.
- Optional boolean inversion preserves the three distinct states: absent, true, false.
- Custom flag arrays resolve from concrete arrays and optional concrete arrays without scalar-casting crashes.

This is the core distinction from thin `Process` wrappers: the summary is still a grammar model. It can intentionally emit syntax, suppress fallback emission for modeled properties, and fail when the modeled grammar is incomplete.

#### Parent References

Parent references are not dead helper code. They are the current bridge for a concrete subcommand model that needs to intentionally render or branch on an argument owned by its parent command.

The current pattern is:

```swift
final class ParentTool: AnyCommandLineTool, CommandLineTool {
    @Parameter(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentTool.self, name: "compile", command: Compile())
    var compile

    final class Compile: AnyCommandLineTool, CommandLineTool, _Subcommand {
        typealias ParentCommand = ParentTool

        @Parameter(name: nil)
        var input: String? = nil

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$sdk

            When(self.$sdk, equals: "macosx") {
                "--sdk-forwarded"
            }

            \.$input
        }
    }
}
```

Expected behavior:

```swift
try ParentTool()
    .with(\.sdk, "macosx")
    .compile()
    .with(\.input, "main.swift")
    .invocation
```

renders:

```console
parent-tool compile --sdk macosx --sdk-forwarded main.swift
```

The important implementation detail is the shared `InvocationSummaryContext`: once `self.$sdk` renders the parent argument from inside the child summary, the default placement pass must not render the same parent argument again.

Current state:

- `_Subcommand` remains compatibility surface for DeveloperAutomation’s transitional `xcrun.swiftc` model.
- `InvocationSummaryValueReferenceFromParent` is now tested in Merge as an integration point.
- The behavior is useful, but the public spelling needs design; do not prune these helpers unless the replacement supports the same typed parent projection behavior.

`Resolvable` was different: it was only a generic public protocol used to express this one CLT summary requirement. It has been removed, and `InvocationSummaryValue` now states its exact `resolve(in:)` requirement directly.

### Output Formatter Tools

Some command-line tools are primarily output transformers. `xcbeautify` is the immediate real example:

```console
xcodebuild ... | xcbeautify --renderer github-actions --disable-colored-output
```

WIP protocol:

```swift
public protocol CommandLineToolOutputFormatterTool: CommandLineTool {
    var outputFormattingSemantics: Semantics { get }
}
```

Current default semantics:

```swift
CommandLineToolOutputFormatterTool.Semantics.standardOutputFormatter
```

Meaning:

- consumes standard output from another command;
- produces human-readable formatted output;
- does not yet define a public command-composition API.

DeveloperAutomation now has a concrete `CLT.xcbeautify` model:

```swift
extension CLT {
    public final class xcbeautify: AnyCommandLineTool, CommandLineTool, CommandLineToolOutputFormatterTool {
        public enum Renderer: String, CaseIterable, Hashable, Sendable, CLT.ArgumentValueConvertible {
            case terminal
            case githubActions = "github-actions"
            case teamcity
            case azureDevopsPipelines = "azure-devops-pipelines"
        }

        @Parameter(name: "renderer")
        public var renderer: Renderer? = nil

        @Flag(name: "disable-colored-output")
        public var disableColoredOutput: Bool = false
    }
}
```

This is deliberately not yet a public attachment/composition API. The compatibility bridge is internal: older class-style tools can temporarily set `_attachedOutputFormatterTool` and `_attachedStandardStreamWiring` while still rendering their legacy shell command lines.

The older top-level `CommandLineToolOutputFormattingSemantics` spelling remains as a deprecated compatibility alias. Swift does not allow a concrete nested type inside the protocol itself, so the implementation carrier is `_CommandLineToolOutputFormatterTool_Semantics` and the protocol exposes it as `CommandLineToolOutputFormatterTool.Semantics`. That better reflects that these semantics only describe formatter-tool intent; they do not describe the whole process graph.

Formatter semantics now also carry `streamEffects`. The default `humanReadableFormatting` effect is exclusive, which lets execution-plan validation reject accidental chains like:

```console
xcodebuild ... | xcbeautify | xcbeautify
```

That rule is not hardcoded as "formatter tools can never be repeated." A future formatter can declare a repeatable effect if double application is meaningful.

Candidate directions to evaluate:

| Direction | Benefit | Risk |
| --- | --- | --- |
| `tool.with(formatter)` overload | Ergonomic and matches user vocabulary. | Could conflict with existing key-path `with` unless carefully overloaded. |
| `GenericFormattedCommandLineTool<Base, Formatter>` | Explicit composition object and metadata. | May not preserve existing integrated `xcodebuild` behavior without a bridge. |
| Internal attached formatter sidecar on `AnyCommandLineTool` | Compatibility path for `CLT.xcodebuild` while API evolves. | Hidden state can become another ad hoc escape hatch if not constrained. |

The immediate rule: model formatter tools first; do not force every formatter use into a public generic wrapper until `xcodebuild` and other clients prove the composition shape.

## Usage

This section tracks what is currently implemented in the active Merge / DeveloperAutomation work, not the full desired API.

| Example | Current Status | Purpose |
| --- | --- | --- |
| `swift build` style example | Implemented in Merge tests under `Tests/CommandLineSupport`. | Demonstrates `@Parameter`, `@Flag`, counters, typed flags, subcommands, single-value encoding, and positional arguments without a custom summary. |
| `xcrun` / `xcrun swiftc` | Implemented in DeveloperAutomation WIP module. | Primary real-world wrapper; exercises parent command options, nested command rendering, custom summary, and loaded-module-trace rendering. |
| `git2` | Implemented in DeveloperAutomation WIP tests. | Stress test for refactoring an existing hand-written wrapper into typed parent/subcommand models. |
| `tar` / `curl` | Implemented as small WIP examples. | Exercises short flags, typed operation flags, and counter flags. |

### Merge Example: `swift build`

Implemented as a module-wise Swift Testing example. This is the cleanest current "good usage" test because it does not rely on invocation summaries.

Declaration shape:

```swift
final class ExampleSwiftTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String { "swift" }

    @Flag(name: "verbose", placement: .local)
    var verbose: Bool = false

    @Parameter(conversion: .hyphenPrefixed, name: "sdk", placement: .local)
    var sdk: String? = nil

    @Subcommand(of: ExampleSwiftTool.self, name: "build", command: ExampleSwiftBuildTool())
    var build
}

final class ExampleSwiftBuildTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String { "build" }

    @Flag
    var configuration: Configuration? = nil

    @Parameter(name: "package-path")
    var packagePath: String? = nil

    @Parameter(name: nil)
    var explicitProducts: [String] = []
}
```

Subcommands are selected by call syntax:

```swift
ExampleSwiftTool()
    .with(\.verbose, true)
    .build()
```

which renders the parent command, then the selected subcommand:

```console
swift --verbose build
```

```swift
let command = ExampleSwiftTool()
    .with(\.verbose, true)
    .with(\.sdk, "/Applications/Xcode.app/.../MacOSX.sdk")
    .build()
    .with(\.configuration, .release)
    .with(\.verbosity, 2)
    .with(\.sandbox, false)
    .with(\.packagePath, "Fixtures/Example Package")
    .with(\.triple, "arm64-apple-macosx15.0")
    .with(\.swiftcOptions, [
        .define("TRACE_IMPORTS"),
        .unsafeFlag("-emit-loaded-module-trace")
    ])
    .with(\.explicitProducts, [
        "ExampleCLI",
        "ExampleSupport"
    ])

let invocation = try command.commandInvocation
```

Expected shape:

```console
swift --verbose -sdk <sdk> build --release -vv --no-sandbox --package-path Fixtures/Example Package --triple=arm64-apple-macosx15.0 -Xswiftc -DTRACE_IMPORTS -Xswiftc -emit-loaded-module-trace ExampleCLI ExampleSupport
```

### DeveloperAutomation Example: `xcrun swiftc`

Current typed usage:

```swift
let loadedModuleTraceInvocation = try xcrun(sdk: sdkPath).swiftc()
    .with(\.target, "arm64e-apple-macos26.1")
    .with(\.moduleName, "Dummy")
    .with(\.inputFiles, [sourceFileURL])
    .with(\.mode, .typecheck)
    .with(\.emitLoadedModuleTracePath, .stdout)
    .invocation
```

Expected rendering:

```console
xcrun swiftc -target arm64e-apple-macos26.1 -sdk <sdkPath> -typecheck -emit-loaded-module-trace -emit-loaded-module-trace-path - -module-name Dummy <sourceFile>
```

Selected-tool relationship:

```swift
public final class xcrun: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    @Parameter(name: "sdk")
    public var sdk: String? = nil

    @SelectedTool(of: xcrun.self, name: "swiftc", tool: swiftc())
    public var swiftc
}

public final class swiftc: AnyCommandLineTool, CommandLineTool {
    @Parameter(name: "target")
    public var target: String? = nil

    @Parameter(name: "module-name")
    public var moduleName: String? = nil

    @Parameter(name: nil)
    public var inputFiles: [URL] = []
}
```

`sdk` belongs to `xcrun`; `target`, `moduleName`, and `inputFiles` belong to the standalone `swiftc` model. The selected command still renders as one command path: `xcrun swiftc ...`, but `swiftc` is not nested inside `xcrun`.

Current gap: rendering exists; `emitLoadedModuleTrace()` still needs to actually execute through the shell abstraction and decode `ModuleTrace`.

### DeveloperAutomation Example: `git2`

This is the important refactor example: the legacy `CLT.git` surface can move from manually serialized strings to typed command/subcommand models.

Current model sketch:

```swift
public final class git2: AnyCommandLineTool, CommandLineTool {
    public override var _commandName: String { "git" }

    @Parameter(name: "C")
    public var localRepositoryURL: URL? = nil

    @Flag(name: "tags", inversion: .prefixedNo, defaultPosition: .lastCommand)
    public var tags: Bool? = nil

    @Flag(name: "force", defaultPosition: .lastCommand)
    public var force: Bool = false

    @Flag(name: "verbose", defaultPosition: .nextCommand)
    public var verbose: Bool = false

    @Subcommand(of: git2.self, name: "push", command: git2.push())
    public var push

    @Subcommand(of: git2.self, name: "fetch", command: git2.fetch())
    public var fetch

    @Subcommand(of: git2.self, name: "remote", command: git2.remote())
    public var remote
}
```

Subcommand-local options stay on subcommand types:

```swift
extension git2 {
    public final class push: AnyCommandLineTool, CommandLineTool {
        @Flag(name: "all")
        public var pushAllBranches: Bool = false

        @Flag(name: "mirror")
        public var mirrorAllRefs: Bool = false

        @Flag(name: "verify", inversion: .prefixedNo)
        public var verify: Bool? = nil

        public enum SignedPushRequestMode: String, CLT.ArgumentValueConvertible {
            case always = "true"
            case never = "false"
            case ifAsked = "if-asked"
        }

        @Parameter(name: "signed")
        public var signed: SignedPushRequestMode? = nil
    }
}
```

Usage:

```swift
let invocation = try git2()
    .with(\.localRepositoryURL, url)
    .with(\.tags, true)
    .with(\.force, true)
    .push()
    .invocation
```

Expected:

```console
git -C <url> push --tags --force
```

Nested placement example:

```swift
let invocation = try git2()
    .with(\.verbose, true)
    .with(\.prune, true)
    .remote()
    .update()
    .invocation
```

Expected:

```console
git remote --verbose update --prune
```

Nested declaration sketch:

```swift
extension git2 {
    public final class remote: AnyCommandLineTool, CommandLineTool {
        @Subcommand(of: remote.self, name: "update", command: update())
        public var update

        @Flag(name: "push", defaultPosition: .lastCommand)
        public var push: Bool = false

        @Flag(name: "all", defaultPosition: .lastCommand)
        public var all: Bool = false
    }
}
```

This gives a three-token command path:

```swift
git2().remote().update()
```

```console
git remote update
```

Placement then decides where selected parent options land relative to the remaining command path. In the current test, `verbose` renders after `remote`, while `prune` renders after `update`.

Design note: the current implementation still has some shared flags on root `git2` with `.lastCommand` placement. That is acceptable as a stress test, but the final model should move options to the narrowest valid owner unless the real tool treats them as global.

## Prior Art And Signals

### Comparable Ecosystems

| Ecosystem | Project / Discussion | Relevant Idea | Takeaway |
| --- | --- | --- | --- |
| Python | [`sh`](https://sh.readthedocs.io/) | Calls binaries as if they were Python functions, dynamically resolving commands from `PATH`. | Good ergonomics for execution; weak on typed schemas and compile-time modeling. |
| Python | [Plumbum local commands](https://plumbum.readthedocs.io/en/latest/local_commands.html) | `local["ls"]` / `local.cmd.ls` creates command objects; supports execution, foreground/background, return codes. | Strong precedent for command objects representing existing executables. |
| Python | [Plumbum CLI toolkit](https://plumbum.readthedocs.io/en/latest/cli.html) | Uses Python classes, descriptors, and introspection to define CLIs. | Useful analogy for property-wrapper/introspection design, but mostly export-side. |
| Rust | [`xshell`](https://docs.rs/xshell/) / [`Cmd`](https://docs.rs/xshell/latest/xshell/struct.Cmd.html) | Cross-platform shell scripting with a command builder tied to shell context, cwd, and environment. | Good model for separating shell context from command construction. |
| Scala | [`os-lib`](https://index.scala-lang.org/com-lihaoyi/os-lib) / [Scala Toolkit process docs](https://docs.scala-lang.org/toolkit/os-run-process.html) | Typed-ish filesystem/process API replacing lower-level `ProcessBuilder`/`scala.sys` pain. | Good precedent for ergonomic subprocess APIs paired with typed paths/results. |
| Haskell | [`turtle`](https://hackage.haskell.org/package/turtle) | Shell programming in a typed language; external command interop, streaming, typed parsing patterns. | Shows the value of typed shell scripting beyond raw process spawning. |
| Ruby | [`tty-command`](https://www.rubydoc.info/gems/tty-command) | Command execution with logging, stdout/stderr/status capture. | Useful process-execution ergonomics, but not a typed CLI schema model. |

### Swift-Specific Signals

| Source | Signal | Relevance |
| --- | --- | --- |
| [Swift Argument Parser announcement](https://www.swift.org/blog/argument-parser/) | Swift has strong support for exporting CLIs from Swift models. | Confirms the asymmetry: export-side is solved; import/model-existing-CLI is not. |
| [Better integration with UNIX tools](https://forums.swift.org/t/better-integration-with-unix-tools/7094) | A forum user calls Swift a strong scripting language except for its lack of ergonomic APIs to execute Unix commands, then gives examples around `find`/`rsync`. Replies discuss `$PATH` lookup, pre-split arguments, stdout/stderr capture, and Python/Go precedents. | Best Swift Forum signal for the ecosystem gap: users want to integrate with existing tools, and the debate immediately lands on semantic argv, process context, output capture, and safety. |
| [Swift Subprocess review](https://forums.swift.org/t/review-sf-0007-introducing-swift-subprocess/70337) | Reviewers call out missing `$PATH` lookup, blocking pipe APIs, stdout/stderr deadlock risks, and the tension between scripting convenience and server-side security. | Confirms execution still needs careful API boundaries. `CommandLineToolSupport` should not bake shell behavior into CLI modeling. |
| [ArgumentParser `dump-help` JSON discussion](https://forums.swift.org/t/dropping-the-experimental-from-dump-help/82099) | Swift Argument Parser can dump a JSON structure of a CLI for documentation and tooling. | Strong evidence that machine-readable CLI schemas are valuable. Existing external CLIs lack this unless we model them. |
| [Command-line UX enhancements for `swift`](https://forums.swift.org/t/command-line-ux-enhancements-for-swift/50670) | Forum users wanted standard argument schema dumps so UI tools can query a CLI and build experiences around it. | Very close to this project’s motivation: typed/model-readable command descriptions enable tooling. |
| [Improved command line tool documentation](https://forums.swift.org/t/gsoc2025-improved-command-line-tool-documentation/79076) | Proposed Swift Argument Parser documentation work breaks commands, flags, options, and arguments into structured documentation artifacts and metadata. | Reinforces that command components are first-class model objects, not just strings. |
| [ArgumentParser option arguments with spaces](https://forums.swift.org/t/argumentparser-option-arguments-that-contain-spaces-and-treat-them-as-a-single-value/42563) | ArgumentParser intentionally does not split shell command strings; users must choose/implement quoting grammar. | Supports separating semantic argv from shell-rendered strings. |
| [Duplicate option behavior in ArgumentParser](https://forums.swift.org/t/a-duplicate-option-overwrites-previous-option/39091) | Repeated options can mean override or accumulation; arrays are supported, but semantics are tool-specific. | Directly relevant to `@AccumulatingOption` and resolved model flattening. |
| [SwiftCommand forum announcement](https://forums.swift.org/t/meet-swiftcommand-a-new-swift-package-that-makes-creating-child-processes-very-easy/59701) | Community built a `Foundation.Process` wrapper inspired by Rust `std::process::Command`. | Confirms execution ergonomics are a known gap, but this project needs a schema/model layer above execution. |
| [SwiftShell](https://github.com/kareman/SwiftShell) | A long-standing Swift shell-scripting library models command execution around a mutable context: environment, cwd, stdin, stdout, stderr, arguments, and executable lookup. | Prior art for `SystemShell`/execution context, not for typed command schemas. |
| [Moving from Process to Subprocess](https://troz.net/post/2025/process-subprocess/) and [Swift Subprocess intro](https://swiftdevjournal.com/posts/subprocess/) | Recent articles explain that Swift's newer Subprocess work makes launching existing programs easier than direct `Process`. | Confirms the ecosystem is still mostly focused on subprocess ergonomics, leaving the typed existing-CLI model unsolved. |
| [Creating a Swift wrapper for an existing CLI binary?](https://www.reddit.com/r/swift/comments/dhu0ei) | A user asks for tutorials on wrapping an existing CLI binary and says searches mostly return advice for creating a new CLI app. | Direct community signal for the "existing CLI -> Swift model" documentation/API gap. |
| [Process hangs / subprocess discussion](https://forums.swift.org/t/swiftpm-command-process-gets-stuck/77026) | Even simple Swift `Process` use around `swift package ...` can hang or behave differently in plugin/terminal contexts. | Supports making `SystemShell` testable and execution behavior explicit. |

### Swift-Side Read

The Swift ecosystem has several adjacent answers:

- `ArgumentParser` models Swift-owned CLIs beautifully.
- `dump-help` and DocC-generation work prove that machine-readable command structure is valuable.
- `Subprocess`, `SwiftCommand`, and `SwiftShell` improve launching existing processes.

The missing middle is still a typed, inspectable model for existing external tools:

```swift
xcrun().swiftc()
    .sdk(.macosx)
    .target("arm64-apple-macosx15.0")
    .emitModule()
    .input("Sources/App/main.swift")
```

That should lower to argv, support summaries/docs/diagnostics, preserve tool-specific semantics, and remain separate from the execution backend.

### What To Borrow

- **Command objects:** from `sh`/Plumbum, but with Swift type information instead of dynamic lookup only.
- **Shell context:** from `xshell`, where command execution lives inside cwd/env/shell context.
- **Typed paths/results:** from Scala `os-lib` and Haskell `turtle`.
- **Schema export thinking:** from Swift Argument Parser's JSON help dump.
- **Explicit argv vs shell string split:** from Swift forum quoting discussions and Python `shlex`-style concerns.
- **Collected output vocabulary:** from Swift Subprocess, where output/error strategies are explicit and collected results are distinct from streaming/file-descriptor redirection.

### What Not To Copy

- Do not stop at a nicer `Process` wrapper. That solves execution, not modeling.
- Do not make everything dynamic like Python `sh`; Swift should provide compile-time discoverability.
- Do not rely on shell strings as the primary semantic representation.
- Do not spread custom summaries everywhere before the summary model is reviewed.

## Design Decisions

| Decision | Recommendation | Status |
| --- | --- | --- |
| Summary naming | Keep `CommandLineToolInvocationSummary` internally; expose short aliases on `CommandLineTool`; avoid global `InvocationSummary`. | Needs approval |
| `defaultPosition` long-term | Keep as low-level/default rendering. Prefer summaries for intentional dynamic renderings. | Needs approval |
| Parent refs in summaries | Keep typed dynamic parent projection, but hide underscored protocols from API users. | Needs API review |
| Simple subcommands | Keep explicit types for complex cases; add lightweight inline/simple-subcommand affordance. | Needs design |
| Tool-selecting tools | Promote selected-tool vocabulary without naming the outer tool a runner; treat `xcrun swiftc` differently from true subcommands like `git remote`. | Needs design |
| Option groups | Add only where they remove real duplication without hiding command structure. | Needs design |
| Repeated options in resolved model | Preserve one property wrapper as one resolved item; flatten separately. | Needs approval |
| Accumulating flags/options | Do not overload `@Flag` prematurely; add real examples before adding wrappers. | Pending |
| Constructor-backed flags | Support explicit render-default initialization so `init` can set current value without making that value the render default. | Implemented; needs naming/docs review |
| Output formatter tools | Keep `CommandLineToolOutputFormatterTool` WIP; model `xcbeautify` concretely before committing to formatter composition API. | Implemented as WIP protocol + DeveloperAutomation model |
| `SystemShell` testability | Keep concrete `SystemShell`; inject executor/backend. | Pending |
| Subcommand call syntax | `GenericSubcommand.callAsFunction() -> Self` enables `xcrun().simctl().io()` today. | Implemented; needs API review |
| Execution spelling | Avoid making `()` primarily mean execution for subcommands; keep existing async `callAsFunction` compatibility and use underscored `_run` as the provisional typed carrier surface. | In progress |
| `showSDKPath`-style actions | Model no-argument operations as typed flags/properties first; add action wrapper only if needed. | Needs design |
| Return metadata | Keep legacy execution return as `Process.RunResult`; use provisional `_CommandLineToolExecutionRecord<Tool>` for typed carrier experimentation. | In progress |
| Key conversion precedence | Support command-level default and per-argument override. | Implemented; parent/child summary projection now covered |
| `xcrun swiftc` summary | Partial summary plus default fallback is pragmatic; parent-reference summary behavior now has Merge coverage. | Needs real-client migration pressure |
| `xcodebuild` modeling | Eventually model as `xcrun.xcodebuild`; avoid breaking existing clients. | Pending |
| Module boundaries | Move generic `git`/`tar` experiments into Merge tests or proper modules. | Pending |
| collected output | Prefer shared `_runCollectingOutput` / `._collectingOutput` vocabulary over one-off client helpers like `runQuietGit`; keep underscored while semantics settle. | Implemented as provisional |
| argv vs shell strings | Make `CommandLineToolInvocation.Argument` the storage source of truth; derive shell/display strings separately. | Implemented for storage and plain direct execution; selected tools/pipelines still need explicit strategy |
| execution plans | Add a pre-execution representation that separates source, configuration, selected-tool metadata, and eventual direct-vs-shell strategy. | First `_CommandLineToolExecutionPlan` implemented; needs strategy model |
| URL/path arguments | Stop shell-escaping `URL.argumentValue` as the semantic default while preserving compatibility for older code. | Needs migration |
| output formatter graph | Treat formatter tools as execution-plan participants, not ordinary arguments; keep standard-stream wiring nested under `_CommandLineToolExecutionPlan`. | First nested `StandardStreamWiring` model implemented |
| Error handling | Public rendering should throw typed errors; reserve assertions for impossible internal states. | Needs cleanup |

## Completion Work

### Merge

- Keep provisional selected-tool, execution-record, output-formatter, and invocation-summary files under `Sources/CommandLineToolSupport/Intramodular (WIP)` until their names and semantics are reviewed.
- Prefer one-line type documentation in WIP source files: it should explain why the type exists, not restate its stored properties.
- Keep module-wise tests under `Tests/CommandLineSupport`.
- Add tests for:
  - nested subcommands with parent and child summaries.
- Clean up spelling/API roughness:
  - `_CommandLineToolOptionKeyConvension`;
  - `_representaton`;
  - global namespace leakage.
- Decide whether `@Subcommand(name:)` affects rendering or `_commandName` is sole source of truth.
- Clarify `CommandLineToolInvocation`: semantic arguments are now stored, but display rendering, shell rendering, and direct execution are separate views.
- Preserve the new `CommandLineToolInvocation.Component` storage direction while moving execution plans toward explicit direct-vs-shell strategy.
- Split semantic argument conversion from shell rendering; specifically migrate away from shell-escaped `URL.argumentValue` without breaking older clients.
- Expand execution-plan/source tests covering selected tools, builtins, executable URLs, formatter pipelines, and raw shell command lines.
- Replace crashes/force casts in public rendering paths with typed errors.
- Keep `Resolvable` removed unless another non-CLT use case appears; `InvocationSummaryValue` now states its exact `resolve(in:)` requirement directly.
- Continue nudging parent-reference summaries toward a public, non-underscored spelling without losing current DeveloperAutomation compatibility.
- Add formatter composition tests only after agreeing on the relationship between `CLT.xcodebuild`, `CLT.xcbeautify`, and nested standard-stream wiring.
- Keep client-local bridges like `CLT.git._runGit(_:)` only while they identify real shared holes; remove them once URL/path conversion and invocation storage are fixed.

## Suggested Plan

1. Split semantic value conversion from shell rendering, starting with a compatibility-preserving path for `URL.argumentValue`.
2. Add explicit execution strategy to `_CommandLineToolExecutionPlan` so records can distinguish direct executable launch from shell-mediated launch.
3. Teach selected-tool plans how to choose between selecting-tool execution and resolved selected-tool execution without erasing metadata.
4. Migrate `CLT.git._runGit(_:)` away once root `-C` path rendering is fixed by shared modeling.
5. Grow formatter execution from the current nested `StandardStreamWiring` sidecar for `xcodebuild | xcbeautify`, preserving existing `CLT.xcodebuild` public behavior.
6. Add summary + placement edge tests, especially parent projection, selected-tool paths, and key-conversion conflicts.
7. Replace public-path force casts and vague preconditions with typed modeling/rendering errors or sharper developer-error preconditions.
8. Keep this document updated as decisions land; stale client bridges should be called out explicitly instead of normalized.

---

## DeveloperAutomation Models

### `xcrun`

```swift
public final class xcrun: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    @Parameter(name: "sdk")
    public var sdk: String? = nil

    public enum InformationDump: CommandLineTools.OptionKeyConvertible {
        case showSDKPath
        case showSDKVersion
        case showSDKBuildVersion
        case showSDKPlatformPath
        case showSDKPlatformVersion
        case showToolchainPath
    }

    @Flag public var dumpMode: InformationDump?

    @SelectedTool(of: xcrun.self, name: "simctl", tool: simctl())
    public var simctl

    @SelectedTool(of: xcrun.self, name: "swiftc", tool: swiftc())
    public var swiftc
}
```

Example:

```swift
try await xcrun(sdk: "macosx")
    .with(\.dumpMode, .showSDKPath)
    .callAsFunction()
```

### `xcrun swiftc`

Models compiler modes, compiler options, input files, and loaded-module-trace options.

Key fields:

- `mode`
- `target`
- `sysroot`
- `moduleName`
- `packageName`
- `workingDirectory`
- import/framework/library search paths
- linked frameworks/libraries
- `swiftVersion`
- `defines`
- `extraClangArguments`
- `extraLinkerArguments`
- `inputFiles`
- `emitLoadedModuleTracePath`

Loaded module trace path:

```swift
public enum EmitLoadedModuleTracePath: Hashable, CLT.ArgumentValueConvertible {
    case url(URL)
    case stdout

    public var argumentValue: String {
        switch self {
            case .url(let url):
                url.argumentValue
            case .stdout:
                "-"
        }
    }
}
```

Expected rendering:

```console
xcrun swiftc -target arm64e-apple-macos26.1 -sdk <sdkPath> -typecheck -emit-loaded-module-trace -emit-loaded-module-trace-path - -module-name Dummy <file>
```

Still missing: `emitLoadedModuleTrace()` currently needs to actually run and decode, not just render.

### `ModuleTrace`

Typed JSON output:

```swift
public struct ModuleTrace: Decodable {
    public let version: Int
    public let moduleName: String
    public let arch: String
    public let swiftmodules: [String]
    public let swiftmodulesDetailedInfo: [DetailedSwiftModuleInfo]
    public let swiftmacros: [String]
}
```

### `git`

There are two active `git` pressures:

1. `git2` in the older DeveloperAutomation experimental target is a modeling stress test for shared parent options, placement, and nested subcommands.
2. `CLT.git` in the real DeveloperAutomation module is a compatibility wrapper with domain methods such as `origin()`, `tags()`, `pull()`, and `hasChangesToPush()`.

Examples:

```swift
try git2()
    .with(\.localRepositoryURL, url)
    .with(\.tags, true)
    .with(\.force, true)
    .push()
    .invocation
```

Expected:

```console
git -C <url> push --tags --force
```

Nested:

```swift
try git2()
    .with(\.verbose, true)
    .with(\.prune, true)
    .remote()
    .update()
    .invocation
```

Expected:

```console
git remote --verbose update --prune
```

Concern: shared options such as `force`/`tags` should not be hoisted to root `git` if they are invalid for many subcommands.

Current `CLT.git` migration state:

- `serializedCommand(action:)` has been removed from `CLT.git`.
- Domain methods now pass structured argument arrays into a small `_runGit(_:)` bridge.
- Stdout probes use the shared `._collectingOutput` difference.
- `_runGit(_:)` remains because root `git -C <path>` cannot yet safely flow through the modeled `@Parameter(name: "C")` URL property without hitting legacy `URL.argumentValue` shell escaping.

This is a useful temporary bridge, not the desired API shape. The intended final shape is still that `CLT.git` domain methods become boring:

```swift
try await _run(
    appending: ["checkout", "-b", branch.name],
    applying: ._collectingOutput
)
```

with `git`, `-C`, and the repository path supplied by the modeled root tool.

### `tar`

Used for typed custom flags and short options:

```swift
public final class tar: AnyCommandLineTool, CommandLineTool {
    @Flag public var operation: Operation
    @Flag(name: "v") public var verbose: Int = 0
    @Flag public var format: Format? = nil
}
```

Expected examples:

```console
tar -c
tar -c -z
```

### `xcodebuild`

Partially migrated:

```swift
public final class xcodebuild: AnyCommandLineTool, CommandLineTool {
    public override var _commandName: String {
        "xcrun xcodebuild" // TODO: Put under xcrun tool
    }

    public override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Parameter(name: "workspace")
    public var workspace: String? = nil

    @Parameter(name: "scheme")
    public var scheme: String? = nil

    @Parameter(name: nil)
    public var buildFlags: Set<BuildFlag>? = nil

    @EnvironmentVariable(name: "SYMROOT")
    public var symRoot: String? = nil
}
```

Still transitional:

- `_commandName = "xcrun xcodebuild"` should probably become `xcrun.xcodebuild`.
- `serializedCommand(action:)` still manually assembles command strings.
- `Set<BuildFlag>` preserves source compatibility but can produce nondeterministic ordering.
- current build serialization still hardcodes `xcbeautify` pipeline behavior; the new formatter model should replace that incrementally without breaking the existing `CLT.xcodebuild` API.

## DeveloperAutomation Completion Work

- Finish `CLT.xcrun_swiftc.emitLoadedModuleTrace()`:
  - run through shell abstraction;
  - decode `ModuleTrace`;
  - test invocation and decoding.
- Replace the existing loaded-module-trace manual command with `CLT.xcrun_swiftc`.
- Add execution or injectable-shell tests.
- Move generic wrapper experiments out of `CLT_xcrun_swiftc`.
- Keep `CLT.xcodebuild` source compatibility while migrating serialization.
- Keep local Merge linkage only while co-iterating; remove local dependency overrides before final merge/release.

## DeveloperAutomation Plan

1. Finish `xcrun swiftc` loaded-module-trace execution.
2. Replace the real manual command use site.
3. Clean module boundaries.
4. Re-test against Merge `main`.

## Original Author Review Context

Preserved questions from the original implementation/review thread:

| Question | Current Direction |
| --- | --- |
| What does it mean to resolve an `invocationSummary` if parameters/options are already resolved? | Summaries should be representable, late-bound nodes that lower into resolved metadata. |
| Ordinary Swift `if` / `switch`, or first-class `When` / `Switch`? | Prefer first-class DSL constructs for diagnostics, autocomplete, and parsing. |
| How should a child summary reference parent properties? | Typed parent projection/dynamic-member support; hide underscored protocols. |
| Is `@Subcommand` acceptable for nested commands like `xcrun simctl io`? | Yes for complex cases; add lighter syntax for trivial subcommands. |
| Should `callAsFunction` exist on roots and subcommands? | Sync `callAsFunction() -> Self` is useful for subcommand selection; async execution spelling needs review. |
| Is `-Xcc a -Xcc b` one resolved option or two? | One modeled resolved item; flatten separately. |
| Should shared `git fetch` / `git pull` args live on root `git`? | Prefer option groups/subcommand-local groups unless truly global. |

## Assessment

The architecture direction is worth preserving. The strongest parts are:

- real command-line modeling primitives, not string helpers;
- tests against awkward real tools;
- typed modes/flags instead of magic strings;
- a path toward resolved metadata, diagnostics, autocomplete, and parsing.

The rough parts are completion work:

- provisional names;
- underscored/global API leakage;
- summary DSL taste;
- shell-string/argv conflation;
- real-shell coupling;
- experimental wrappers in poorly named modules.

Finish the `xcrun swiftc` use case end-to-end, then generalize cautiously.
