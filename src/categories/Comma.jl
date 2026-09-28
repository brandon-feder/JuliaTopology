"""
    Comma(F, G)
    F ↓ G

The comma category `(F ↓ G)` of functors `F: A → C` and `G: B → C`, i.e.
objects of `Hom(Cat[A], Cat[C])` and `Hom(Cat[B], Cat[C])`.

Its objects are [`GenericComma`](@ref)s `(a, b, h)`, with `a` an object of `A`,
`b` one of `B`, and `h: F(a) → G(b)` a morphism of `C`. Its morphisms
`(a, b, h) → (a′, b′, h′)` are [`GenericMorphComma`](@ref)s `(α, β)`, with `α: a → a′`
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
            if !(H isa OIC && category(H) isa Hom{<:Any, <:Any, CatCat})
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
    GenericComma(source, target, arrow)

An object `(a, b, h)` of a [`Comma`](@ref) category `(F ↓ G)`: an object `a`
of the domain of `F`, an object `b` of the domain of `G`, and a morphism
`h: F(a) → G(b)`.
"""
struct GenericComma
    source::OIC
    target::OIC
    arrow::OIC
end

"""
    GenericMorphComma(sourceMorph, targetMorph)

A morphism `(α, β)` of a [`Comma`](@ref) category `(F ↓ G)`, from `(a, b, h)`
to `(a′, b′, h′)`: morphisms `α: a → a′` and `β: b → b′` such that
`G(β) ∘ h == h′ ∘ F(α)`.
"""
struct GenericMorphComma
    sourceMorph::OIC
    targetMorph::OIC
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj::GenericComma, K::Comma)
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
    if !(category(obj.arrow) isa Hom && category(category(obj.arrow)) == C)
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


function checkInCategory(obj, K::Comma)
    # only `GenericComma`s, which slices and coslices build from a morphism
    throw(NotInCategory(obj, K,
        @annotated """
        The value
        $TAB$(obj isa OIC ? obj : valclr(obj))
        is not an object of $K, whose objects are \
        $(codeclr("GenericComma(a, b, h)"))s. For a slice or coslice, you may \
        also pass the morphism $(codeclr("h")) itself.
        """
    ))
end

function checkInCategory(
    morph::GenericMorphComma, H::Hom{GenericComma, GenericComma, <:Comma}
)
    K = category(H)
    dom, cod = object(domain(H)), object(codomain(H))
    α, β = morph.sourceMorph, morph.targetMorph

    # `α: a → a′`
    if !(category(α) isa Hom && domain(category(α)) == dom.source &&
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
    if !(category(β) isa Hom && domain(category(β)) == dom.target &&
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

    # commutativity can only be checked when the morphisms of `C` can be
    # composed and compared
    C = object(codomain(category(K.F)))
    Gβ, Fα = K.G(β), K.F(α)
    comparable =
        hasNonFallbackMethod(Tuple{typeof(compose), typeof(Gβ), typeof(dom.arrow)}) &&
        hasNonFallbackMethod(Tuple{typeof(compose), typeof(cod.arrow), typeof(Fα)})
    if comparable
        lhs, rhs = compose(Gβ, dom.arrow), compose(cod.arrow, Fα)
        comparable = hasNonFallbackMethod(
            Tuple{typeof(firstDifference), typeof(lhs), typeof(rhs)})
    end
    if !comparable
        throw(NotInCategory(morph, H,
            @annotated """
            Whether a morphism of $K commutes can only be checked when the \
            morphisms of $C can be composed and compared (with \
            $(codeclr("compose")) and $(codeclr("firstDifference"))), \
            which they cannot. If you know it commutes, you may skip the \
            check with `force=true`.
            """
        ))
    end

    # `G(β) ∘ h == h′ ∘ F(α)`
    difference = firstDifference(lhs, rhs)
    if difference !== nothing
        throw(NotInCategory(morph, H,
            @annotated """
            The morphism $(objclr(name(OIC(morph, H; force=true)))) is not \
            in $H, since it does not commute: the element \
            $(objclr(name(last(difference.path))))$(length(difference.path) > 1 ?
                @annotated(" of $(join(valclr.(difference.path[1:end-1]), " of "))") :
                "") is sent to \
            $(objclr(name(difference.left))) by $(codeclr("G(β) ∘ h")) but \
            to $(objclr(name(difference.right))) by $(codeclr("h′ ∘ F(α)")).
            """
        ))
    end

    return true
end


# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    K[(a, b, h), force=false]

The object `(a, b, h)` of a [`Comma`](@ref) category `K`, i.e.
`K[GenericComma(a, b, h)]`.
"""
function Base.getindex(K::Comma, (a, b, h)::Tuple{OIC, OIC, OIC}; force::Bool=false)
    return K[GenericComma(a, b, h), force=force]
end

"""
    H[(α, β), force=false]

The morphism `(α, β)` of a [`Comma`](@ref) category, in `H = Hom(o, o′)`, i.e.
`H[GenericMorphComma(α, β)]`.
"""
function Base.getindex(
    H::Hom{GenericComma, GenericComma, <:Comma}, (α, β)::Tuple{OIC, OIC};
    force::Bool=false
)
    return H[GenericMorphComma(α, β), force=force]
end

"""
    source(o)

The object `a` of an object `o = (a, b, h)` of a [`Comma`](@ref) category.
"""
source(o::OIC{GenericComma, <:Comma}) = object(o).source

"""
    target(o)

The object `b` of an object `o = (a, b, h)` of a [`Comma`](@ref) category.
"""
target(o::OIC{GenericComma, <:Comma}) = object(o).target

"""
    arrow(o)

The morphism `h` of an object `o = (a, b, h)` of a [`Comma`](@ref) category.
"""
arrow(o::OIC{GenericComma, <:Comma}) = object(o).arrow

function compose(
    n::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Comma}},
    m::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Comma}}
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

    return Hom(domain(M), codomain(N))[
        GenericMorphComma(
            compose(object(n).sourceMorph, object(m).sourceMorph),
            compose(object(n).targetMorph, object(m).targetMorph),
        ),
        force=true
    ]
end

"""
    isIso(m)

Whether the morphism `m = (α, β)` of a comma category is an isomorphism, i.e.
both `α` and `β` are.
"""
function isIso(m::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Comma}})
    return isIso(object(m).sourceMorph) && isIso(object(m).targetMorph)
end

"""
    inv(m; force=false)

The inverse `(α⁻¹, β⁻¹)` of an isomorphism `m = (α, β)` of a comma category.
Throws an `ArgumentError` unless `m` is an isomorphism; `force=true` skips this
check.
"""
function Base.inv(
    m::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Comma}};
    force::Bool=false
)
    # an isomorphism in both components
    if !force && !isIso(m)
        throw(ArgumentError(
            @annotated """
            The morphism
            $TAB$m
            has no inverse, since its components are not both isomorphisms.
            """
        ))
    end
    H = category(m)
    α, β = object(m).sourceMorph, object(m).targetMorph
    return Hom(codomain(H), domain(H))[
        (inv(α; force=true), inv(β; force=true)), force=true
    ]
end

function id(o::OIC{GenericComma, <:Comma})
    return Hom(o, o)[GenericMorphComma(id(source(o)), id(target(o))), force=true]
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(K::Comma) = "($(name(K.F)) ↓ $(name(K.G)))"

function name(o::OIC{GenericComma, <:Comma})
    return "($(shortName(source(o))), $(shortName(target(o))), \
        $(shortName(arrow(o))))"
end

function name(m::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Comma}})
    return "($(shortName(object(m).sourceMorph)), \
        $(shortName(object(m).targetMorph)))"
end

function treeNode(K::Comma; withcat=true)
    return coloredPrint(K), ["F" => K.F, "G" => K.G]
end
