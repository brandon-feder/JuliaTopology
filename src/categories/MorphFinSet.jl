# =========================================================
# ========== SPECIFY REQUIRED INTERFACE FOR HOMs ==========
# =========================================================

function checkInterface(
    obj, cat::HomLike{DomT, CodT, CatFinSet}
) where DomT where CodT
    return @checkCallable obj cat Tuple{OIC{<:Any, OICAsCat{DomT, CatFinSet}}}
end

# =========================================================
# =============== A GENERIC IMPLEMENTATION ================
# =========================================================

"""
    struct GenericMorphFinSet{DomT, CodT}

An implementation for morphisms in `CatFinSet` which stores
maps as instances of an `AbstractDictionary`, from elements of
`@ascat domain` to elements of `@ascat codomain`. Constructing one checks
nothing; whether it is well defined, and injective or surjective, is checked
when it is wrapped in a `Hom`, `Epi`, `Mono` or `Iso`.
"""
struct GenericMorphFinSet{DomT, CodT}
    domain::OIC{DomT, CatFinSet}
    codomain::OIC{CodT, CatFinSet}
    pairs::AbstractDict
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(
    morph::GenericMorphFinSet, H::HomLike{<:Any, <:Any, CatFinSet}
)
    dom, cod = OICAsCat(domain(H)), OICAsCat(codomain(H))
    mapname = objclr(name(OIC(morph, H; force=true)))

    # the same domain as `H`
    if morph.domain != domain(H)
        throw(NotInCategory(morph, H,
            @annotated """
            The map
            $TAB$mapname
            is not a morphism in $H, since its domain is \
            $(objclr(shortName(morph.domain))) rather than \
            $(objclr(shortName(domain(H)))).
            """
        ))
    end

    # the same codomain as `H`
    if morph.codomain != codomain(H)
        throw(NotInCategory(morph, H,
            @annotated """
            The map
            $TAB$mapname
            is not a morphism in $H, since its codomain is \
            $(objclr(shortName(morph.codomain))) rather than \
            $(objclr(shortName(codomain(H)))).
            """
        ))
    end

    # every key is an element of the domain
    for x in keys(morph.pairs)
        x isa OIC && category(x) == dom && continue
        hint = x isa OIC || !(x in dom) ? "" : @annotated(" It is a plain \
            value, which must first be wrapped as an element, e.g. as \
            $(codeclr("(@ascat X)[x]")).")
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
            $(codeclr("(@ascat X)[x]")).")
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

    # injective, for `Mono` and `Iso`
    if H isa Union{Mono, Iso}
        preimage = Dict{Any, Any}()
        for x in oic(dom)
            y = morph.pairs[x]
            if haskey(preimage, y)
                throw(NotInCategory(morph, H,
                    @annotated """
                    The map
                    $TAB$mapname
                    is not a morphism in $H, since it is not injective: \
                    $(objclr(name(preimage[y]))) and $(objclr(name(x))) both \
                    map to $(objclr(name(y))).
                    """
                ))
            end
            preimage[y] = x
        end
    end

    # surjective, for `Epi` and `Iso`
    if H isa Union{Epi, Iso}
        image = Set(values(morph.pairs))
        missed = [y for y in oic(cod) if !(y in image)]
        if !isempty(missed)
            throw(NotInCategory(morph, H,
                @annotated """
                The map
                $TAB$mapname
                is not a morphism in $H, since it is not surjective: nothing \
                maps to \
                $(join([objclr(name(y)) for y in first(missed, MAX_SET_MAP_PAIRS_SHOWN)],
                    ", "))$(length(missed) > MAX_SET_MAP_PAIRS_SHOWN ? ", …" : "").
                """
            ))
        end
    end

    return true
end

function (morph::OIC{GenericMorphFinSet{DomT, CodT}, <:HomLike{DomT, CodT, CatFinSet}})(
    elem::OIC{<:Any, OICAsCat{DomT, CatFinSet}}
) where DomT where CodT
    return object(morph).pairs[elem]
end

# The inverse of an isomorphism, sending each value back to its key
function Base.inv(
    f::OIC{GenericMorphFinSet{DomT, CodT}, Iso{DomT, CodT, CatFinSet}}
) where DomT where CodT
    H = category(f)
    return Iso(codomain(H), domain(H))[
        Dict(y => x for (x, y) in object(f).pairs)
    ]
end

# =========================================================
# ======================= LAZY MAPS =======================
# =========================================================

"""
    FunctionDict(domain, f)

A lazy `AbstractDict` sending each element `x` of `@ascat domain` to `f(x)`,
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
    g ∘ f

The composite of morphisms `f: X → Y` and `g: Y → Z` of FinSet, sending `x` to
`g(f(x))`, computed lazily. It lies in `Iso(X, Z)` when both are isomorphisms,
in `Mono(X, Z)` when both are monomorphisms, in `Epi(X, Z)` when both are
epimorphisms, and in `Hom(X, Z)` otherwise.
"""
function compose(
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}
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

    Kind = F isa Iso && G isa Iso ? Iso :
        F isa Union{Iso, Mono} && G isa Union{Iso, Mono} ? Mono :
        F isa Union{Iso, Epi} && G isa Union{Iso, Epi} ? Epi : Hom
    return Kind(domain(F), codomain(G))[x -> g(f(x)), force=true]
end

function Base.:∘(
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}
)
    return compose(g, f)
end

"""
    firstDifference(f, g)

For maps `f, g: X → Y` of finite sets, `nothing` when they agree on every
element of `X`, and otherwise `(at = x, left = f(x), right = g(x))` for the
first element `x` where they differ.
"""
function firstDifference(
    f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}
)
    for x in domain(category(f))
        fx, gx = f(x), g(x)
        fx != gx && return (at = x, left = fx, right = gx)
    end
    return nothing
end

"""
    id(X::OIC{<:Any, CatFinSet})

The identity map of the finite set `X`, in `Iso(X, X)`.
"""
id(X::OIC{<:Any, CatFinSet}) = Iso(X, X)[identity, force=true]

# =========================================================
# ===================== CONSTRUCTION ======================
# =========================================================

"""
    H[pairs, force=false]

Construct the morphism in `H :: HomLike{<:Any, <:Any, CatFinSet}` sending `x` to
`y` for each `x => y` in `pairs`, a vector of pairs or an `AbstractDict`, where
each `x` is an element of `@ascat domain(H)` and each `y` one of
`@ascat codomain(H)`, e.g. `Hom(A, B)[[(@ascat A)[1] => (@ascat B)[2]]]`. Throws
an `ArgumentError` for a malformed `pairs` (an entry which is not a pair, an `x`
or `y` which is not such an element, or an `x` given twice), and otherwise a
`NotInCategory` unless the map lies in `H` (see `checkInCategory`).
`force=true` skips all checks.
"""
function Base.getindex(
    H::HomLike{DomT, CodT, CatFinSet},
    pairs::Union{AbstractVector, AbstractDict};
    force::Bool=false
) where DomT where CodT
    dom, cod = OICAsCat(domain(H)), OICAsCat(codomain(H))

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
                        $(codeclr("(@ascat X)[$(repr(v))]")), or take the \
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

    morph = GenericMorphFinSet(domain(H), codomain(H), Dict(pairs))
    return ObjectInCategory(morph, H; force=force)
end

"""
    H[f::Function, force=false]

Construct the morphism in `H :: HomLike{<:Any, <:Any, CatFinSet}` sending each
element `x` of `@ascat domain(H)` to `f(x)`, which must be an element of
`@ascat codomain(H)`, e.g. `Hom(A, B)[x -> (@ascat B)[2 * object(x)]]`. The map
is lazy: `f` is called on each lookup. Throws a `NotInCategory` unless the map
lies in `H` (see `checkInCategory`), which evaluates `f` on the whole domain;
`force=true` skips this.
"""
function Base.getindex(
    H::HomLike{DomT, CodT, CatFinSet}, f::Function; force::Bool=false
) where DomT where CodT
    morph = GenericMorphFinSet(domain(H), codomain(H), FunctionDict(domain(H), f))
    return ObjectInCategory(morph, H; force=force)
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

# The mapping in the order of the domain, e.g. `{1 ↦ :a, 2 ↦ :b, 3 ↦ :c, …}`,
# with `?` for any element a forced, incomplete map leaves unmapped, and a
# plain value shown by its `repr`
function name(oic::OIC{<:GenericMorphFinSet})
    morph = object(oic)
    shown = [
        "$(name(a)) ↦ $(!haskey(morph.pairs, a) ? "?" :
            morph.pairs[a] isa OIC ? name(morph.pairs[a]) : repr(morph.pairs[a]))"
        for a in Iterators.take(morph.domain, MAX_SET_MAP_PAIRS_SHOWN)
    ]
    length(morph.domain) > MAX_SET_MAP_PAIRS_SHOWN && push!(shown, "…")
    return "{$(join(shown, ", "))}"
end