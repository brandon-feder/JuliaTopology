const Cone = Comma{<:OIC{FuncDiagonal}, <:OIC{FuncDiagram}}

const Cocone = Op{<:Cone}

"""
    Cone(D)

The category of cones over a diagram `D` of shape `J` in `C`, i.e. the comma
category `Δ ↓ D` of the diagonal functor `Δ: C → [J, C]` and `D`, regarded as a
functor from [`Point`](@ref) by [`constant`](@ref). A cone is an apex `X` with a leg `X → D(j)` for
each vertex `j`, commuting with the arrows of `D`, written
`Cone(D)[(A = legA, B = legB, …)]`, or `Cone(D)[X, legs]` for an empty
diagram. A morphism of cones is a morphism `u` between their apexes
commuting with the legs, written `Hom(c₁, c₂)[u]`. A limit of `D` is a
terminal object of `Cone(D)`, see [`limit`](@ref). `Cone` is also the type of
every cone category, for dispatch.

# Standardized Interface
- `apex(c)`, `legs(c)`, `leg(c, :A)` — the apex and legs of a cone `c`
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
`Cocone(D)[(A = legA, B = legB, …)]`, or `Cocone(D)[X, legs]` for an empty
diagram. A morphism of cocones is a morphism `u` between their apexes
commuting with the legs, written `Hom(c₁, c₂)[u]`. A colimit of `D` is an
initial object of `Cocone(D)`, see [`colimit`](@ref). `Cocone` is also the
type of every cocone category, for dispatch.

# Standardized Interface
- `apex(c)`, `legs(c)`, `leg(c, :A)` — the apex and legs of a cocone `c`
"""
Cocone(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = op(Cone(op(D)))

"""
    diagram(K)

The diagram `D` of the category of cones `K = Cone(D)`, or of cocones
`K = Cocone(D)`.
"""
diagram(K::Cone) = object(object(K.G).objects.pt)
diagram(K::Cocone) = op(diagram(op(K)))

# =========================================================
# ======================= SHORTHAND =======================
# =========================================================

function Base.getindex(K::Cone, X::OIC, legs::NamedTuple; force::Bool=false)
    Δ = K.F
    λ = Hom(Δ(X), category(Δ(X))[diagram(K), force=true])[legs, force=force]
    return K[GenericComma(X, Point[:pt], λ), force=force]
end

# a cocone is the opposite of a cone over the opposite diagram
function Base.getindex(K::Cocone, X::OIC, legs::NamedTuple; force::Bool=false)
    D = diagram(K)

    # each leg goes from the object of its vertex to the apex, checked here so
    # that the message speaks of cocones rather than of opposite cones
    for (j, ℓ) in pairs(legs)
        if !force && haskey(object(D).objects, j) && !(ℓ isa OIC &&
                category(ℓ) isa Hom && domain(category(ℓ)) == D(j) &&
                codomain(category(ℓ)) == X)
            throw(NotInCategory(ℓ, K,
                @annotated """
                The leg at $(valclr(j))
                $TAB$(ℓ isa OIC ? ℓ : valclr(ℓ))
                is not a morphism from $(D(j)) to the apex $X, so it cannot be \
                a leg of a cocone in $K.
                """
            ))
        end
    end

    # and commutes with the arrows of `D`, for cocones of finite sets
    if !force && category(X) isa CatFinSet && Set(keys(legs)) == Set(vertices(shape(D)))
        for (label, (j, k)) in pairs(generators(shape(D))), x in D(j)
            lhs, rhs = legs[k](D(label)(x)), legs[j](x)
            if lhs != rhs
                throw(NotInCategory(legs, K,
                    @annotated """
                    The legs do not form a cocone in $K, since they do not \
                    commute with the arrow $(valclr(label)): the element \
                    $(objclr(name(x))) of $(valclr(j)) is sent to \
                    $(objclr(name(lhs))) by the leg at $(valclr(k)) after \
                    $(valclr(label)), but to $(objclr(name(rhs))) by the leg at \
                    $(valclr(j)).
                    """
                ))
            end
        end
    end
    return op(op(K)[op(X), map(op, legs), force=force])
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
    H::Hom{GenericComma, GenericComma, <:Cone}, u::OIC{<:Any, <:Hom};
    force::Bool=false
)
    return H[GenericMorphComma(u, id(Point[:pt])), force=force]
end

function Base.getindex(
    H::Hom{GenericComma, GenericComma, <:Cocone}, u::OIC{<:Any, <:Hom};
    force::Bool=false
)
    return op(Hom(op(codomain(H)), op(domain(H)))[op(u), force=force])
end

# a cone or cocone over a one-object diagram has one leg, which may be given
# alone, as for a slice or coslice
function Base.getindex(
    K::Union{Cone, Cocone}, f::OIC{<:Any, <:Hom}; force::Bool=false
)
    vs = vertices(shape(diagram(K)))

    # only over a one-object diagram
    if length(vs) != 1
        throw(ArgumentError(
            @annotated """
            A single morphism can only be given as a cone or cocone over a \
            diagram with one object, but $K is over one with \
            $(length(vs)); give its legs as \
            $(codeclr("K[(A = legA, B = legB, …)]")) instead.
            """
        ))
    end
    return K[(; only(vs) => f), force=force]
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

The legs of a cone or cocone `c`, a `NamedTuple` with one morphism for each
vertex of its diagram.
"""
legs(c::OIC{GenericComma, <:Cone}) = components(arrow(c))
legs(c::OIC{GenericComma, <:Cocone}) = map(op, legs(op(c)))

"""
    leg(c, j::Symbol)

The leg of a cone or cocone `c` at the vertex `j` of its diagram.
"""
leg(c::OIC{GenericComma, <:Union{Cone, Cocone}}, j::Symbol) = legs(c)[j]

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
