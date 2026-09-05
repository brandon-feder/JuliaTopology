"""
    GenericAbstractSimplicialComplex

The generic object for the category `AbstractSimplicialComplex`. Wraps a
sorted iterator of simplices, each a `Tuple{Vararg{Int}}` of vertex labels.
"""
struct GenericAbstractSimplicialComplex
    simplexIterator

    function GenericAbstractSimplicialComplex(simplexIterator)
        @assert applicable(iterate, simplexIterator)
        @assert applicable(length, simplexIterator)
        @assert applicable(eltype, simplexIterator)
        @assert hasmethod(getindex, Tuple{typeof(simplexIterator), Int})
        @assert eltype(simplexIterator) <: Tuple{Vararg{Int}}

        return new(simplexIterator)
    end
end

inCategory(obj::GenericAbstractSimplicialComplex, ::Type{AbstractSimplicialComplex}) = true

function nSimplices(
    obj::ObjectInCategory{GenericAbstractSimplicialComplex, AbstractSimplicialComplex}
)
    return length(obj.object.simplexIterator)
end

function simplexIterator(
    obj::ObjectInCategory{GenericAbstractSimplicialComplex, AbstractSimplicialComplex}
)
    return obj.object.simplexIterator
end