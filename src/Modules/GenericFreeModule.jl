"""
    struct GenericFreeModule

A free module over a specific ring.
"""
struct GenericFreeModule
    ring::ObjectInCategory{GenericFiniteField, FiniteField}
    dimension::Int

    function GenericFreeModule(ring::ObjectInCategory, dimension::Int)
        @assert dimension >= 0

        return new(ring, dimension)
    end
end

inCategory(obj::GenericFreeModule, ::Type{FreeModule}) = true

function dimension(obj::ObjectInCategory{GenericFreeModule, FreeModule})
    return obj.object.dimension
end

function ring(obj::ObjectInCategory{GenericFreeModule, FreeModule})
    return obj.object.ring
end

function Base.eltype(obj::ObjectInCategory{GenericFreeModule, FreeModule})
    return eltype(ring(obj))
end