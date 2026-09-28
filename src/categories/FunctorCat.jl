"""
    FunctorCat(J, C)

The functor category `[J, C]` for any categories `J` and `C`. Its objects are
the functors from `J` to `C`, i.e. objects of `Hom(Cat[J], Cat[C])`, written
`FunctorCat(J, C)[F]`. Its morphisms are natural transformations: for a shape
`J` (a category defining [`nvertices`](@ref) and [`generators`](@ref), e.g. a
[`FreeCat`](@ref)), [`GenericMorphFunctorCat`](@ref)s, and otherwise any type
defined for them, trusted with `force=true`.

# Standardized Interface
- `compose(θ, η)`, `id(F)`, `firstDifference(η, θ)` — componentwise

# Interface Specification Assumptions
- `F` is an object of `FunctorCat(J, C)`; `η, θ` are its morphisms
"""
struct FunctorCat{JT <: Category, CT <: Category} <: Category
    J::JT
    C::CT
end

"""
    GenericMorphFunctorCat(components)

A natural transformation `η: F → G` between functors out of a shape `J`, a
morphism of [`FunctorCat`](@ref)`(J, C)`: a tuple with its component
`η_j: F(j) → G(j)` at each vertex `j`. Build one with
`Hom(F, G)[(η₁, η₂, …)]`; [`components`](@ref) reads the components back.

Checking one needs the [`diagram`](@ref)s of `F` and `G`, which diagrams and
functors out of a [`FreeCat`](@ref) have: the components, with the squares of
the morphisms of `F` and `G` at each arrow, then form a diagram of shape `J` in
the arrow category [`arrowCategory`](@ref)`(C)`, and that this is a diagram,
i.e. that its squares commute, is exactly naturality. Between other functors,
pass `force=true` to trust it.
"""
struct GenericMorphFunctorCat
    components::Tuple
end

"""
    arrowCategory(C)

The arrow category of `C`, the comma category `id(Cat[C]) ↓ id(Cat[C])`: its
objects are the morphisms of `C`, and its morphisms are commuting squares.
"""
arrowCategory(C::Category) = id(Cat[C]) ↓ id(Cat[C])

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj, K::FunctorCat)
    # a functor from `J` to `C`
    if !(obj isa OIC && category(obj) isa Hom{<:Any, <:Any, CatCat} &&
            object(domain(category(obj))) == K.J &&
            object(codomain(category(obj))) == K.C)
        throw(NotInCategory(obj, K,
            @annotated """
            The value
            $TAB$(obj isa OIC ? obj : valclr(obj))
            is not an object of $K, whose objects are functors from \
            $(K.J) to $(K.C), e.g. built by $(codeclr("diagram")).
            """
        ))
    end
    return true
end


function checkInCategory(η::GenericMorphFunctorCat, H::Hom{<:Any, <:Any, <:FunctorCat})
    J, C = category(H).J, category(H).C
    F, G = object(domain(H)), object(codomain(H))
    A = arrowCategory(C)

    # one component for each vertex
    if length(η.components) != nvertices(J)
        throw(NotInCategory(η, H,
            @annotated """
            A natural transformation in $H must have one component for each \
            of its $(valclr(nvertices(J))) vertices, but it has \
            $(valclr(length(η.components))).
            """
        ))
    end

    # between functors whose objects and morphisms can be listed
    for functor in (F, G)
        if !hasNonFallbackMethod(Tuple{typeof(diagram), typeof(functor)})
            throw(NotInCategory(η, H,
                @annotated """
                Whether a natural transformation in $H is natural can only be \
                checked when its functors are diagrams or can be turned into \
                one (with $(codeclr("diagram"))), which
                $TAB$functor
                cannot. If you know it is natural, you may skip the check \
                with `force=true`.
                """
            ))
        end
    end
    D₁, D₂ = diagram(F), diagram(G)

    # whose component at `j` goes from `D₁(j)` to `D₂(j)`
    for (j, c) in enumerate(η.components)
        X₁, X₂ = objects(D₁)[j], objects(D₂)[j]
        if !(c isa OIC && category(c) isa Hom &&
                domain(category(c)) == X₁ && codomain(category(c)) == X₂)
            throw(NotInCategory(η, H,
                @annotated """
                The component at the vertex $(valclr(j))
                $TAB$(c isa OIC ? c : valclr(c))
                is not a morphism from $X₁ to $X₂, so it cannot be a \
                component of a natural transformation in $H.
                """
            ))
        end
    end

    # and with the squares of `D₁` and `D₂` at each arrow, a diagram in the
    # arrow category, whose comma category checks that the squares commute
    corners = map((X₁, X₂, c) -> A[(X₁, X₂, c)], objects(D₁), objects(D₂), η.components)
    squares = map((k, (s, t)) -> Hom(corners[s], corners[t])[
        (arrows(D₁)[k], arrows(D₂)[k])], Tuple(eachindex(generators(J))), generators(J))
    diagram(J, A, corners, squares)

    return true
end


# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    H[components::Tuple, force=false]

The natural transformation with the given components, one per vertex, as a
morphism in `H = Hom(F, G)` of a [`FunctorCat`](@ref), i.e.
`H[GenericMorphFunctorCat(components)]`, e.g. `Hom(F, G)[(η₁, η₂)]`.
"""
function Base.getindex(
    H::Hom{<:Any, <:Any, <:FunctorCat}, components::Tuple; force::Bool=false
)
    return H[GenericMorphFunctorCat(components), force=force]
end

"""
    components(η)

The components of a natural transformation `η`, a tuple with one morphism for
each vertex of its shape.
"""
components(η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}) =
    object(η).components

function compose(
    θ::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}},
    η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}
)
    E, T = category(η), category(θ)

    # `η` ends where `θ` starts
    if codomain(E) != domain(T)
        throw(ArgumentError(
            @annotated """
            The natural transformations
            $TAB$θ
            and
            $TAB$η
            cannot be composed, since the codomain of the second is not the \
            domain of the first.
            """
        ))
    end

    return Hom(domain(E), codomain(T))[
        map(compose, components(θ), components(η)), force=true]
end

# the identity at each vertex, which needs the objects of the diagram of `F`
function id(F::OIC{<:Any, <:FunctorCat})
    return Hom(F, F)[map(id, objects(diagram(object(F)))), force=true]
end

"""
    isMono(η), isEpi(η), isIso(η)

Whether every component of the natural transformation `η` is a monomorphism,
epimorphism or isomorphism. For diagrams of sets, this is exactly whether `η`
itself is one.
"""
isMono(η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}) =
    all(isMono, components(η))
isEpi(η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}) =
    all(isEpi, components(η))
isIso(η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}) =
    all(isIso, components(η))

"""
    inv(η; force=false)

The inverse of a natural isomorphism `η`, whose components are the inverses of
those of `η`. Throws an `ArgumentError` unless every component is an
isomorphism; `force=true` skips this check.
"""
function Base.inv(
    η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}; force::Bool=false
)
    # an isomorphism in each component
    if !force && !isIso(η)
        throw(ArgumentError(
            @annotated """
            The natural transformation
            $TAB$η
            has no inverse, since not all of its components are isomorphisms.
            """
        ))
    end
    H = category(η)
    return Hom(codomain(H), domain(H))[map(c -> inv(c; force=true), components(η)), force=true]
end

"""
    firstDifference(η, θ)

For natural transformations `η, θ: D₁ → D₂`, `nothing` when every component
agrees, and otherwise `(path = (j, x), left, right)` for the first vertex `j`
whose components differ, at `x`.
"""
function firstDifference(
    η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}},
    θ::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}
)
    for j in eachindex(components(η))
        difference = firstDifference(components(η)[j], components(θ)[j])
        if difference !== nothing
            return (path = (j, difference.path...), left = difference.left,
                right = difference.right)
        end
    end
    return nothing
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(K::FunctorCat) = "[$(name(K.J)), $(name(K.C))]"

name(D::OIC{<:Any, <:FunctorCat}) = name(object(D))

function name(η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}})
    return "(" * join(map(shortName, components(η)), ", ") * ")"
end
