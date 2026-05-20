//
// Copyright (c) Vatsal Manot
//

import MacroBuilder

public struct CommandLineToolMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.isCommandLineToolCompatibleNominalDeclaration else {
            throw AnyDiagnosticMessage(
                message: "@CommandLineTool can only be attached to a class, struct, actor, or enum."
            )
        }

        guard !protocols.isEmpty else {
            return []
        }

        return [
            ExtensionDeclSyntax(
                extendedType: type,
                inheritanceClause: InheritanceClauseSyntax(
                    inheritedTypes: InheritedTypeListSyntax(itemsBuilder: {
                        for `protocol` in protocols {
                            InheritedTypeSyntax(type: `protocol`)
                        }
                    })
                ),
                memberBlock: MemberBlockSyntax(members: "")
            )
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
