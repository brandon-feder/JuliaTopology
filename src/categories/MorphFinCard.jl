"""
    struct GenericMorphFinCard{V <: AbstractVector{<:Integer}}

A morphism of [`FinCard`](@ref): a vector `map::V` of length `n` with entries
in `1:m`, sending `i` to `map[i]`. `V` may be any array type, such as a GPU
array. The constructor stores `map` itself, without copying it, so it must
not be mutated afterwards. It lies in
`Hom(FinCard[n], FinCard[m])`, and further in `Epi`, `Mono` or `Iso` when the
map is surjective, injective, or both.

# Construction
`GenericMorphFinCard(D, C, map; force=false)` throws an `ArgumentError` unless
- `length(map) == cardinality(D)` - defined on exactly the domain.
- `all(v -> v in 1:cardinality(C), map)` - lands in the codomain.

Pass `force=true` to skip this.

# Required Interface
None beyond `f(i)`, which is defined for every `GenericMorphFinCard`, so
`checkInterface` always succeeds. `checkInCategory` requires the domain and
codomain to match `H`, and the map to be injective (for `Mono`), surjective
(for `Epi`), or both (for `Iso`).

# Standardized Interface
- `H[v]`, `H[f::Function]`, `H[GenericMorphFinCard(D, C, v)]` - construct a
        map in `H`; each checks that the map is well defined and lies in `H`
        unless `force=true`.
- `f(i)` - apply `f` to `i ∈ 1:cardinality(D)`.
- `f == g`, `hash(f)` - equal domain, codomain and values (and kind, for maps
        wrapped in `H`).
- `compose(f, g)`, `f ∘ g` - the composite, applying `g` first; the most
        specific kind (`Iso`/`Mono`/`Epi`/`Hom`) that `f` and `g` guarantee.
- `id(X)::Iso`, `inv(f)` (for `f :: Iso`).

# Interface Specification Assumptions
- `f, g :: GenericMorphFinCard`.
- `H :: HomLike{Int, Int, CatFinCard}`, one of `Hom(D, C)`, `Epi(D, C)`,
        `Mono(D, C)`, `Iso(D, C)`.
- `D, C :: FinCard`, the domain and codomain of `H`.
- `v :: AbstractVector{<:Integer}`, `i :: Integer`.
"""
struct GenericMorphFinCard{V <: AbstractVector{<:Integer}}
    domain::OIC{Int, CatFinCard}
    codomain::OIC{Int, CatFinCard}
    map::V

    function GenericMorphFinCard(
        domain::OIC{Int, CatFinCard}, codomain::OIC{Int, CatFinCard},
        map::V; force::Bool=false
    ) where V <: AbstractVector{<:Integer}
        if !force
            n, m = cardinality(domain), cardinality(codomain)
            length(map) == n || throw(ArgumentError(
                "map must have one entry per element of the domain, i.e. " *
                "length $n, but has length $(length(map))"))

            inCod(v) = 1 <= v <= m
            all(inCod, map) || throw(ArgumentError(
                _outsideCodomainMessage(collect(map), m)))
        end
        return new{V}(domain, codomain, map)
    end
end

# Only reached once a check has failed, so it works on a CPU copy of the map.
function _outsideCodomainMessage(map::Vector{<:Integer}, m::Integer)
    bad = findall(v -> !(1 <= v <= m), map)
    return "map sends elements outside the codomain 1:$m: " * join(
        ("$i => $(map[i])" for i in first(bad, 3)), ", ") *
        (length(bad) > 3 ? ", ... ($(length(bad)) in total)" : "")
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

# Why `obj` is not a morphism of the kind `Cat`, or `nothing` if it is.
# `Cat` is `Hom`, `Epi`, `Mono` or `Iso` between finite cardinals; the last
# three also require the map to be injective, surjective or both.
function _notInHomReason(
    obj::GenericMorphFinCard, Cat::HomLike{Int, Int, CatFinCard}
)
    obj.domain == domain(Cat) || return "the domain of the map is not " *
        "the domain of the $(nameof(typeof(Cat)))"
    obj.codomain == codomain(Cat) || return "the codomain of the map is not " *
        "the codomain of the $(nameof(typeof(Cat)))"
    return _notInKindReason(obj, Cat)
end

# The checks below only use whole-array operations (`similar`, `fill!`,
# broadcasting, `count`, `all`), so they run on whatever array backend holds
# the map (e.g. a `CuArray`) without scalar indexing. Only the error messages,
# built once a check has failed, copy the map to the CPU.

_notInKindReason(::GenericMorphFinCard, ::Hom) = nothing

function _notInKindReason(obj::GenericMorphFinCard, ::Mono)
    n, m = length(obj.map), cardinality(obj.codomain)
    # pigeonhole: skip counting when the map cannot be injective
    n <= m && count(_hits(obj.map, m)) == n && return nothing
    return _notInjectiveReason(obj)
end

function _notInKindReason(obj::GenericMorphFinCard, ::Epi)
    hits = _hits(obj.map, cardinality(obj.codomain))
    return all(hits) ? nothing : _notSurjectiveReason(hits)
end

function _notInKindReason(obj::GenericMorphFinCard, ::Iso)
    n, m = length(obj.map), cardinality(obj.codomain)
    n > m && return _notInjectiveReason(obj)
    hits = _hits(obj.map, m)
    # `n` elements hitting `n` distinct values of `1:m`: injective, and
    # surjective exactly when `n == m`
    count(hits) == n || return _notInjectiveReason(obj)
    return n == m ? nothing : _notSurjectiveReason(hits)
end

# `hits[j]` is whether some element maps to `j`, on the backend of `map`. The
# entries of `map` must lie in `1:m`, which the constructor checks.
function _hits(map::AbstractVector{<:Integer}, m::Integer)
    hits = fill!(similar(map, Bool, m), false)
    hits[map] .= true
    return hits
end

# Only called once the map is known not to be injective.
function _notInjectiveReason(obj::GenericMorphFinCard)
    map = collect(obj.map)
    firstPreimage = zeros(Int, cardinality(obj.codomain))
    for (i, v) in enumerate(map)
        j = firstPreimage[v]
        j == 0 || return "the map is not injective: " *
            "$j and $i both map to $v"
        firstPreimage[v] = i
    end
    error("unreachable: the map is injective")
end

# Only called once the map is known not to be surjective.
function _notSurjectiveReason(hits::AbstractVector{Bool})
    missing_ = findall(!, collect(hits))
    shown = join(first(missing_, 3), ", ")
    return "the map is not surjective: nothing maps to " * (
        length(missing_) > 3 ?
            "$shown, ... ($(length(missing_)) in total)" : shown)
end

function checkInCategory(
    obj::GenericMorphFinCard, Cat::HomLike{Int, Int, CatFinCard}
)
    reason = _notInHomReason(obj, Cat)
    reason === nothing || throw(NotInCategory(obj, Cat, reason))
    return true
end

# The only required method, `f(i)`, is defined below for every
# `GenericMorphFinCard`; well-definedness is checked by the constructor.
checkInterface(
    ::GenericMorphFinCard, ::HomLike{Int, Int, CatFinCard}
) = true

# =========================================================
# ==================== CONSTRUCTION SUGAR =================
# =========================================================

"""
    Base.getindex(H::HomLike{Int, Int, CatFinCard}, v::AbstractVector{<:Integer}; force=false)

Build a map of finite cardinals sending `i` to `v[i]`:

    Hom(FinCard[3], FinCard[2])[[1, 2, 1]]

The result is checked against `H` unless `force=true`.
"""
function Base.getindex(
    H::HomLike{Int, Int, CatFinCard}, v::AbstractVector{<:Integer};
    force::Bool=false
)
    morph = GenericMorphFinCard(domain(H), codomain(H), v; force=force)
    return ObjectInCategory(morph, H; force=force)
end

"""
    Base.getindex(H::HomLike{Int, Int, CatFinCard}, f::Function; force=false)

Build a map of finite cardinals by applying `f` to every `i` in the domain of
`H`; `f` must return an `Integer` in the codomain.

    Hom(FinCard[3], FinCard[3])[i -> 4 - i]

Throws an `ArgumentError` if `f` returns something that is not an `Integer`.
As with the vector method, the result is checked against `H` unless
`force=true`.
"""
function Base.getindex(
    H::HomLike{Int, Int, CatFinCard}, f::Function; force::Bool=false
)
    v = Vector{Int}(undef, cardinality(domain(H)))
    for i in eachindex(v)
        y = f(i)
        y isa Integer || throw(ArgumentError(
            "the function must return an element of the codomain (an " *
            "Integer), but returned $(repr(y)) for $i"))
        v[i] = y
    end
    return getindex(H, v; force=force)
end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    FinCardMap

An [`ObjectInCategory`](@ref) holding a [`GenericMorphFinCard`](@ref) in one
of `Hom`, `Epi`, `Mono` or `Iso` between finite cardinals.
"""
const FinCardMap = OIC{<:GenericMorphFinCard, <:HomLike{Int, Int, CatFinCard}}

function (F::FinCardMap)(i::Integer)
    n = cardinality(domain(category(F)))
    1 <= i <= n || throw(ArgumentError(
        "$i is not an element of the domain 1:$n"))
    return object(F).map[i]
end

# =========================================================
# ======================== EQUALITY =======================
# =========================================================

function Base.:(==)(f::GenericMorphFinCard, g::GenericMorphFinCard)
    return f.domain == g.domain && f.codomain == g.codomain && f.map == g.map
end

# `hash` reads the map element by element, so a map on another backend (e.g. a
# GPU array) is copied to the CPU first. `Array` and ranges hash consistently
# with each other, as `==` requires.
_hostMap(map::Union{Array, AbstractRange}) = map
_hostMap(map::AbstractVector) = Array(map)

function Base.hash(f::GenericMorphFinCard, h::UInt)
    return hash(_hostMap(f.map), hash(f.codomain, hash(f.domain,
        hash(:GenericMorphFinCard, h))))
end

function Base.:(==)(f::FinCardMap, g::FinCardMap)
    return object(f) == object(g) && category(f) == category(g)
end

function Base.hash(f::FinCardMap, h::UInt)
    return hash(object(f), hash(category(f), h))
end

# =========================================================
# ==================== COMPOSITION, ETC ===================
# =========================================================

"""
    compose(f, g)
    f ∘ g

The composite of two maps of finite cardinals, applying `g` first and then
`f`, as for `∘` on functions. The codomain of `g` must be the domain of `f`.
The result is an `Iso`, `Mono`, `Epi` or `Hom`, whichever is the most specific
kind that both maps guarantee.
"""
function compose(f::FinCardMap, g::FinCardMap)
    fCat, gCat = category(f), category(g)
    domain(fCat) == codomain(gCat) || throw(ArgumentError(
        """
        Cannot compose `f ∘ g`. The map `g` is applied first, so its \
        codomain
        $TAB$(codomain(gCat)),
        must be the domain of `f`
        $TAB$(domain(fCat)).
        """
    ))

    kind = _homKind(
        _isInjectiveKind(fCat) && _isInjectiveKind(gCat),
        _isSurjectiveKind(fCat) && _isSurjectiveKind(gCat),
    )

    # composing valid maps gives a valid map of the kind chosen above
    morph = GenericMorphFinCard(domain(gCat), codomain(fCat),
        object(f).map[object(g).map]; force=true)
    return ObjectInCategory(
        morph, kind(domain(gCat), codomain(fCat)); force=true)
end

Base.:∘(f::FinCardMap, g::FinCardMap) = compose(f, g)

"""
    id(X)

The identity map of the finite cardinal `X`, an `Iso` from `X` to itself.
"""
function id(X::OIC{Int, CatFinCard})
    return ObjectInCategory(
        GenericMorphFinCard(X, X, Base.OneTo(cardinality(X)); force=true),
        Iso(X, X); force=true)
end

"""
    inv(f)

The inverse of an isomorphism `f` of finite cardinals, an `Iso` from its
codomain to its domain. Only maps in `Iso` have an inverse.
"""
function Base.inv(f::OIC{<:GenericMorphFinCard, <:Iso{Int, Int, CatFinCard}})
    dom, cod = domain(category(f)), codomain(category(f))
    return ObjectInCategory(
        GenericMorphFinCard(cod, dom, _invperm(object(f).map); force=true),
        Iso(cod, dom); force=true)
end

# The inverse of the permutation `map`, on the backend of `map`: `inverse[j]`
# is the `i` with `map[i] == j`.
function _invperm(map::AbstractVector{<:Integer})
    inverse = similar(map)
    inverse[map] .= eachindex(map)
    return inverse
end

function Base.inv(f::FinCardMap)
    H = category(f)
    reason = _notInKindReason(object(f), Iso(domain(H), codomain(H)))
    hint = reason === nothing ?
        """
        However, the map is bijective, so it can be rebuilt as an \
        isomorphism with
        $(TAB)Iso(domain(H), codomain(H))[object(f).map],
        where `H = category(f)`.
        """ :
        """
        Moreover, the map cannot be an isomorphism: $reason.
        """
    throw(ArgumentError(
        """
        Only morphisms in the category $(catclr("Iso")) have an inverse. \
        However, the morphism is in the category
        $TAB$H.
        $hint
        """
    ))
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

function name(::FinCardMap)
    return "A Card Map"
end
