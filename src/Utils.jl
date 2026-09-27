"""
    struct InterfaceViolation <: Exception

Thrown by [`checkInterface`](@ref) when `object` does not satisfy the interface
required by a category.

# Members
- `object` - The object being wrapped
- `category` - The category which the object is in
- `reason::AbstractString` - An explanation of the violation
"""
struct InterfaceViolation <: Exception
    reason::AbstractString
end

function Base.print(io::IO, err::InterfaceViolation)
    print(io, err.reason)
end

"""
    @annotated "...\$x..."

An interpolated string which keeps the colors of what is interpolated into it,
i.e. an `AnnotatedString`, where a plain string literal would discard them.
Use it for any message containing colored text.
"""
macro annotated(ex)
    Meta.isexpr(ex, :string) || return esc(ex)
    parts = (:($annotatedArg($(esc(a)))) for a in ex.args)
    return :($annotatedstring($(parts...)))
end

# What `@annotated` interpolates for `x`; objects and categories are replaced
# by their colored display, which `annotatedstring` would otherwise print plain
annotatedArg(x) = x
