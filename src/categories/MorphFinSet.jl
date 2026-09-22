"""
    struct GenericMorphFinSet

A morphism in [`FinSet`](@ref), stored as an explicit dictionary sending
each element of the domain to an element of the codomain.

# Fields
- `domain::OIC{DomT, CatFinSet}` - The domain
- `codomain::OIC{CodT, CatFinSet}` - The codomain
- `dict::Dict{<:OIC, <:OIC}` - Domain element => codomain element. Both
        keys and values are already objects in category (as returned by
        `getindex` on the domain and codomain).

# Required Interface
- `inCategory(::GenericMorphFinSet, ::HomLike)` - Domain and codomain must
        agree with those of the `Hom`, `Epi`, `Mono` or `Iso`; the map must
        also be surjective (`Epi`), injective (`Mono`) or both (`Iso`)
- `checkInterface(::GenericMorphFinSet, ::HomLike)` - The dict must be defined
        on exactly the elements of the domain, with values in the codomain

# Standardized Interface
- `f(x)` - Apply the map to an element `x` of the domain, giving an
        element of the codomain

Here `f`, `g` are maps of finite sets, `H` is `Hom(D, C)`, `Epi(D, C)`,
`Mono(D, C)` or `Iso(D, C)`, and elements are the objects that `D[i]` and
iteration give; see [`CatFinSet`](@ref). Every construction below checks the
result against `H`, and takes `force=true` to skip that.

## Constructing maps
- `H[dict]` - Build a map from a `Dict`. Same as `H[collect(pairs(dict))]`.
- `H[[x => y, ...]]` - Build a map from pairs, where `x` is an element of `D`
        and `y` an element of `C`. Each side is the plain value the set was
        built from, or an element object such as `D[1]`. Throws an
        `ArgumentError` for a value that is not an element, that occurs more
        than once in its set (so names no single element), or a domain element
        that appears in two pairs.
- `H[x -> y]` - Build a map by applying a function to every element of `D`.
        The function takes and returns element objects (`ObjectInCategory`),
        not plain values, e.g. `H[x -> C[object(x)[1]]]`.
- `H[GenericMorphFinSet(D, C, dict)]` - The explicit form of the above, where
        `dict` maps elements of `D` to elements of `C`.

## Comparing maps
- `f == g`, `hash(f)` - Maps are equal when their domain, codomain and values
        agree, and, for maps in a category, when they are in the same kind of
        `Hom`. Sets are compared by identity, not by content.

## Composition
- `compose(f, g)` and `f ∘ g` - The composite, applying `g` first and then
        `f` (as for functions). The codomain of `g` must be the domain of
        `f`. The result is the most specific of `Iso`, `Mono`, `Epi`, `Hom` that
        the kinds of `f` and `g` guarantee, so `Iso ∘ Mono` is a `Mono`. The
        kind never comes from inspecting the values.
- `id(X)` - The identity of `X`, in `Iso(X, X)`.
- `inv(f)` - The inverse of `f`, for `f` in an `Iso` only. It lies in
        `Iso(C, D)`.
"""
struct GenericMorphFinSet{DomT, CodT}
    domain::OIC{DomT, CatFinSet}
    codomain::OIC{CodT, CatFinSet}
    dict::Dict{<:OIC, <:OIC}
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

# Why `obj` is not a morphism of the kind `Cat`, or `nothing` if it is.
# `Cat` is `Hom`, `Epi`, `Mono` or `Iso` between finite sets; the last three
# also require the map to be injective, surjective or both.
function _notInHomReason(
    obj::GenericMorphFinSet, Cat::HomLike{<:Any, <:Any, CatFinSet}
)
    obj.domain == domain(Cat) || return "the domain of the map is not " *
        "the domain of the $(nameof(typeof(Cat)))"
    obj.codomain == codomain(Cat) || return "the codomain of the map is not " *
        "the codomain of the $(nameof(typeof(Cat)))"
    return _notInKindReason(obj, Cat)
end

_notInKindReason(::GenericMorphFinSet, ::Hom) = nothing
_notInKindReason(obj::GenericMorphFinSet, ::Mono) = _notInjectiveReason(obj)
_notInKindReason(obj::GenericMorphFinSet, ::Epi) = _notSurjectiveReason(obj)
function _notInKindReason(obj::GenericMorphFinSet, ::Iso)
    reason = _notInjectiveReason(obj)
    return reason === nothing ? _notSurjectiveReason(obj) : reason
end

function _notInjectiveReason(obj::GenericMorphFinSet)
    seen = Dict{Any, Any}()
    for (x, y) in obj.dict
        haskey(seen, y) && return "the map is not injective: " *
            "$(repr(object(seen[y]))) and $(repr(object(x))) both map to " *
            "$(repr(object(y)))"
        seen[y] = x
    end
    return nothing
end

function _notSurjectiveReason(obj::GenericMorphFinSet)
    missing_ = setdiff(Set(obj.codomain), Set(values(obj.dict)))
    isempty(missing_) && return nothing
    return "the map is not surjective: nothing maps to " *
        listElements(missing_)
end

function inCategory(
    obj::GenericMorphFinSet{DomT, CodT},
    Cat::HomLike{DomT, CodT, CatFinSet}
) where DomT where CodT
    return _notInHomReason(obj, Cat) === nothing
end

function checkInCategory(
    obj::GenericMorphFinSet{DomT, CodT},
    Cat::HomLike{DomT, CodT, CatFinSet}
) where DomT where CodT
    reason = _notInHomReason(obj, Cat)
    reason === nothing || throw(NotInCategory(obj, Cat, reason))
    return true
end

function checkInterface(
    obj::GenericMorphFinSet,
    Cat::HomLike{<:Any, <:Any, CatFinSet}
)
    dom = Set(domain(Cat))
    cod = Set(codomain(Cat))
    defined = Set(keys(obj.dict))

    missing_ = setdiff(dom, defined)
    isempty(missing_) || throw(InterfaceViolation(obj, Cat,
        "map is not defined on every element of the domain; missing " *
        listElements(missing_)))

    extra = setdiff(defined, dom)
    isempty(extra) || throw(InterfaceViolation(obj, Cat,
        "map is defined on elements that are not in the domain: " *
        listElements(extra)))

    badKeys = [k for (k, v) in obj.dict if !(v in cod)]
    isempty(badKeys) || throw(InterfaceViolation(obj, Cat,
        "map sends elements outside the codomain: " * join(
            ("$(repr(object(k))) => $(repr(object(obj.dict[k])))"
                for k in first(badKeys, 3)), ", ") *
        (length(badKeys) > 3 ? ", ... ($(length(badKeys)) in total)" : "")))
    return true
end

# =========================================================
# ==================== CONSTRUCTION SUGAR =================
# =========================================================

"""
    Base.getindex(H::HomLike{<:Any, <:Any, CatFinSet}, dict::AbstractDict; force=false)

Build a map of finite sets from `dict`, sending elements of the domain of `H`
to elements of its codomain. This is the same as the vector-of-pairs method,
`H[collect(pairs(dict))]`, so keys and values may be plain values or element
objects such as `D[1]`, and they are checked in the same way.

    D, C = FinSet[[1, 2]], FinSet[[:a, :b]]
    Hom(D, C)[Dict(D[i] => C[i] for i in 1:cardinality(D))]
    Hom(D, C)[Dict(1 => :a, 2 => :b)]
"""
function Base.getindex(
    H::HomLike{<:Any, <:Any, CatFinSet}, dict::AbstractDict; force::Bool=false
)
    return getindex(H, collect(pairs(dict)); force=force)
end

"""
    Base.getindex(H::HomLike{<:Any, <:Any, CatFinSet}, pairs::AbstractVector{<:Pair}; force=false)

Build a map of finite sets from a vector of `x => y` pairs, where `x` is an
element of the domain of `H` and `y` an element of its codomain, given as the
plain values the sets were built from:

    D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b]]
    Hom(D, C)[[1 => :a, 2 => :b, 3 => :a]]
    Hom(D, C)[[i => mod1(i, 2) == 1 ? :a : :b for i in 1:3]]

A side that is already an element object such as `D[1]` is used as is. Throws
an `ArgumentError` if a value is not an element of its set or if an element of
the domain appears in more than one pair. As with the `Dict` method, the result
is checked against `H` unless `force=true`.
"""
function Base.getindex(
    H::HomLike{<:Any, <:Any, CatFinSet}, pairs::AbstractVector{<:Pair};
    force::Bool=false
)
    domTable = _elementTable(domain(H))
    codTable = _elementTable(codomain(H))

    dict = Dict{OIC, OIC}()
    for (x, y) in pairs
        key = _resolveElement(domTable, x, "domain")
        haskey(dict, key) && throw(ArgumentError(
            "$(repr(x)) appears in more than one pair; a map sends each " *
            "element of the domain to exactly one element"))
        dict[key] = _resolveElement(codTable, y, "codomain")
    end

    morph = GenericMorphFinSet(domain(H), codomain(H), dict)
    return ObjectInCategory(morph, H; force=force)
end

"""
    Base.getindex(H::HomLike{<:Any, <:Any, CatFinSet}, f::Function; force=false)

Build a map of finite sets by applying `f` to every element of the domain of
`H`. Unlike the `Dict` and vector-of-pairs methods, `f` works with element
objects only: it receives an element of the domain (an `ObjectInCategory`) and
must return an element of the codomain, such as `C[j]`.

    D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b, :c]]
    Hom(D, C)[x -> C[object(x)[1]]]     # the i-th element to the i-th element

Throws an `ArgumentError` if `f` returns something that is not an
`ObjectInCategory`. As with the other methods, the result is checked against
`H` unless `force=true`, which is where an element of the wrong set is caught.
"""
function Base.getindex(
    H::HomLike{<:Any, <:Any, CatFinSet}, f::Function; force::Bool=false
)
    dict = Dict{OIC, OIC}()
    for elem in domain(H)
        y = f(elem)
        y isa OIC || throw(ArgumentError(
            "the function must return an element of the codomain (an " *
            "ObjectInCategory such as `C[j]`), but returned $(repr(y)) for " *
            "$(repr(object(elem)))"))
        dict[elem] = y
    end
    morph = GenericMorphFinSet(domain(H), codomain(H), dict)
    return ObjectInCategory(morph, H; force=force)
end

# Map each plain value of a finite set to its element object. A value that
# occurs more than once maps to `nothing`, since it names no single element.
function _elementTable(set::OIC{<:Any, CatFinSet})
    table = Dict{Any, Union{OIC, Nothing}}()
    for elem in set
        x = _elementValue(elem)
        table[x] = haskey(table, x) ? nothing : elem
    end
    return table
end

_resolveElement(::Dict, elem::OIC, ::String) = elem
function _resolveElement(table::Dict, x, side::String)
    haskey(table, x) || throw(ArgumentError(
        "$(repr(x)) is not an element of the $side"))
    elem = table[x]
    elem === nothing && throw(ArgumentError(
        "$(repr(x)) occurs more than once in the $side, so it does not name " *
        "a single element; give the element itself instead, e.g. " *
        "`$(side)[i]` for its i-th element"))
    return elem
end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

function (F::OIC{GenericMorphFinSet{T1, T2}, <:HomLike{T1, T2, CatFinSet}})(x::OIC{<:Any, <:OICAsCat{T1, CatFinSet}}) where T1 where T2
    return object(F).dict[x]
end

# =========================================================
# ======================== EQUALITY =======================
# =========================================================

# Maps are equal when they have the same domain, codomain and values. The
# generic `==` would compare the `dict` field by identity.
function Base.:(==)(f::GenericMorphFinSet, g::GenericMorphFinSet)
    return f.domain == g.domain && f.codomain == g.codomain &&
        f.dict == g.dict
end

function Base.hash(f::GenericMorphFinSet, h::UInt)
    return hash(f.dict, hash(f.codomain, hash(f.domain,
        hash(:GenericMorphFinSet, h))))
end

"""
    FinSetMap

An [`ObjectInCategory`](@ref) holding a [`GenericMorphFinSet`](@ref) in one of
`Hom`, `Epi`, `Mono` or `Iso` between finite sets.
"""
const FinSetMap = OIC{<:GenericMorphFinSet, <:HomLike{<:Any, <:Any, CatFinSet}}

# Equality is only defined for maps: content equality on every `OIC` would
# make hashing an element hash the whole set it belongs to.
function Base.:(==)(f::FinSetMap, g::FinSetMap)
    return object(f) == object(g) && category(f) == category(g)
end

function Base.hash(f::FinSetMap, h::UInt)
    return hash(object(f), hash(category(f), h))
end

# =========================================================
# ==================== COMPOSITION, ETC ===================
# =========================================================

_isInjectiveKind(::Union{Mono, Iso}) = true
_isInjectiveKind(::Union{Hom, Epi}) = false
_isSurjectiveKind(::Union{Epi, Iso}) = true
_isSurjectiveKind(::Union{Hom, Mono}) = false

# The most specific kind of `Hom` for a map known to be injective/surjective
_homKind(injective, surjective) =
    injective ? (surjective ? Iso : Mono) : (surjective ? Epi : Hom)

"""
    compose(f, g)
    f ∘ g

The composite of two maps of finite sets, applying `g` first and then `f`, as
for `∘` on functions. The codomain of `g` must be the domain of `f`. The result
is an `Iso`, `Mono`, `Epi` or `Hom`, whichever is the most specific kind that
both maps guarantee.
"""
function compose(f::FinSetMap, g::FinSetMap)
    fCat, gCat = category(f), category(g)
    domain(fCat) == codomain(gCat) || throw(ArgumentError(
        "cannot compose: the codomain of the map applied first is not the " *
        "domain of the map applied second"))

    kind = _homKind(
        _isInjectiveKind(fCat) && _isInjectiveKind(gCat),
        _isSurjectiveKind(fCat) && _isSurjectiveKind(gCat),
    )
    fDict = object(f).dict
    dict = Dict{OIC, OIC}(x => fDict[y] for (x, y) in object(g).dict)

    # composing valid maps gives a valid map of the kind chosen above
    morph = GenericMorphFinSet(domain(gCat), codomain(fCat), dict)
    return ObjectInCategory(
        morph, kind(domain(gCat), codomain(fCat)); force=true)
end

Base.:∘(f::FinSetMap, g::FinSetMap) = compose(f, g)

"""
    id(X)

The identity map of the finite set `X`, an `Iso` from `X` to itself.
"""
function id(X::OIC{<:Any, CatFinSet})
    dict = Dict{OIC, OIC}(elem => elem for elem in X)
    return ObjectInCategory(
        GenericMorphFinSet(X, X, dict), Iso(X, X); force=true)
end

"""
    inv(f)

The inverse of an isomorphism `f` of finite sets, an `Iso` from its codomain to
its domain. Only maps in `Iso` have an inverse.
"""
function Base.inv(f::OIC{<:GenericMorphFinSet, <:Iso{<:Any, <:Any, CatFinSet}})
    dom, cod = domain(category(f)), codomain(category(f))
    dict = Dict{OIC, OIC}(y => x for (x, y) in object(f).dict)
    return ObjectInCategory(
        GenericMorphFinSet(cod, dom, dict), Iso(cod, dom); force=true)
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

function name(::OIC{<:GenericMorphFinSet, <:HomLike{<:Any, <:Any, CatFinSet}})
    return "A Set Map"
end
