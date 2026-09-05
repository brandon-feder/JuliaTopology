abstract type AbstractCategory end

"""
    inCategory(obj, ::Type{Cat}) where Cat <: AbstractCategory

Returns `true` if the object `obj` is in the category `Cat`.
Unless overloaded, this will evaluate to false. To overload this for 
a particular category, you can use
```julia
inCategory(obj::ParticularType, ::Type{ParticularCategory}) = true
```
"""
inCategory(obj, ::Type{Cat}) where Cat <: AbstractCategory = false

"""
    NotInCategoryError <: Exception

An exception thrown when an object of type `T` does not belong to 
the category `Cat`.
"""
struct NotInCategoryError{T, Cat <: AbstractCategory} <: Exception
    object::T
end

function Base.showerror(io::IO, e::NotInCategoryError{T, Cat}) where T where Cat
    print(io, "Object $(e.object) of type $(T) is not in the category $(Cat)")
end

"""
    assertInCategory(obj::T, ::Type{Cat})

Throws an error if `obj` is not in the category `Cat`.
"""
function assertInCategory(obj::T, ::Type{Cat}) where T where Cat <: AbstractCategory
    if !inCategory(obj, Cat)
        throw(NotInCategoryError{T, Cat}(obj))
    end
end

"""
    struct ObjectInCategory{T, Cat <: AbstractCategory}

Wraps an object with a category it belongs to.
"""
struct ObjectInCategory{T, Cat <: AbstractCategory}
    object::T

    function ObjectInCategory{T, Cat}(
        obj::T
    ) where T where Cat
        assertInCategory(obj, Cat)
        return new{T, Cat}(obj)
    end
end

function Base.show(
    io::IO, obj::ObjectInCategory{T, Cat}
) where T where Cat
    print(io, "object $(obj.object) of type $(T) in category $(Cat)")
end

"""
    Base.:(==)(a::ObjectInCategory{T, Cat}, b::ObjectInCategory{T, Cat})

Two objects in the same category are equal when their wrapped objects
are equal. This delegates to `==` on the wrapped objects themselves,
so it is meaningful even when `T` alone cannot distinguish two
distinct instances (e.g. two different fields sharing the same Julia
type).
"""
function Base.:(==)(
    a::ObjectInCategory{T, Cat}, b::ObjectInCategory{T, Cat}
) where T where Cat
    return a.object == b.object
end

"""
    function ObjectInCategory(obj, ::Type{Cat})

Wraps an object with a category it belongs to.
"""
function ObjectInCategory(obj::T, ::Type{Cat}) where T where Cat <: AbstractCategory
    return ObjectInCategory{T, Cat}(obj)
end

"""
    macro wrap(obj, CatT)

Shorthand for
```julia
ObjectInCategory(obj, Cat)
```
"""
macro wrap(obj, CatT)
    return :(ObjectInCategory($(esc(obj)), $(esc(CatT))))
end