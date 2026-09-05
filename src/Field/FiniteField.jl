"""
    struct FiniteField <: AbstractCategory end

Category for finite fields. Here, `T` is the type of 
    elements of the field.

# Required Interface
- `Base.eltype(obj)::Type` - The element type
- `Base.one(obj)::T` - The multiplicative identity
- `Base.zero(obj)::T` - The additive identity
- `Base.:*(a::Int, x::T)::T` - How to "iterate addition."
- `order(obj)::Int` - Order of the finite field
"""
struct FiniteField <: AbstractCategory end