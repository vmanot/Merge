//
// Copyright (c) Vatsal Manot
//

import MacroBuilder
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CommandLineToolMacro {
    fileprivate static func commandNameExpression(
        from node: AttributeSyntax
    ) -> String? {
        node.arguments?
            .as(LabeledExprListSyntax.self)?
            .first?
            .expression
            .trimmed
            .description
    }
    
    fileprivate static func accessModifier(
        for declaration: some DeclGroupSyntax
    ) -> String {
        let publicAccessModifiers: Set<String> = ["open", "public", "package"]
        
        guard let modifier = declaration.modifiers.first(where: {
            publicAccessModifiers.contains($0.name.text)
        }) else {
            return ""
        }
        
        return "\(modifier.name.text) "
    }
}

extension CommandLineToolMacro: ExtensionMacro {
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

        let inheritanceClause: String

        if protocols.isEmpty {
            inheritanceClause = ""
        } else {
            inheritanceClause = ": " + protocols.map(\.trimmedDescription).joined(separator: ", ")
        }

        return try [
            ExtensionDeclSyntax(
                """
                extension \(type.trimmed)\(raw: inheritanceClause) {
                }
                """
            )
        ]
    }
}

extension CommandLineToolMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let commandNameExpression = commandNameExpression(from: node) else {
            return []
        }
        
        let accessModifier = accessModifier(for: declaration)
        
        return [
            DeclSyntax(
                """
                \(raw: accessModifier)override var commandName: CommandLineTool.Name? {
                    \(raw: commandNameExpression)
                }
                """
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
