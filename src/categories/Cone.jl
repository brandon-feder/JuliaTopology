const Cone = Comma{<:OIC{FuncDiagonal}, <:OIC{FuncDiagram}}

const Cocone = Op{<:Cone}

"""
    Cone(D)

The category of cones over a diagram `D` of shape `J` in `C`, i.e. the comma
category `Δ ↓ D` of the diagonal functor `Δ: C → [J, C]` and `D`, regarded as a
functor from [`Point`](@ref) by [`constant`](@ref). A cone is an apex `X` with a leg `X → D(j)` for
each vertex `j`, commuting with the arrows of `D`, written
`Cone(D)[ℓ₁, ℓ₂, …]`, or `Cone(D)[X, (ℓ₁, ℓ₂, …)]` to give the apex
explicitly, as an empty diagram needs. A morphism of cones is a morphism `u` between their apexes
commuting with the legs, written `Hom(c₁, c₂)[u]`. A limit of `D` is a
terminal object of `Cone(D)`, see [`limit`](@ref). `Cone` is also the type of
every cone category, for dispatch.

# Standardized Interface
- `apex(c)`, `legs(c)`, `leg(c, j)` — the apex and legs of a cone `c`
"""
function Cone(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})
    J, C = shape(D), object(codomain(category(D)))
    K = FunctorCat(J, C)
    return diagonal(J, C) ↓ constant(K[D, force=true])
end

"""
    Cocone(D)

The category of cocones under a diagram `D` of shape `J` in `C`: the opposite
of the category of cones over `op(D)`, i.e. `Op(Cone(op(D)))`, since a cocone
is exactly a cone in the opposite category. Everything about cocones follows
by duality; they are built and read with the morphisms of `C` themselves,
which are converted with [`op`](@ref) as needed. A cocone is an apex `X` with a
leg `D(j) → X` for each
vertex `j`, commuting with the arrows of `D`, written
`Cocone(D)[ℓ₁, ℓ₂, …]`, or `Cocone(D)[X, (ℓ₁, ℓ₂, …)]` to give the apex
explicitly, as an empty diagram needs. A morphism of cocones is a morphism `u` between their apexes
commuting with the legs, written `Hom(c₁, c₂)[u]`. A colimit of `D` is an
initial object of `Cocone(D)`, see [`colimit`](@ref). `Cocone` is also the
type of every cocone category, for dispatch.

# Standardized Interface
- `apex(c)`, `legs(c)`, `leg(c, j)` — the apex and legs of a cocone `c`
"""
Cocone(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = op(Cone(op(D)))

"""
    diagram(K)

The diagram `D` of the category of cones `K = Cone(D)`, or of cocones
`K = Cocone(D)`.
"""
diagram(K::Cone) = object(only(objects(K.G)))
diagram(K::Cocone) = op(diagram(op(K)))

# =========================================================
# ======================= SHORTHAND =======================
# =========================================================

function Base.getindex(K::Cone, X::OIC, legs::Tuple; force::Bool=false)
    Δ = K.F
    λ = Hom(Δ(X), category(Δ(X))[diagram(K), force=true])[legs, force=force]
    return K[GenericComma(X, Point[1], λ), force=force]
end

# a cocone is the opposite of a cone over the opposite diagram
function Base.getindex(K::Cocone, X::OIC, legs::Tuple; force::Bool=false)
    D = diagram(K)

    # each leg goes from the object of its vertex to the apex, checked here so
    # that the message speaks of cocones rather than of opposite cones
    for (j, ℓ) in enumerate(legs)
        if !force && j <= length(objects(D)) && !(ℓ isa OIC &&
                category(ℓ) isa Hom && domain(category(ℓ)) == objects(D)[j] &&
                codomain(category(ℓ)) == X)
            throw(NotInCategory(ℓ, K,
                @annotated """
                The leg at the vertex $(valclr(j))
                $TAB$(ℓ isa OIC ? ℓ : valclr(ℓ))
                is not a morphism from $(objects(D)[j]) to the apex $X, so it \
                cannot be a leg of a cocone in $K.
                """
            ))
        end
    end

    return op(op(K)[op(X), map(op, legs), force=force])
end

# the apex is read off the first leg
function Base.getindex(
    K::Union{Cone, Cocone}, leg₁::OIC{<:Any, <:Hom}, legs::OIC{<:Any, <:Hom}...;
    force::Bool=false
)
    X = K isa Cone ? domain(category(leg₁)) : codomain(category(leg₁))
    return K[X, (leg₁, legs...), force=force]
end

function Base.getindex(
    H::Hom{GenericComma, GenericComma, <:Cone}, u::OIC{<:Any, <:Hom};
    force::Bool=false
)
    return H[GenericMorphComma(u, id(Point[1])), force=force]
end

function Base.getindex(
    H::Hom{GenericComma, GenericComma, <:Cocone}, u::OIC{<:Any, <:Hom};
    force::Bool=false
)
    return op(Hom(op(codomain(H)), op(domain(H)))[op(u), force=force])
end

"""
    mapCone(F, c)

The image of a cone or cocone `c` over a diagram `D` under a functor `F`, a
cone or cocone over `F ∘ D`: its apex is `F(apex(c))`, and its legs are the
images of those of `c`.
"""
function mapCone(F::OIC{<:Any, <:Hom{<:Any, <:Any, CatCat}}, c::OIC{GenericComma, <:Union{Cone, Cocone}})
    K = category(c)
    image = (K isa Cone ? Cone : Cocone)(F ∘ diagram(K))
    return image[F(apex(c)), map(F, legs(c))]
end

"""
    Slice(X)

The slice category `C/X` over an object `X` of `C`: the cones over the
one-object diagram [`constant`](@ref)`(X)`. Its objects are the morphisms
`f: A → X`, written `Slice(X)[f]`, and its morphisms from `f: A → X` to
`g: B → X` are the morphisms `h: A → B` with `g ∘ h == f`, written
`Hom(Slice(X)[f], Slice(X)[g])[h]`. Its terminal object is `id(X)`, up to
isomorphism: `terminal(Slice(X))`.
"""
Slice(X::OIC) = Cone(constant(X))

"""
    Coslice(X)

The coslice category `X/C` under an object `X` of `C`: the cocones under the
one-object diagram [`constant`](@ref)`(X)`. Its objects are the morphisms
`f: X → A`, written `Coslice(X)[f]`, and its morphisms from `f: X → A` to
`g: X → B` are the morphisms `h: A → B` with `h ∘ f == g`, written
`Hom(Coslice(X)[f], Coslice(X)[g])[h]`. Its initial object is `id(X)`, up to
isomorphism: `initial(Coslice(X))`.
"""
Coslice(X::OIC) = Cocone(constant(X))

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    apex(c)

The apex of a cone or cocone `c`.
"""
apex(c::OIC{GenericComma, <:Cone}) = source(c)
apex(c::OIC{GenericComma, <:Cocone}) = op(apex(op(c)))

"""
    legs(c)

The legs of a cone or cocone `c`, a tuple with one morphism for each vertex of
its diagram.
"""
legs(c::OIC{GenericComma, <:Cone}) = components(arrow(c))
legs(c::OIC{GenericComma, <:Cocone}) = map(op, legs(op(c)))

"""
    leg(c, j::Int)

The leg of a cone or cocone `c` at the vertex `j` of its diagram.
"""
leg(c::OIC{GenericComma, <:Union{Cone, Cocone}}, j::Int) = legs(c)[j]

"""
    apexMorphism(m)

The morphism between the apexes of a morphism `m` of cones or of cocones, i.e.
the `u` of `Hom(c₁, c₂)[u]`.
"""
apexMorphism(m::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Cone}}) =
    object(m).sourceMorph
apexMorphism(m::OIC{GenericMorphOp, <:Hom{GenericComma, GenericComma, <:Cocone}}) =
    op(apexMorphism(op(m)))

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(K::Cone) = "Cone($(name(diagram(K))))"

name(K::Cocone) = "Cocone($(name(diagram(K))))"

name(c::OIC{GenericComma, <:Union{Cone, Cocone}}) = shortName(apex(c))

name(m::OIC{GenericMorphComma, <:Hom{GenericComma, GenericComma, <:Cone}}) =
    shortName(apexMorphism(m))

name(m::OIC{GenericMorphOp, <:Hom{GenericComma, GenericComma, <:Cocone}}) =
    shortName(apexMorphism(m))
