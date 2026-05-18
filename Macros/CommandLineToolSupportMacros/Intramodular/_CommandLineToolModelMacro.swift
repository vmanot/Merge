//
// Copyright (c) Vatsal Manot
//

import MacroBuilder

public struct _CommandLineToolModelMacro: _MemberMacro2 {
    public static func _expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isCommandLineToolCompatibleNominalDeclaration else {
            throw AnyDiagnosticMessage(
                message: "@_CommandLineToolModel can only be attached to a class, struct, actor, or enum."
            )
        }
        guard let declaration = declaration.asProtocol(NamedDeclSyntax.self) else {
            throw AnyDiagnosticMessage(
                message: "@_CommandLineToolModel requires a named declaration."
            )
        }

        let typeName = declaration.trimmed.name.text

        return [
            "public typealias _ExecutionRecord = _CommandLineToolExecutionRecord<\(raw: typeName)>",
            #"@available(*, deprecated, renamed: "_ExecutionRecord") public typealias _RunResult = _ExecutionRecord"#,
            "public typealias _RawRunResult = Process.RunResult",
        ]
    }
}

extension DeclGroupSyntax {
    fileprivate var isCommandLineToolCompatibleNominalDeclaration: Bool {
        self.is(ClassDeclSyntax.self) ||
        self.is(StructDeclSyntax.self) ||
        self.is(ActorDeclSyntax.self) ||
        self.is(EnumDeclSyntax.self)
    }
}
