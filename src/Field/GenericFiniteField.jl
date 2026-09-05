"""
    GenericFiniteField

The generic object for the category `FiniteField`, backed by a `Nemo.FqField`.
"""
struct GenericFiniteField
    order::Int
    field::Nemo.FqField

    function GenericFiniteField(order::Int, field::Nemo.FqField)
        @assert Nemo.order(field) == order
        return new(order, field)
    end
end

inCategory(obj::GenericFiniteField, ::Type{FiniteField}) = true

function GenericFiniteField(order::Int)
    return GenericFiniteField(order, Nemo.GF(order))
end

function Base.one(
    obj::ObjectInCategory{GenericFiniteField, FiniteField}
)
    return one(obj.object.field)
end

function Base.zero(
    obj::ObjectInCategory{GenericFiniteField, FiniteField}
)
    return zero(obj.object.field)
end

function Base.eltype(
    obj::ObjectInCategory{GenericFiniteField, FiniteField}
)
    return eltype(obj.object.field)
end