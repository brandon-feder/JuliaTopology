"""
    FunctorCat(J, C)

The functor category `[J, C]` for a shape `J :: FreeCat` and a category `C`.
Its objects are the diagrams of shape `J` in `C`, i.e. objects of
`Hom(Cat[J], Cat[C])` (see [`diagram`](@ref)), written `FunctorCat(J, C)[D]`.
Its morphisms are natural transformations, [`MorphNat`](@ref)s.

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
    MorphNat(components)

A natural transformation `η: D₁ → D₂` between diagrams of shape `J`, a morphism
of [`FunctorCat`](@ref)`(J, C)`: a `NamedTuple` with a component
`η_j: D₁(j) → D₂(j)` in `C` for each vertex `j`, such that
`D₂(a) ∘ η_j == η_k ∘ D₁(a)` for each arrow `a: j → k`.
"""
struct MorphNat
    components::NamedTuple
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj, K::FunctorCat)
    # a functor from `J` to `C`
    if !(obj isa OIC && category(obj) isa HomLike{<:Any, <:Any, CatCat} &&
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

checkInterface(::OIC, ::FunctorCat) = true

function checkInCategory(η::MorphNat, H::HomLike{<:Any, <:Any, <:FunctorCat})
    J = category(H).J
    D₁, D₂ = object(domain(H)), object(codomain(H))

    # one component for each vertex
    if Set(keys(η.components)) != Set(J.vertices)
        throw(NotInCategory(η, H,
            @annotated """
            A natural transformation in $H must have one component for each \
            of the vertices $(valclr(J.vertices)), but it has components for \
            $(valclr(keys(η.components))).
            """
        ))
    end

    # `η_j: D₁(j) → D₂(j)`
    for j in J.vertices
        c = η.components[j]
        if !(c isa OIC && category(c) isa HomLike &&
                domain(category(c)) == D₁(J[j]) &&
                codomain(category(c)) == D₂(J[j]))
            throw(NotInCategory(η, H,
                @annotated """
                The component at $(valclr(j))
                $TAB$(c isa OIC ? c : valclr(c))
                is not a morphism from $(D₁(J[j])) to $(D₂(J[j])), so it \
                cannot be a component of a natural transformation in $H.
                """
            ))
        end
    end

    # of the kind of `H`, componentwise
    if H isa Union{Iso, Epi, Mono}
        Kind = typeof(H).name.wrapper
        for j in J.vertices
            c = η.components[j]
            if !(object(c) in Kind(domain(category(c)), codomain(category(c))))
                throw(NotInCategory(η, H,
                    @annotated """
                    The natural transformation is not in $H, since its \
                    component at $(valclr(j))
                    $TAB$c
                    is not in $(Kind(domain(category(c)), codomain(category(c)))).
                    """
                ))
            end
        end
    end

    # natural: `D₂(a) ∘ η_j == η_k ∘ D₁(a)` for each arrow `a: j → k`
    for (label, (j, k)) in pairs(J.arrows)
        a = generator(J, label)
        lhs = compose(D₂(a), η.components[j])
        rhs = compose(η.components[k], D₁(a))

        # which can only be checked when the morphisms of `C` can be compared
        if !hasmethod(firstDifference, Tuple{typeof(lhs), typeof(rhs)})
            throw(NotInCategory(η, H,
                @annotated """
                Whether a natural transformation in $H is natural can only be \
                checked when the morphisms of $(category(H).C) can be \
                compared (with $(codeclr("firstDifference"))), which they \
                cannot. If you know it is, you may skip the check with \
                `force=true`.
                """
            ))
        end

        difference = firstDifference(lhs, rhs)
        if difference !== nothing
            throw(NotInCategory(η, H,
                @annotated """
                The natural transformation is not in $H, since it is not \
                natural at the arrow $(valclr(label)): the element \
                $(objclr(name(difference.at))) of $(valclr(j)) is sent to \
                $(objclr(name(difference.left))) by \
                $(codeclr("D₂($label) ∘ η_$j")) but to \
                $(objclr(name(difference.right))) by \
                $(codeclr("η_$k ∘ D₁($label)")).
                """
            ))
        end
    end

    return true
end

checkInterface(::MorphNat, ::HomLike{<:Any, <:Any, <:FunctorCat}) = true

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

function compose(
    θ::OIC{MorphNat, <:HomLike{<:Any, <:Any, <:FunctorCat}},
    η::OIC{MorphNat, <:HomLike{<:Any, <:Any, <:FunctorCat}}
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

    Kind = E isa Iso && T isa Iso ? Iso :
        E isa Union{Iso, Mono} && T isa Union{Iso, Mono} ? Mono :
        E isa Union{Iso, Epi} && T isa Union{Iso, Epi} ? Epi : Hom
    components = map(compose, object(θ).components, object(η).components)
    return Kind(domain(E), codomain(T))[MorphNat(components), force=true]
end

function id(D::OIC{<:Any, <:FunctorCat})
    J = category(D).J
    components = (; (j => id(object(D)(J[j])) for j in J.vertices)...)
    return Iso(D, D)[MorphNat(components), force=true]
end

"""
    firstDifference(η, θ)

For natural transformations `η, θ: D₁ → D₂`, `nothing` when every component
agrees, and otherwise `(at = (j, x), left, right)` for the first vertex `j`
whose components differ, at `x`.
"""
function firstDifference(
    η::OIC{MorphNat, <:HomLike{<:Any, <:Any, <:FunctorCat}},
    θ::OIC{MorphNat, <:HomLike{<:Any, <:Any, <:FunctorCat}}
)
    for j in category(category(η)).J.vertices
        difference = firstDifference(object(η).components[j], object(θ).components[j])
        if difference !== nothing
            return (at = (j, difference.at), left = difference.left,
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

function name(η::OIC{MorphNat, <:HomLike{<:Any, <:Any, <:FunctorCat}})
    components = object(η).components
    return "(" * join(("$j: $(shortName(c))" for (j, c) in pairs(components)),
        ", ") * ")"
end
