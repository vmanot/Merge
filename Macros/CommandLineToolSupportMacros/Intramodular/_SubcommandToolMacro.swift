//
// Copyright (c) Vatsal Manot
//

import MacroBuilder
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct _SubcommandToolMacro {
    fileprivate static func isNominalDeclaration(_ syntax: Syntax) -> Bool {
        syntax.is(ClassDeclSyntax.self) ||
        syntax.is(StructDeclSyntax.self) ||
        syntax.is(ActorDeclSyntax.self) ||
        syntax.is(EnumDeclSyntax.self)
    }

    fileprivate static func isParentDeclaration(_ syntax: Syntax) -> Bool {
        isNominalDeclaration(syntax) || syntax.is(ExtensionDeclSyntax.self)
    }

    fileprivate static func declarationIsNested(
        _ declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        let declarationText = declaration.trimmedDescription

        return context.lexicalContext.contains { syntax in
            isParentDeclaration(syntax) && syntax.trimmedDescription != declarationText
        }
    }

    fileprivate static func parentCommandTypeDescription(
        in context: some MacroExpansionContext
    ) -> String? {
        for syntax in context.lexicalContext.reversed() {
            if let declaration = syntax.as(ClassDeclSyntax.self) {
                return declaration.name.text
            } else if let declaration = syntax.as(StructDeclSyntax.self) {
                return declaration.name.text
            } else if let declaration = syntax.as(ActorDeclSyntax.self) {
                return declaration.name.text
            } else if let declaration = syntax.as(EnumDeclSyntax.self) {
                return declaration.name.text
            } else if let declaration = syntax.as(ExtensionDeclSyntax.self) {
                return declaration.extendedType.trimmedDescription
            } else {
                continue
            }
        }

        return nil
    }

    fileprivate static func declarationUsesParentInvocationSummaryReferences(
        _ declaration: some DeclSyntaxProtocol
    ) -> Bool {
        guard let declaration = declaration.asProtocol(DeclGroupSyntax.self) else {
            return false
        }

        return declaration.memberBlock.members.contains { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                return false
            }

            let isInvocationSummary = variable.bindings.contains { binding in
                binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "invocationSummary"
            }

            return isInvocationSummary && variable.containsSelfParentValueReference
        }
    }

    fileprivate static func declarationAlreadyConformsToCommandLineTool(
        _ declaration: some DeclGroupSyntax
    ) -> Bool {
        declaration.inheritanceClause?.inheritedTypes.contains { inheritedType in
            inheritedType.type.trimmedDescription == "CommandLineTool"
        } ?? false
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

extension VariableDeclSyntax {
    fileprivate var containsSelfParentValueReference: Bool {
        Syntax(self).containsSelfParentValueReference
    }
}

extension Syntax {
    fileprivate var containsSelfParentValueReference: Bool {
        if let memberAccess = self.as(MemberAccessExprSyntax.self),
           let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
           base.baseName.text == "self",
           memberAccess.declName.baseName.text.hasPrefix("$")
        {
            return true
        }

        return children(viewMode: .sourceAccurate).contains { child in
            child.containsSelfParentValueReference
        }
    }
}

extension _SubcommandToolMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isCommandLineToolSubcommandCompatibleNominalDeclaration else {
            throw AnyDiagnosticMessage(
                message: "@_SubcommandTool can only be attached to a nested class, struct, actor, or enum."
            )
        }

        guard declarationIsNested(declaration, in: context) else {
            throw AnyDiagnosticMessage(
                message: "@_SubcommandTool can only be attached to a type nested inside another type."
            )
        }

        return []
    }
}

extension _SubcommandToolMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.isCommandLineToolSubcommandCompatibleNominalDeclaration else {
            throw AnyDiagnosticMessage(
                message: "@_SubcommandTool can only be attached to a nested class, struct, actor, or enum."
            )
        }

        guard declarationUsesParentInvocationSummaryReferences(declaration) else {
            return []
        }

        guard declarationIsNested(DeclSyntax(declaration), in: context), let parentCommandType = parentCommandTypeDescription(in: context) else {
            throw AnyDiagnosticMessage(
                message: "@_SubcommandTool can only infer parent invocation-summary conformance for a type nested inside another type."
            )
        }

        let accessModifier = accessModifier(for: declaration)

        return [
            DeclSyntax(
                """
                \(raw: accessModifier)typealias ParentCommand = \(raw: parentCommandType)
                """
            )
        ]
    }
}

extension _SubcommandToolMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.isCommandLineToolSubcommandCompatibleNominalDeclaration else {
            throw AnyDiagnosticMessage(
                message: "@_SubcommandTool can only be attached to a nested class, struct, actor, or enum."
            )
        }

        var conformances: [String] = []

        if !declarationAlreadyConformsToCommandLineTool(declaration) {
            conformances.append("CommandLineTool")
        }

        if declarationUsesParentInvocationSummaryReferences(declaration) {
            guard declarationIsNested(DeclSyntax(declaration), in: context) else {
                throw AnyDiagnosticMessage(
                    message: "@_SubcommandTool can only infer parent invocation-summary conformance for a type nested inside another type."
                )
            }

            conformances.append("_InvocationSummarySubcommandWithParentCommand")
        }

        guard !conformances.isEmpty else {
            return []
        }

        return try [
            ExtensionDeclSyntax(
                """
                extension \(type.trimmed): \(raw: conformances.joined(separator: ", ")) {
                }
                """
            )
        ]
    }
}

extension DeclSyntaxProtocol {
    fileprivate var isCommandLineToolSubcommandCompatibleNominalDeclaration: Bool {
        self.is(ClassDeclSyntax.self) ||
        self.is(StructDeclSyntax.self) ||
        self.is(ActorDeclSyntax.self) ||
        self.is(EnumDeclSyntax.self)
    }
}
