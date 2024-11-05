//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow

public protocol _ActorSideEffectSpecification {
    
}

public protocol _ActorSideEffect {
    
}

public protocol _ActorSideEffectSpecifying {
    associatedtype EffectSpecificationType: _ActorSideEffectSpecification
    
    static var effectSpecification: EffectSpecificationType { get }
}

public struct _ResolvedTaskEffect {
    
}

public protocol _ActorSideEffectModifier {
    @_spi(Internal)
    func _modify(_: inout _ResolvedTaskEffect)
}

struct _ModifiedActorTaskEffectSpecification<Modifier: _ActorSideEffectModifier, Content: _ActorSideEffectSpecification>: _ActorSideEffectSpecification {
    let content: Content
    let modifier: Modifier
}

extension _ActorSideEffectSpecification {
    public func _modifier(_ modifier: some _ActorSideEffectModifier) -> some _ActorSideEffectSpecification {
        _ModifiedActorTaskEffectSpecification(content: self, modifier: modifier)
    }
}

public struct _ActorSideEffectsSpecifications {
    public enum _ActorSideEffectSpecificationSymbol {
        case keyPath(AnyKeyPath)
    }
    
    /// Apply an effect on the change of something.
    public struct OnChange<Content: _ActorSideEffectSpecification>: _ActorSideEffectSpecification {
        public let value: _ActorSideEffectSpecificationSymbol
        public let content: Content
        
        init(value: _ActorSideEffectSpecificationSymbol, content: Content) {
            self.value = value
            self.content = content
        }
    }
}
