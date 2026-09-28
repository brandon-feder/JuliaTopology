# =========================================================
# ======================== LIMITS =========================
# =========================================================

"""
    ConeIn{C}

The categories of cones over diagrams landing in categories of type `C`, for
dispatch, e.g. `terminal(K::ConeIn{CatFinCard})` to compute the limits of
diagrams of finite cardinals.
"""
const ConeIn{C} = Comma{<:OIC{FuncDiagonal, <:Hom{C}}, <:OIC{FuncDiagram}}

"""
    terminal(K)

A terminal object of the category `K`: for a category of cones, a limit; for
a category of cocones (the opposite of one of cones), a colimit; for a slice,
the identity, up to isomorphism. Terminal objects of comma categories are
universal arrows, so this is the one universal construction the others are
built from. Each category whose limits can be computed defines it for its
cones, e.g. `terminal(K::ConeIn{SomeCategory})`.
"""
function terminal(K::Cone)
    throw(InterfaceViolation(
        @annotated """
        A terminal object of $K, i.e. a limit, is not computed for diagrams \
        in $(object(domain(category(K.F)))). When appropriate, you may \
        compute it by overloading
        $(overloadHint("terminal", ("K", @annotated("the category of cones $K"),
            typeString(typeof(K)))))
        """
    ))
end

"""
    terminal(C::Category)

A terminal object of `C`, the apex of the limit of the empty diagram in `C`.
`canonicalHom(X, T)` is the unique morphism into it.
"""
terminal(C::Category) = apex(limit(diagram(emptyShape(), C)))

"""
    universalArrow(K)

The universal arrow of a comma category `K`, i.e. its terminal object, see
[`terminal`](@ref).
"""
universalArrow(K::Comma) = terminal(K)

"""
    limit(D)

The limit of a diagram `D`, a terminal object of [`Cone`](@ref)`(D)`, i.e.
`terminal(Cone(D))`: the universal cone over `D`, through which every other
cone factors uniquely, by `canonicalHom(c, limit(D))`.
"""
limit(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = terminal(Cone(D))

"""
    product(X₁, X₂, …)

The product of objects of one category, the [`limit`](@ref) of
[`discrete`](@ref)`(…)`.
"""
product(Xs::OIC...) = limit(discrete(Xs...))

"""
    A × B

The product of objects `A` and `B`, the apex of [`product`](@ref)`(A, B)`.
"""
×(A::OIC, B::OIC) = apex(product(A, B))

"""
    equalizer(f, g)

The equalizer of morphisms `f, g: X → Y`, the [`limit`](@ref) of
[`parallelPair`](@ref)`(f, g)`.
"""
equalizer(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom}) = limit(parallelPair(f, g))

"""
    pullback(f, g)

The pullback of morphisms `f: A → C` and `g: B → C`, the [`limit`](@ref) of
[`cospan`](@ref)`(f, g)`.
"""
pullback(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom}) = limit(cospan(f, g))

# =========================================================
# ======================= COLIMITS ========================
# =========================================================

"""
    colimit(D)

The colimit of a diagram `D`, an initial object of [`Cocone`](@ref)`(D)`,
i.e. `initial(Cocone(D))`: the universal cocone under `D`, through which every
other cocone factors uniquely, by `canonicalHom(colimit(D), c)`. Since a
cocone is a cone in the opposite category, this is `op` of the terminal cone
over `op(D)`, so a category computes its colimits by defining `terminal` for
cones over diagrams in its opposite.
"""
colimit(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = initial(Cocone(D))

"""
    initial(C::Category)

An initial object of `C`, the apex of the colimit of the empty diagram in `C`.
`canonicalHom(I, X)` is the unique morphism out of it.
"""
initial(C::Category) = apex(colimit(diagram(emptyShape(), C)))

"""
    coproduct(X₁, X₂, …)

The coproduct of objects of one category, the [`colimit`](@ref) of
[`discrete`](@ref)`(…)`.
"""
coproduct(Xs::OIC...) = colimit(discrete(Xs...))

"""
    A ⊔ B

The coproduct of objects `A` and `B`, the apex of [`coproduct`](@ref)`(A, B)`.
"""
⊔(A::OIC, B::OIC) = apex(coproduct(A, B))

"""
    coequalizer(f, g)

The coequalizer of morphisms `f, g: X → Y`, the [`colimit`](@ref) of
[`parallelPair`](@ref)`(f, g)`.
"""
coequalizer(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom}) = colimit(parallelPair(f, g))

"""
    pushout(f, g)

The pushout of morphisms `f: C → A` and `g: C → B`, the [`colimit`](@ref) of
[`span`](@ref)`(f, g)`.
"""
pushout(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom}) = colimit(span(f, g))
