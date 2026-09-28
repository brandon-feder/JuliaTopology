"""
    FunctorCat(J, C)

The functor category `[J, C]` for a shape `J` (a category defining
[`vertices`](@ref) and [`generators`](@ref), e.g. a [`FreeCat`](@ref)) and a
category `C`.
Its objects are the diagrams of shape `J` in `C`, i.e. objects of
`Hom(Cat[J], Cat[C])` (see [`diagram`](@ref)), written `FunctorCat(J, C)[D]`.
Its morphisms are natural transformations, [`GenericMorphFunctorCat`](@ref)s.

# Standardized Interface
- `compose(θ, η)`, `id(D)`, `firstDifference(η, θ)` — componentwise

# Interface Specification Assumptions
- `D` is an object of `FunctorCat(J, C)`; `η, θ` are its morphisms
"""
struct FunctorCat{JT <: Category, CT <: Category} <: Category
    J::JT
    C::CT
end

"""
    GenericMorphFunctorCat(diagram)

A natural transformation `η: D₁ → D₂` between diagrams of shape `J` in `C`, a
morphism of [`FunctorCat`](@ref)`(J, C)`: a diagram of shape `J` in the arrow
category [`arrowCategory`](@ref)`(C)`, whose object at each vertex `j` is the
component `η_j: D₁(j) → D₂(j)` and whose morphism at each arrow `a` is the
square `(D₁(a), D₂(a))`. That this square commutes is exactly naturality.
Build one with `Hom(D₁, D₂)[(j = η_j, …)]`; [`components`](@ref) reads the
components back.
"""
struct GenericMorphFunctorCat
    diagram::OIC
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
    D₁, D₂ = object(domain(H)), object(codomain(H))
    E = η.diagram

    # a diagram of shape `J` in the arrow category of `C`
    if !(E isa OIC && category(E) == Hom(Cat[J], Cat[arrowCategory(C)]))
        throw(NotInCategory(η, H,
            @annotated """
            A natural transformation in $H is a diagram of shape $J in the \
            arrow category of $C, but
            $TAB$(E isa OIC ? E : valclr(E))
            is not one.
            """
        ))
    end

    # whose component at `j` goes from `D₁(j)` to `D₂(j)`
    for j in vertices(J)
        if !(source(E(j)) == D₁(j) && target(E(j)) == D₂(j))
            throw(NotInCategory(η, H,
                @annotated """
                The component at $(valclr(j))
                $TAB$(arrow(E(j)))
                is not a morphism from $(D₁(j)) to $(D₂(j)), so it cannot be \
                a component of a natural transformation in $H.
                """
            ))
        end
    end

    # and whose square at `a` is made of `D₁(a)` and `D₂(a)`
    for label in keys(generators(J))
        square = object(E(label))
        if !(square.sourceMorph == D₁(label) && square.targetMorph == D₂(label))
            throw(NotInCategory(η, H,
                @annotated """
                The square at the arrow $(valclr(label)) of the natural \
                transformation is not made of the morphisms of $(D₁) and \
                $(D₂) at $(valclr(label)).
                """
            ))
        end
    end

    return true
end


# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    H[components::NamedTuple, force=false]

The natural transformation with the given components, one per vertex, as a
morphism in `H = Hom(D₁, D₂)` of a [`FunctorCat`](@ref), e.g.
`Hom(D₁, D₂)[(X = η_X, Y = η_Y)]`.
"""
function Base.getindex(
    H::Hom{<:Any, <:Any, <:FunctorCat}, components::NamedTuple; force::Bool=false
)
    J, C = category(H).J, category(H).C
    D₁, D₂ = object(domain(H)), object(codomain(H))
    A = arrowCategory(C)

    # one component for each vertex
    if !force && Set(keys(components)) != Set(vertices(J))
        throw(NotInCategory(components, H,
            @annotated """
            A natural transformation in $H must have one component for each \
            of the vertices $(valclr(vertices(J))), but it has components for \
            $(valclr(keys(components))).
            """
        ))
    end

    # whose component at `j` goes from `D₁(j)` to `D₂(j)`
    for j in vertices(J)
        c = components[j]
        if !force && !(c isa OIC && category(c) isa Hom &&
                domain(category(c)) == D₁(j) && codomain(category(c)) == D₂(j))
            throw(NotInCategory(components, H,
                @annotated """
                The component at $(valclr(j))
                $TAB$(c isa OIC ? c : valclr(c))
                is not a morphism from $(D₁(j)) to $(D₂(j)), so it cannot be \
                a component of a natural transformation in $H.
                """
            ))
        end
    end

    # each component an object of the arrow category, and each naturality
    # square a morphism of it, which the comma category checks commutes
    objects = (; (j => A[(D₁(j), D₂(j), components[j]), force=force]
        for j in vertices(J))...)
    squares = (; (a => Hom(objects[s], objects[t])[(D₁(a), D₂(a)), force=force]
        for (a, (s, t)) in pairs(generators(J)))...)
    E = diagram(J, A; force=force, objects..., squares...)
    return H[GenericMorphFunctorCat(E), force=force]
end

"""
    components(η)

The components of a natural transformation `η`, a `NamedTuple` with one
morphism for each vertex of its shape.
"""
components(η::OIC{GenericMorphFunctorCat, <:Hom{<:Any, <:Any, <:FunctorCat}}) =
    map(arrow, object(object(η).diagram).objects)

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

function id(D::OIC{<:Any, <:FunctorCat})
    J = category(D).J
    return Hom(D, D)[(; (j => id(object(D)(j)) for j in vertices(J))...), force=true]
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
    for j in vertices(category(category(η)).J)
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
    return "(" * join(("$j: $(shortName(c))" for (j, c) in pairs(components(η))),
        ", ") * ")"
end
