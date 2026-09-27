const Cone = Comma{<:OIC{FuncDiagonal}, <:OIC{FuncConstant}}

const Cocone = Comma{<:OIC{FuncConstant}, <:OIC{FuncDiagonal}}

"""
    Cone(D)

The category of cones over a diagram `D` of shape `J` in `C`, i.e. the comma
category `Δ ↓ D` of the diagonal functor `Δ: C → [J, C]` and `D`, regarded as a
functor from [`Point`](@ref). A cone is an apex `X` with a leg `X → D(j)` for
each vertex `j`, commuting with the arrows of `D`, written
`Cone(D)[(A = legA, B = legB, …)]`, or `Cone(D)[X, legs]` for an empty
diagram. A morphism of cones is a morphism `u` between their apexes
commuting with the legs, written `Hom(c₁, c₂)[u]`. A limit of `D` is a
terminal object of `Cone(D)`, see [`limit`](@ref). `Cone` is also the type of
every cone category, for dispatch.

# Standardized Interface
- `apex(c)`, `legs(c)`, `leg(c, :A)` — the apex and legs of a cone `c`
"""
function Cone(D::OIC{FuncDiagram, <:Hom{FreeCat, <:Any, CatCat}})
    J, C = object(domain(category(D))), object(codomain(category(D)))
    K = FunctorCat(J, C)
    return diagonal(J, C) ↓ Hom(Cat[Point], Cat[K])[FuncConstant(K[D, force=true])]
end

"""
    Cocone(D)

The category of cocones under a diagram `D` of shape `J` in `C`, i.e. the
comma category `D ↓ Δ`. A cocone is an apex `X` with a leg `D(j) → X` for each
vertex `j`, commuting with the arrows of `D`, written
`Cocone(D)[(A = legA, B = legB, …)]`, or `Cocone(D)[X, legs]` for an empty
diagram. A morphism of cocones is a morphism `u` between their apexes
commuting with the legs, written `Hom(c₁, c₂)[u]`. A colimit of `D` is an
initial object of `Cocone(D)`, see [`colimit`](@ref). `Cocone` is also the
type of every cocone category, for dispatch.

# Standardized Interface
- `apex(c)`, `legs(c)`, `leg(c, :A)` — the apex and legs of a cocone `c`
"""
function Cocone(D::OIC{FuncDiagram, <:Hom{FreeCat, <:Any, CatCat}})
    J, C = object(domain(category(D))), object(codomain(category(D)))
    K = FunctorCat(J, C)
    return Hom(Cat[Point], Cat[K])[FuncConstant(K[D, force=true])] ↓ diagonal(J, C)
end

# =========================================================
# ======================= SHORTHAND =======================
# =========================================================

function Base.getindex(K::Cone, X::OIC, legs::NamedTuple; force::Bool=false)
    Δ, D = K.F, object(K.G).value
    λ = Hom(Δ(X), D)[MorphNat(legs), force=force]
    return K[ObjComma(X, Point[:pt], λ), force=force]
end

function Base.getindex(K::Cocone, X::OIC, legs::NamedTuple; force::Bool=false)
    Δ, D = K.G, object(K.F).value
    λ = Hom(D, Δ(X))[MorphNat(legs), force=force]
    return K[ObjComma(Point[:pt], X, λ), force=force]
end

function Base.getindex(K::Union{Cone, Cocone}, legs::NamedTuple; force::Bool=false)
    # the apex is read off a leg
    if isempty(legs)
        throw(ArgumentError(
            @annotated """
            A cone or cocone over an empty diagram has no legs to read its \
            apex off, so it must be given explicitly, as \
            $(codeclr("K[X, NamedTuple()]")).
            """
        ))
    end
    leg₁ = first(legs)
    X = K isa Cone ? domain(category(leg₁)) : codomain(category(leg₁))
    return K[X, legs, force=force]
end

function Base.getindex(
    H::HomLike{ObjComma, ObjComma, <:Cone}, u::OIC{<:Any, <:HomLike};
    force::Bool=false
)
    return H[MorphComma(u, id(Point[:pt])), force=force]
end

function Base.getindex(
    H::HomLike{ObjComma, ObjComma, <:Cocone}, u::OIC{<:Any, <:HomLike};
    force::Bool=false
)
    return H[MorphComma(id(Point[:pt]), u), force=force]
end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    apex(c)

The apex of a cone or cocone `c`.
"""
apex(c::OIC{ObjComma, <:Cone}) = source(c)
apex(c::OIC{ObjComma, <:Cocone}) = target(c)

"""
    legs(c)

The legs of a cone or cocone `c`, a `NamedTuple` with one morphism for each
vertex of its diagram.
"""
legs(c::OIC{ObjComma, <:Union{Cone, Cocone}}) = object(arrow(c)).components

"""
    leg(c, j::Symbol)

The leg of a cone or cocone `c` at the vertex `j` of its diagram.
"""
leg(c::OIC{ObjComma, <:Union{Cone, Cocone}}, j::Symbol) = legs(c)[j]

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(K::Cone) = "Cone($(name(object(K.G).value)))"

name(K::Cocone) = "Cocone($(name(object(K.F).value)))"

name(c::OIC{ObjComma, <:Union{Cone, Cocone}}) = shortName(apex(c))

name(m::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Cone}}) =
    shortName(object(m).sourceMorph)

name(m::OIC{MorphComma, <:HomLike{ObjComma, ObjComma, <:Cocone}}) =
    shortName(object(m).targetMorph)
