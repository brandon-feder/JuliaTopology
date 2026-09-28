# =========================================================
# =================== IDENTITY FUNCTORS ===================
# =========================================================

"""
    struct FuncIdentity end

The identity functor of a category `C`, an object of `Hom(Cat[C], Cat[C])`
sending every object and morphism of `C` to itself. `id(Cat[C])` builds it.
"""
struct FuncIdentity end

function checkInCategory(obj::FuncIdentity, H::Hom{<:Any, <:Any, CatCat})
    # from a category to itself
    if domain(H) != codomain(H)
        throw(NotInCategory(obj, H,
            @annotated """
            An identity functor is not a morphism in $H, since its domain \
            and codomain are different categories.
            """
        ))
    end
    return true
end


id(X::OIC{<:Category, CatCat}) = Hom(X, X)[FuncIdentity(), force=true]

function (::OIC{FuncIdentity, <:Hom{CatT, CatT, CatCat}})(
    obj::OIC{<:Any, CatT}
) where CatT
    return obj
end

function (::OIC{FuncIdentity, <:Hom{CatT, CatT, CatCat}})(
    morph::OIC{<:Any, <:Hom{<:Any, <:Any, CatT}}
) where CatT
    return morph
end

name(::OIC{FuncIdentity, <:Hom{<:Any, <:Any, CatCat}}) = "Id"

# =========================================================
# =================== COMPOSITE FUNCTORS ==================
# =========================================================

"""
    FuncCompose(G, F)

The composite `G ∘ F` of functors `F: A → B` and `G: B → C`, an object of
`Hom(Cat[A], Cat[C])` sending each object and morphism `x` of `A` to
`G(F(x))`. Build it with `compose(G, F)` or `G ∘ F`.
"""
struct FuncCompose
    outer::OIC
    inner::OIC
end

function checkInCategory(F::FuncCompose, H::Hom{<:Any, <:Any, CatCat})
    # `inner` from the domain of `H`, `outer` to its codomain, meeting between
    if !(domain(category(F.inner)) == domain(H) &&
            codomain(category(F.outer)) == codomain(H) &&
            codomain(category(F.inner)) == domain(category(F.outer)))
        throw(NotInCategory(F, H,
            @annotated """
            The composite of
            $TAB$(F.outer)
            and
            $TAB$(F.inner)
            is not a functor in $H, since they do not go from \
            $(object(domain(H))) through one category to \
            $(object(codomain(H))).
            """
        ))
    end
    return true
end

function (F::OIC{FuncCompose, <:Hom{DomT, <:Any, CatCat}})(x::OIC{<:Any, DomT}) where DomT
    return object(F).outer(object(F).inner(x))
end

function (F::OIC{FuncCompose, <:Hom{DomT, <:Any, CatCat}})(
    m::OIC{<:Any, <:Hom{<:Any, <:Any, DomT}}
) where DomT
    return object(F).outer(object(F).inner(m))
end

name(F::OIC{FuncCompose, <:Hom{<:Any, <:Any, CatCat}}) =
    "$(shortName(object(F).outer)) ∘ $(shortName(object(F).inner))"

"""
    compose(G, F)
    G ∘ F

The composite of functors `F: A → B` and `G: B → C`, applying `F` first. An
identity functor drops out, and a diagram followed by a functor is again a
diagram, of the same shape (its pushforward); otherwise the composite is a
[`FuncCompose`](@ref).
"""
function compose(
    G::OIC{<:Any, <:Hom{<:Any, <:Any, CatCat}}, F::OIC{<:Any, <:Hom{<:Any, <:Any, CatCat}}
)
    # `F` lands where `G` starts
    if codomain(category(F)) != domain(category(G))
        throw(ArgumentError(
            @annotated """
            The functors
            $TAB$G
            and
            $TAB$F
            cannot be composed, since the second lands in \
            $(object(codomain(category(F)))) but the first starts at \
            $(object(domain(category(G)))).
            """
        ))
    end

    object(F) isa FuncIdentity && return G
    object(G) isa FuncIdentity && return F
    if object(F) isa FuncDiagram
        J, C = shape(F), object(codomain(category(G)))
        return diagram(J, C, map(G, objects(F)), map(G, arrows(F)); force=true)
    end
    return Hom(domain(category(F)), codomain(category(G)))[FuncCompose(G, F), force=true]
end

