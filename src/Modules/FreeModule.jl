"""
In order to define chain complexes, we need an interface for finite free modules
over some rings and morphisms between those modules.

# Required Interface
- `ring(obj)` - The underlying ring
- `dimension(obj)::Int` -  dimension of free module (size of basis)
"""
struct FreeModule <: AbstractCategory end