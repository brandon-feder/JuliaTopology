"""
The category of abstract simplicial complexes.

# Required Interface
- `nSimplices(obj)::Int` - Returns the total number of simplices (of all dimensions)
- `simplexIterator(obj)` - Returns an iterator over all simplices. The iterator should be sorted in lexagraphic order.
Furthermore, the iterator should overload `Base.length`, `Base.getindex`, and `Base.eltype`. The
element type of the iterator should be a `Tuple{Vararg{Int}}`.

# Standardized Interface
- `dimension(obj)` - Dimension of simplicial complex
- `nSimplices(obj, k::Int)::Int` - Number of k-simplexes
- `simplexIterator(obj, k::Int)` - Iterator over all k-simplices in the same order
    they appear in `simplexIterator(obj)`.
- `kSimplexFaceIdxIter(obj, k::Int)` - Iterate over pairs (i, j) where i indexes the i-th k-simplex and j indexes the j-th face of simplex i, in the order they appear in `simplexIterator()`
- `boundaryMap(obj, i::Int, ring)` - The i-th boundary map ∂_i : C_i -> C_{i-1}, computed
    over `ring`, and returned as a `FreeModuleMorphism`.
- `betti(obj, ring, n::Int)::Int` - The n-th Betti number of the complex, computed over `ring`.

"""

abstract type AbstractSimplicialComplex <: AbstractCategory end

function dimension(
    obj::ObjectInCategory{T, AbstractSimplicialComplex}
) where T
    return maximum(
        simp -> length(simp),
        obj.object.simplexIterator
    )-1
end

function nSimplices(
    obj::ObjectInCategory{T, AbstractSimplicialComplex}, 
    k::Int
) where T
    return count(
        simp -> length(simp) == k+1, 
        simplexIterator(obj)
    )
end

function simplexIterator(
    obj::ObjectInCategory{T, AbstractSimplicialComplex},
    k::Int
) where T
    return filter(
        simp -> length(simp) == k+1,
        simplexIterator(obj)
    )
end

function kSimplexFaceIdxIter(
    obj::ObjectInCategory{T, AbstractSimplicialComplex},
    k::Int
) where T
    if k <= 0
        return Tuple{Int, Int}[]
    end

    kSimplices = simplexIterator(obj, k)
    facetSimplices = simplexIterator(obj, k-1)

    return (
        (i, searchsortedfirst(facetSimplices, (simplex[1:p-1]..., simplex[p+1:end]...)))
        for (i, simplex) in enumerate(kSimplices)
        for p in length(simplex):-1:1
    )
end

function boundaryMap(
    obj::ObjectInCategory{T, AbstractSimplicialComplex},
    i::Int,
    ring::ObjectInCategory{T2, FiniteField}
) where T where T2
    domainModule   = @wrap GenericFreeModule(ring, nSimplices(obj, i))     FreeModule
    codomainModule = @wrap GenericFreeModule(ring, nSimplices(obj, i - 1)) FreeModule

    iSimplices = simplexIterator(obj, i)
    facetSimplices = simplexIterator(obj, i - 1)

    # For an i-simplex [v_0,...,v_i], removing the vertex at position p (1-indexed)
    # gives ∂[v_0,...,v_i] = sum_p (-1)^(p-1) [v_0,...,v̂_p,...,v_i].
    signs = Dict{Tuple{Int, Int}, Int}()
    for (a, b) in kSimplexFaceIdxIter(obj, i)
        simplex = iSimplices[a]
        face = facetSimplices[b]
        p = findfirst(v -> !(v in face), simplex)
        signs[(a, b)] = isodd(p) ? 1 : -1
    end

    matEntry = (a, b) -> begin
        s = get(signs, (a, b), 0)
        return s == 0 ? zero(ring) : (s == 1 ? one(ring) : -one(ring))
    end

    return @wrap GenericFreeModuleMorphism(domainModule, codomainModule, matEntry) FreeModuleMorphism
end

function betti(
    obj::ObjectInCategory{T, AbstractSimplicialComplex},
    ring::ObjectInCategory{T2, FiniteField},
    n::Int
) where T where T2
    dn  = boundaryMap(obj, n, ring)
    dn1 = boundaryMap(obj, n + 1, ring)

    # rank-nullity: dim(ker ∂n) = dim(Cn) - rank(∂n), and dim(im ∂n+1) = rank(∂n+1),
    # so the n-th Betti number is the difference between those two ranks
    return (nSimplices(obj, n) - rank(dn)) - rank(dn1)
end