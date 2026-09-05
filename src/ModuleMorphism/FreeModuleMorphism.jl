"""
Interface for morphisms between free modules.

# Required Interface
- `domain(obj)::FreeModule` - domain of morphism
- `codomain(obj)::FreeModule` - codomain of morphism
- `Base.getindex(obj, i::Int, j::Int)::T` - Get index of matrix with respect to 
    the standard basis
- `rank(obj)::Int` - rank of linear transformation (TODO: make standardized)
"""
struct FreeModuleMorphism <: AbstractCategory end