"""
    Comma(F, G)
    F ↓ G

The comma category `(F ↓ G)` of functors `F: A → C` and `G: B → C`, i.e.
objects of `Hom(Cat[A], Cat[C])` and `Hom(Cat[B], Cat[C])`.

Its objects are [`ObjComma`](@ref)s `(a, b, h)`, with `a` an object of `A`,
`b` one of `B`, and `h: F(a) → G(b)` a morphism of `C`. Its morphisms
`(a, b, h) → (a′, b′, h′)` are [`MorphComma`](@ref)s `(α, β)`, with `α: a → a′`
in `A` and `β: b → b′` in `B` such that `G(β) ∘ h == h′ ∘ F(α)`.

# Standardized Interface
- `source(o)`, `target(o)`, `arrow(o)` — the `a`, `b` and `h` of an object `o`
- `compose(n, m)`, `id(o)` — componentwise

# Interface Specification Assumptions
- `F, G` are functors with the same codomain `C`
- `o` is an object of `Comma(F, G)`; `m, n` are morphisms between them
"""
struct Comma{FT, GT} <: Category
    F::FT
    G::GT

    function Comma(F::FT, G::GT) where FT where GT
        # both are functors
        for (side, H) in (("first", F), ("second", G))
            if !(H isa OIC && category(H) isa HomLike{<:Any, <:Any, CatCat})
                throw(ArgumentError(
                    @annotated """
                    The $side argument of a comma category must be a \
                    functor, i.e. an object of \
                    $(codeclr("Hom(Cat[A], Cat[C])")), but it is
                    $TAB$(H isa OIC ? H : valclr(H)).
                    """
                ))
            end
        end

        # into the same category
        if codomain(category(F)) != codomain(category(G))
            throw(ArgumentError(
                @annotated """
                The functors of a comma category must have the same \
                codomain, but
                $TAB$F
                and
                $TAB$G
                land in $(object(codomain(category(F)))) and \
                $(object(codomain(category(G)))).
                """
            ))
        end

        return new{FT, GT}(F, G)
    end
end

"""
    F ↓ G

The comma category `(F ↓ G)`, i.e. `Comma(F, G)`.
"""
↓(F, G) = Comma(F, G)

"""
    ObjComma(source, target, arrow)

An object `(a, b, h)` of a [`Comma`](@ref) category `(F ↓ G)`: an object `a`
of the domain of `F`, an object `b` of the domain of `G`, and a morphism
`h: F(a) → G(b)`.
"""
struct ObjComma
    source::OIC
    target::OIC
    arrow::OIC
end

"""
    MorphComma(sourceMorph, targetMorph)

A morphism `(α, β)` of a [`Comma`](@ref) category `(F ↓ G)`, from `(a, b, h)`
to `(a′, b′, h′)`: morphisms `α: a → a′` and `β: b → b′` such that
`G(β) ∘ h == h′ ∘ F(α)`.
"""
struct MorphComma
    sourceMorph::OIC
    targetMorph::OIC
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj::ObjComma, K::Comma)
    A = object(domain(category(K.F)))
    B = object(domain(category(K.G)))
    C = object(codomain(category(K.F)))

    # `a` is an object of `A`
    if category(obj.source) != A
        throw(NotInCategory(obj, K,
            @annotated """
            The source
            $TAB$(obj.source)
            is not an object of $A, the domain of $(K.F), so it cannot be \
            the source of an object of $K.
            """
        ))
    end

    # `b` is an object of `B`
    if category(obj.target) != B
        throw(NotInCategory(obj, K,
            @annotated """
            The target
            $TAB$(obj.target)
            is not an object of $B, the domain of $(K.G), so it cannot be \
            the target of an object of $K.
            """
        ))
    end

    # `h` is a morphism of `C`
    if !(category(obj.arrow) isa HomLike && category(category(obj.arrow)) == C)
        throw(NotInCategory(obj, K,
            @annotated """
            The arrow
            $TAB$(obj.arrow)
            is not a morphism of $C, so it cannot be the arrow of an object \
            of $K.
            """
        ))
    end

    # from `F(a)`
    if domain(category(obj.arrow)) != K.F(obj.source)
        throw(NotInCategory(obj, K,
            @annotated """
            The arrow
            $TAB$(obj.arrow)
            does not start at $(K.F(obj.source)), the image of the source \
            under $(K.F), so it cannot be the arrow of an object of $K.
            """
        ))
    end

    # to `G(b)`
    if codomain(category(obj.arrow)) != K.G(obj.target)
        throw(NotInCategory(obj, K,
            @annotated """
            The arrow
            $TAB$(obj.arrow)
            does not end at $(K.G(obj.target)), the image of the target \
            under $(K.G), so it cannot be the arrow of an object of $K.
            """
        ))
    end

    return true
end

checkInterface(::ObjComma, ::Comma) = true

function checkInCategory(obj, K::Comma)
    # only `ObjComma`s, which slices and coslices build from a morphism
    throw(NotInCategory(obj, K,
        @annotated """
        The value
        $TAB$(obj isa OIC ? obj : valclr(obj))
        is not an object of $K, whose objects are \
        $(codeclr("ObjComma(a, b, h)"))s. For a slice or coslice, you may \
        also pass the morphism $(codeclr("h")) itself.
        """
    ))
end

function checkInCategory(
    morph::MorphComma, H::HomLike{ObjComma, ObjComma, <:Comma}
)
    K = category(H)
    dom, cod = object(domain(H)), object(codomain(H))
    α, β = morph.sourceMorph, morph.targetMorph

    # only `Hom` and `Iso`
    if H isa Union{Epi, Mono}
        throw(NotInCategory(morph, H,
            @annotated """
            Morphisms of a comma category are only checked for being in \
            $(catclr("Hom")) or $(catclr("Iso")), so none can be shown to be \
            in $H.
            """
        ))
    end

    # `α: a → a′`
    if !(category(α) isa HomLike && domain(category(α)) == dom.source &&
            codomain(category(α)) == cod.source)
        throw(NotInCategory(morph, H,
            @annotated """
            The source morphism
            $TAB$α
            is not a morphism from $(dom.source) to $(cod.source), so it \
            cannot be the source morphism of a morphism in $H.
            """
        ))
    end

    # `β: b → b′`
    if !(category(β) isa HomLike && domain(category(β)) == dom.target &&
            codomain(category(β)) == cod.target)
        throw(NotInCategory(morph, H,
            @annotated """
            The target morphism
            $TAB$β
            is not a morphism from $(dom.target) to $(cod.target), so it \
            cannot be the target morphism of a morphism in $H.
            """
        ))
    end

    # isomorphisms componentwise, for `Iso`
    if H isa Iso && !(category(α) isa Iso && category(β) isa Iso)
        throw(NotInCategory(morph, H,
            @annotated """
            The morphism $(objclr(name(OIC(morph, H; force=true)))) is not in \
            $H, since its source and target morphisms are not both in an \
            $(catclr("Iso")).
            """
        ))
    end

    # commutativity can only be checked pointwise, over FinSet
    C = object(codomain(category(K.F)))
    if !(C isa CatFinSet)
        throw(NotInCategory(morph, H,
            @annotated """
            Whether a morphism of $K commutes can only be checked when its \
            functors land in $FinSet, but they land in $C. If you know it \
            commutes, you may skip the check with `force=true`.
            """
        ))
    end

    # `G(β) ∘ h == h′ ∘ F(α)`, pointwise
    Gβ, Fα = K.G(β), K.F(α)
    for x in domain(category(dom.arrow))
        lhs, rhs = Gβ(dom.arrow(x)), cod.arrow(Fα(x))
        if lhs != rhs
            throw(NotInCategory(morph, H,
                @annotated """
                The morphism $(objclr(name(OIC(morph, H; force=true)))) is \
                not in $H, since it does not commute: the element \
                $(objclr(name(x))) is sent to $(objclr(name(lhs))) by \
                $(codeclr("G(β) ∘ h")) but to $(objclr(name(rhs))) by \
                $(codeclr("h′ ∘ F(α)")).
                """
            ))
        end
    end

    return true
end

checkInterface(::MorphComma, ::HomLike{ObjComma, ObjComma, <:Comma}) = true

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    source(o)

The object `a` of an object `o = (a, b, h)` of a [`Comma`](@ref) category.
"""
source(o::OIC{ObjComma, <:Comma}) = object(o).source

"""
    target(o)

The object `b` of an object `o = (a, b, h)` of a [`Comma`](@ref) category.
"""
target(o::OIC{ObjComma, <:Comma}) = object(o).target

"""
    arrow(o)

The morphism `h` of an object `o = (a, b, h)` of a [`Comma`](@ref) category.
"""
arrow(o::OIC{ObjComma, <:Comma}) = object(o).arrow

function compose(
    n::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Comma}},
    m::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Comma}}
)
    M, N = category(m), category(n)

    # `m` lands where `n` starts
    if codomain(M) != domain(N)
        throw(ArgumentError(
            @annotated """
            The morphisms
            $TAB$n
            and
            $TAB$m
            cannot be composed, since the codomain of the second is not the \
            domain of the first.
            """
        ))
    end

    Kind = M isa Iso && N isa Iso ? Iso : Hom
    return Kind(domain(M), codomain(N))[
        MorphComma(
            compose(object(n).sourceMorph, object(m).sourceMorph),
            compose(object(n).targetMorph, object(m).targetMorph),
        ),
        force=true
    ]
end

function id(o::OIC{ObjComma, <:Comma})
    return Iso(o, o)[MorphComma(id(source(o)), id(target(o))), force=true]
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(K::Comma) = "($(name(K.F)) ↓ $(name(K.G)))"

function name(o::OIC{ObjComma, <:Comma})
    return "($(shortName(source(o))), $(shortName(target(o))), \
        $(shortName(arrow(o))))"
end

function name(m::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Comma}})
    return "($(shortName(object(m).sourceMorph)), \
        $(shortName(object(m).targetMorph)))"
end

function treeNode(K::Comma; withcat=true)
    return coloredPrint(K), ["F" => K.F, "G" => K.G]
end

# =========================================================
# ================== SLICES AND COSLICES ==================
# =========================================================

const Slice = Comma{<:OIC{FuncIdentity}, <:OIC{FuncConstant}}

const Coslice = Comma{<:OIC{FuncConstant}, <:OIC{FuncIdentity}}

"""
    Slice(X)

The slice category `C/X` over an object `X` of `C`, i.e. `id(Cat[C]) ↓ Δ(X)`.
Its objects are the morphisms `f: A → X`, written `Slice(X)[f]`, and its
morphisms from `f: A → X` to `g: B → X` are the morphisms `h: A → B` with
`g ∘ h == f`, written `Hom(Slice(X)[f], Slice(X)[g])[h]`. `Slice` is also the
type of every slice category, for dispatch.
"""
function Slice(X::OIC)
    C = Cat[category(X)]
    return id(C) ↓ Hom(Cat[Point], C)[FuncConstant(X)]
end

"""
    Coslice(X)

The coslice category `X/C` under an object `X` of `C`, i.e.
`Δ(X) ↓ id(Cat[C])`. Its objects are the morphisms `f: X → A`, written
`Coslice(X)[f]`, and its morphisms from `f: X → A` to `g: X → B` are the
morphisms `h: A → B` with `h ∘ f == g`, written
`Hom(Coslice(X)[f], Coslice(X)[g])[h]`. `Coslice` is also the type of every
coslice category, for dispatch.
"""
function Coslice(X::OIC)
    C = Cat[category(X)]
    return Hom(Cat[Point], C)[FuncConstant(X)] ↓ id(C)
end

function Base.getindex(K::Slice, f::OIC{<:Any, <:HomLike}; force::Bool=false)
    return K[ObjComma(domain(category(f)), Point[:pt], f), force=force]
end

function Base.getindex(K::Coslice, f::OIC{<:Any, <:HomLike}; force::Bool=false)
    return K[ObjComma(Point[:pt], codomain(category(f)), f), force=force]
end

function Base.getindex(
    H::HomLike{ObjComma, ObjComma, <:Slice}, h::OIC{<:Any, <:HomLike};
    force::Bool=false
)
    return H[MorphComma(h, id(Point[:pt])), force=force]
end

function Base.getindex(
    H::HomLike{ObjComma, ObjComma, <:Coslice}, h::OIC{<:Any, <:HomLike};
    force::Bool=false
)
    return H[MorphComma(id(Point[:pt]), h), force=force]
end

"""
    terminal(Slice(X))

The terminal object `id(X)` of the slice category over `X`. The unique
morphism into it from `f` is `canonicalHom(f, terminal(Slice(X)))`, which is
`f` itself.
"""
terminal(K::Slice) = K[id(object(K.G).value), force=true]

"""
    initial(Coslice(X))

The initial object `id(X)` of the coslice category under `X`. The unique
morphism out of it to `f` is `canonicalHom(initial(Coslice(X)), f)`, which is
`f` itself.
"""
initial(K::Coslice) = K[id(object(K.F).value), force=true]

function canonicalHom(
    o::OIC{ObjComma, <:Slice}, t::OIC{ObjComma, <:Slice}
)
    # into the terminal object of the same slice
    if category(o) != category(t) || t != terminal(category(t))
        throw(NoCanonicalHomError(o, t,
            @annotated """
            In a slice category, a canonical morphism is only defined into \
            its terminal object, but
            $TAB$t
            is not the terminal object $(terminal(category(o))).
            """
        ))
    end
    return Hom(o, t)[arrow(o), force=true]
end

function canonicalHom(
    i::OIC{ObjComma, <:Coslice}, o::OIC{ObjComma, <:Coslice}
)
    # out of the initial object of the same coslice
    if category(o) != category(i) || i != initial(category(i))
        throw(NoCanonicalHomError(i, o,
            @annotated """
            In a coslice category, a canonical morphism is only defined out \
            of its initial object, but
            $TAB$i
            is not the initial object $(initial(category(o))).
            """
        ))
    end
    return Hom(i, o)[arrow(o), force=true]
end

name(K::Slice) =
    "$(name(object(K.G).value |> category))/$(shortName(object(K.G).value))"

name(K::Coslice) =
    "$(shortName(object(K.F).value))/$(name(object(K.F).value |> category))"

name(o::OIC{ObjComma, <:Union{Slice, Coslice}}) =
    shortName(arrow(o))

name(m::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Slice}}) =
    shortName(object(m).sourceMorph)

name(m::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Coslice}}) =
    shortName(object(m).targetMorph)
