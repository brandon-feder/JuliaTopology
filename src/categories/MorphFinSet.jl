# =========================================================
# ========== SPECIFY REQUIRED INTERFACE FOR HOMs ==========
# =========================================================

function checkInterface(
    obj, cat::Hom{DomT, CodT, CatFinSet}
) where DomT where CodT
    return @checkCallable obj cat Tuple{OIC{<:Any, OICAsCat{DomT, CatFinSet}}}
end

# =========================================================
# =============== A GENERIC IMPLEMENTATION ================
# =========================================================

"""
    GenericMorphFinSet(pairs)

An implementation for morphisms in `CatFinSet` which stores a map as an
`AbstractDict`, from elements of `ascat(X)` to elements of `ascat(Y)`; its
domain `X` and codomain `Y` are those of the `Hom(X, Y)` it is wrapped in.
Constructing one checks nothing; whether it is a well defined map is checked
when it is wrapped.
"""
struct GenericMorphFinSet
    pairs::AbstractDict
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(
    morph::GenericMorphFinSet, H::Hom{<:Any, <:Any, CatFinSet}
)
    dom, cod = OICAsCat(domain(H)), OICAsCat(codomain(H))
    mapname = objclr(name(OIC(morph, H; force=true)))

    # every key is an element of the domain
    for x in keys(morph.pairs)
        x isa OIC && category(x) == dom && continue
        hint = x isa OIC || !(x in dom) ? "" : @annotated(" It is a plain \
            value, which must first be wrapped as an element, e.g. as \
            $(codeclr("ascat(X)[x]")).")
        throw(NotInCategory(morph, H,
            @annotated """
            The map
            $TAB$mapname
            is not a morphism in $H, since its key
            $TAB$(x isa OIC ? x : valclr(x))
            is not an element of its domain $dom.$hint
            """
        ))
    end

    # every element of the domain is mapped
    unmapped = [x for x in oic(dom) if !haskey(morph.pairs, x)]
    if !isempty(unmapped)
        throw(NotInCategory(morph, H,
            @annotated """
            The map
            $TAB$mapname
            is not a morphism in $H, since it does not map \
            $(join([objclr(name(x)) for x in first(unmapped, MAX_SET_MAP_PAIRS_SHOWN)],
                ", "))$(length(unmapped) > MAX_SET_MAP_PAIRS_SHOWN ? ", …" : "").
            """
        ))
    end

    # every value is an element of the codomain, in the order of the domain
    for x in oic(dom)
        y = morph.pairs[x]
        y isa OIC && category(y) == cod && continue
        hint = y isa OIC || !(y in cod) ? "" : @annotated(" It is a plain \
            value, which must first be wrapped as an element, e.g. as \
            $(codeclr("ascat(X)[x]")).")
        throw(NotInCategory(morph, H,
            @annotated """
            The map
            $TAB$mapname
            is not a morphism in $H, since it maps $(objclr(name(x))) to
            $TAB$(y isa OIC ? y : valclr(y))
            which is not an element of its codomain $cod.$hint
            """
        ))
    end

    return true
end

function (morph::OIC{GenericMorphFinSet, <:Hom{DomT, <:Any, CatFinSet}})(
    elem::OIC{<:Any, OICAsCat{DomT, CatFinSet}}
) where DomT
    return object(morph).pairs[elem]
end

"""
    isMono(f)

Whether the map `f` of finite sets is injective, i.e. a monomorphism.
"""
function isMono(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}})
    values = [f(x) for x in domain(category(f))]
    return allunique(values)
end

"""
    isEpi(f)

Whether the map `f` of finite sets is surjective, i.e. an epimorphism.
"""
function isEpi(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}})
    image = Set(f(x) for x in domain(category(f)))
    return all(y -> y in image, codomain(category(f)))
end

"""
    isIso(f)

Whether the map `f` of finite sets is bijective, i.e. an isomorphism.
"""
isIso(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}) = isMono(f) && isEpi(f)

"""
    inv(f; force=false)

The inverse of a bijective map `f` of finite sets, sending each value back to
the element it came from. Throws an `ArgumentError` unless `f` is a bijection;
`force=true` skips this check, which evaluates `f` on its whole domain.
"""
function Base.inv(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}; force::Bool=false)
    # bijective
    if !force && !isIso(f)
        throw(ArgumentError(
            @annotated """
            The map
            $TAB$f
            has no inverse, since it is not a bijection.
            """
        ))
    end
    H = category(f)
    return Hom(codomain(H), domain(H))[
        Dict(f(x) => x for x in domain(H)), force=true
    ]
end

# =========================================================
# ======================= LAZY MAPS =======================
# =========================================================

"""
    FunctionDict(domain, f)

A lazy `AbstractDict` sending each element `x` of `ascat(domain)` to `f(x)`,
computed on lookup rather than stored. Used as the pairs of a
[`GenericMorphFinSet`](@ref), e.g. through `H[f::Function]`.
"""
struct FunctionDict <: AbstractDict{Any, Any}
    domain::OIC{<:Any, CatFinSet}
    f::Function
end

Base.haskey(d::FunctionDict, x) =
    x isa OIC && category(x) == OICAsCat(d.domain)

function Base.getindex(d::FunctionDict, x)
    haskey(d, x) || throw(KeyError(x))
    return d.f(x)
end

Base.get(d::FunctionDict, x, default) = haskey(d, x) ? d.f(x) : default

Base.length(d::FunctionDict) = cardinality(d.domain)

function Base.iterate(d::FunctionDict, state...)
    next = iterate(d.domain, state...)
    next === nothing && return nothing
    x, rest = next
    return x => d.f(x), rest
end

# =========================================================
# ====================== COMPOSITION ======================
# =========================================================

"""
    compose(g, f)

The composite of morphisms `f: X → Y` and `g: Y → Z` of FinSet, sending `x` to
`g(f(x))`, computed lazily.
"""
function compose(
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}},
    f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}
)
    G, F = category(g), category(f)

    # `f` lands where `g` starts
    if codomain(F) != domain(G)
        throw(ArgumentError(
            @annotated """
            The morphisms
            $TAB$g
            and
            $TAB$f
            cannot be composed, since the codomain \
            $(objclr(shortName(codomain(F)))) of the second is not the domain \
            $(objclr(shortName(domain(G)))) of the first.
            """
        ))
    end

    return Hom(domain(F), codomain(G))[x -> g(f(x)), force=true]
end

"""
    firstDifference(f, g)

For maps `f, g: X → Y` of finite sets, `nothing` when they agree on every
element of `X`, and otherwise `(path = (x,), left = f(x), right = g(x))` for the
first element `x` where they differ.
"""
function firstDifference(
    f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}
)
    for x in domain(category(f))
        fx, gx = f(x), g(x)
        fx != gx && return (path = (x,), left = fx, right = gx)
    end
    return nothing
end

"""
    id(X::OIC{<:Any, CatFinSet})

The identity map of the finite set `X`.
"""
id(X::OIC{<:Any, CatFinSet}) = Hom(X, X)[identity, force=true]

# =========================================================
# ===================== CONSTRUCTION ======================
# =========================================================

"""
    H[pairs, force=false, values=false]

Construct the morphism in `H :: Hom{<:Any, <:Any, CatFinSet}` sending `x` to
`y` for each `x => y` in `pairs`, a vector of pairs or an `AbstractDict`, where
each `x` is an element of `ascat(domain(H))` and each `y` one of
`ascat(codomain(H))`, e.g. `Hom(A, B)[[ascat(A)[1] => ascat(B)[2]]]`. With
`values=true`, each `x` and `y` is a plain value instead, which is wrapped, e.g.
`Hom(A, B)[[1 => 2], values=true]`. Throws
an `ArgumentError` for a malformed `pairs` (an entry which is not a pair, an `x`
or `y` which is not such an element, or an `x` given twice), and otherwise a
`NotInCategory` unless the map lies in `H` (see `checkInCategory`).
`force=true` skips all checks.
"""
function Base.getindex(
    H::Hom{DomT, CodT, CatFinSet},
    pairs::Union{AbstractVector, AbstractDict};
    force::Bool=false, values::Bool=false
) where DomT where CodT
    dom, cod = OICAsCat(domain(H)), OICAsCat(codomain(H))

    # given as plain values, wrapped as elements, each checked unless `force`
    if values
        pairs = [p isa Pair ? (dom[first(p), force=force] => cod[last(p), force=force]) : p
            for p in pairs]
    end

    # `pairs` can be made into a `Dict` of elements: each entry is a pair of an
    # element of `dom` and one of `cod`, and no element of `dom` is given twice
    # (which a `Dict` would silently drop). Whether the result is a morphism is
    # left to `checkInCategory`.
    if !force
        seen = Dict{Any, Any}()
        for p in pairs
            # a pair
            if !(p isa Pair)
                throw(ArgumentError(
                    @annotated """
                    Every entry of the vector must be a pair \
                    $(codeclr("x => y")), but it contains
                    $TAB$(valclr(p)).
                    """
                ))
            end
            x, y = p

            # keys and values are already elements, not plain values
            for (role, v, cat) in (("key", x, dom), ("value", y, cod))
                if !(v isa OIC)
                    throw(ArgumentError(
                        @annotated """
                        The $role
                        $TAB$(valclr(v))
                        is a plain value, but the keys and values must be \
                        elements of $dom and $cod. You may wrap it, e.g. as \
                        $(codeclr("ascat(X)[$(repr(v))]")), or take the \
                        elements from iterating over the domain and codomain.
                        """
                    ))
                end
            end

            # from an element of the domain
            if category(x) != dom
                throw(ArgumentError(
                    @annotated """
                    The key
                    $TAB$x
                    is not an element of the domain $dom.
                    """
                ))
            end

            # to an element of the codomain
            if category(y) != cod
                throw(ArgumentError(
                    @annotated """
                    The value
                    $TAB$y
                    of the key $(objclr(name(x))) is not an element of the \
                    codomain $cod.
                    """
                ))
            end

            # given only once
            if haskey(seen, x)
                throw(ArgumentError(
                    @annotated """
                    The element $(objclr(name(x))) of the domain is mapped twice, \
                    to $(objclr(name(seen[x]))) and to $(objclr(name(y))).
                    """
                ))
            end
            seen[x] = y
        end
    end

    morph = GenericMorphFinSet(Dict(pairs))
    return ObjectInCategory(morph, H; force=force)
end

"""
    H[f::Function, force=false, values=false]

Construct the morphism in `H :: Hom{<:Any, <:Any, CatFinSet}` sending each
element `x` of `ascat(domain(H))` to `f(x)`, which must be an element of
`ascat(codomain(H))`, e.g. `Hom(A, B)[x -> ascat(B)[2 * object(x)]]`. With
`values=true`, `f` takes and returns plain values instead, e.g.
`Hom(A, B)[x -> 2x, values=true]`. The map is lazy: `f` is called on each
lookup. Throws a `NotInCategory` unless the map
lies in `H` (see `checkInCategory`), which evaluates `f` on the whole domain;
`force=true` skips this.
"""
function Base.getindex(
    H::Hom{DomT, CodT, CatFinSet}, f::Function; force::Bool=false,
    values::Bool=false
) where DomT where CodT
    # on plain values: unwrap each element, and wrap its image, checked unless
    # `force`
    if values
        cod, g = OICAsCat(codomain(H)), f
        f = x -> cod[g(object(x)), force=force]
    end
    morph = GenericMorphFinSet(FunctionDict(domain(H), f))
    return ObjectInCategory(morph, H; force=force)
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

# The mapping in the order of the domain, e.g. `{1 ↦ :a, 2 ↦ :b, 3 ↦ :c, …}`,
# with `?` for any element a forced, incomplete map leaves unmapped, and a
# plain value shown by its `repr`
function name(oic::OIC{GenericMorphFinSet})
    morph, X = object(oic), domain(category(oic))
    shown = [
        "$(name(a)) ↦ $(!haskey(morph.pairs, a) ? "?" :
            morph.pairs[a] isa OIC ? name(morph.pairs[a]) : repr(morph.pairs[a]))"
        for a in Iterators.take(X, MAX_SET_MAP_PAIRS_SHOWN)
    ]
    cardinality(X) > MAX_SET_MAP_PAIRS_SHOWN && push!(shown, "…")
    return "{$(join(shown, ", "))}"
end