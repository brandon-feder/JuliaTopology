# =========================================================
# ======================= DIAGRAMS ========================
# =========================================================

"""
    FuncDiagram(objects, arrows)

A diagram of shape `J :: FreeCat` in a category `C`, i.e. a functor from `J` to
`C`, an object of `Hom(Cat[J], Cat[C])`: `NamedTuple`s assigning an object of
`C` to each vertex and a morphism of `C` to each arrow of `J`. Build one with
[`diagram`](@ref), or [`parallelPair`](@ref), [`cospan`](@ref),
[`span`](@ref) or [`discrete`](@ref). Applied to a vertex `J[:X]` it gives the
object at `X`, and applied to a path, the composite of the arrows along it.
"""
struct FuncDiagram
    objects::NamedTuple
    arrows::NamedTuple
end

function checkInCategory(D::FuncDiagram, H::Hom{FreeCat, <:Any, CatCat})
    J, C = object(domain(H)), object(codomain(H))

    # one object for each vertex
    if Set(keys(D.objects)) != Set(J.vertices)
        throw(NotInCategory(D, H,
            @annotated """
            A diagram of shape $J must have one object for each of the \
            vertices $(valclr(J.vertices)), but it has objects for \
            $(valclr(keys(D.objects))).
            """
        ))
    end

    # of `C`
    for (v, X) in pairs(D.objects)
        if !(X isa OIC && category(X) == C)
            throw(NotInCategory(D, H,
                @annotated """
                The object at $(valclr(v))
                $TAB$(X isa OIC ? X : valclr(X))
                is not an object of $C, so it cannot be part of a diagram in \
                $C.
                """
            ))
        end
    end

    # one morphism for each arrow
    if Set(keys(D.arrows)) != Set(keys(J.arrows))
        throw(NotInCategory(D, H,
            @annotated """
            A diagram of shape $J must have one morphism for each of the \
            arrows $(valclr(keys(J.arrows))), but it has morphisms for \
            $(valclr(keys(D.arrows))).
            """
        ))
    end

    # of `C`, between the objects at its ends
    for (label, (s, t)) in pairs(J.arrows)
        m = D.arrows[label]
        if !(m isa OIC && category(m) isa HomLike &&
                domain(category(m)) == D.objects[s] &&
                codomain(category(m)) == D.objects[t])
            throw(NotInCategory(D, H,
                @annotated """
                The morphism at the arrow $(valclr(label)): \
                $(valclr(s)) → $(valclr(t))
                $TAB$(m isa OIC ? m : valclr(m))
                is not a morphism from $(D.objects[s]) to $(D.objects[t]), \
                the objects at $(valclr(s)) and $(valclr(t)).
                """
            ))
        end
    end

    return true
end

checkInterface(::FuncDiagram, ::Hom{FreeCat, <:Any, CatCat}) = true

function (D::OIC{FuncDiagram, <:Hom{FreeCat, <:Any, CatCat}})(v::OIC{Symbol, FreeCat})
    return object(D).objects[object(v)]
end

function (D::OIC{FuncDiagram, <:Hom{FreeCat, <:Any, CatCat}})(
    p::OIC{MorphFreeCat, <:HomLike{Symbol, Symbol, FreeCat}}
)
    path = object(p).path
    isempty(path) && return id(D(domain(category(p))))
    morph = object(D).arrows[first(path)]
    for label in path[2:end]
        morph = compose(object(D).arrows[label], morph)
    end
    return morph
end

function name(D::OIC{FuncDiagram, <:Hom{FreeCat, <:Any, CatCat}})
    objects = join(("$v: $(shortName(X))" for (v, X) in pairs(object(D).objects)), ", ")
    return "Diagram($objects)"
end

"""
    diagram(J::FreeCat, C::Category; objects_and_arrows...)

The diagram of shape `J` in `C` given by keyword arguments naming each vertex
and arrow of `J`, e.g.
`diagram(parallelPairShape(), FinSet; X = A, Y = B, f = f, g = g)`. Checks
that it is a diagram unless `force=true`.
"""
function diagram(J::FreeCat, C::Category; force::Bool=false, kwargs...)
    # every keyword names a vertex or an arrow
    for key in keys(kwargs)
        if !(key in J.vertices || haskey(J.arrows, key))
            throw(ArgumentError(
                @annotated """
                $(valclr(key)) is neither a vertex nor an arrow of $J.
                """
            ))
        end
    end
    objects = (; (v => kwargs[v] for v in J.vertices if haskey(kwargs, v))...)
    arrows = (; (a => kwargs[a] for a in keys(J.arrows) if haskey(kwargs, a))...)
    return Hom(Cat[J], Cat[C])[FuncDiagram(objects, arrows), force=force]
end

"""
    parallelPair(f, g)

The diagram `f, g: X ⇉ Y` of two morphisms with the same domain and codomain,
of shape [`parallelPairShape`](@ref).
"""
function parallelPair(f::OIC{<:Any, <:HomLike}, g::OIC{<:Any, <:HomLike})
    X, Y = domain(category(f)), codomain(category(f))
    return diagram(parallelPairShape(), category(X); X, Y, f, g)
end

"""
    cospan(f, g)

The diagram `f: A → C ← B: g` of two morphisms with the same codomain, of
shape [`cospanShape`](@ref).
"""
function cospan(f::OIC{<:Any, <:HomLike}, g::OIC{<:Any, <:HomLike})
    A, B, C = domain(category(f)), domain(category(g)), codomain(category(f))
    return diagram(cospanShape(), category(A); A, B, C, f, g)
end

"""
    span(f, g)

The diagram `A ← C → B` of two morphisms `f: C → A` and `g: C → B` with the
same domain, of shape [`spanShape`](@ref).
"""
function span(f::OIC{<:Any, <:HomLike}, g::OIC{<:Any, <:HomLike})
    C, A, B = domain(category(f)), codomain(category(f)), codomain(category(g))
    return diagram(spanShape(), category(C); C, A, B, f, g)
end

"""
    discrete(X₁, X₂, …)
    discrete(; A = X₁, B = X₂, …)

The diagram of the objects `X₁, X₂, …` of one category, with no arrows. Given
positionally, its vertices are `:X1, :X2, …`; given by keyword, they are the
keywords.
"""
function discrete(objects::OIC...; kwargs...)
    # objects are given one way
    if !isempty(objects) && !isempty(kwargs)
        throw(ArgumentError(
            @annotated """
            The objects of a discrete diagram must be given either \
            positionally or by keyword, not both.
            """
        ))
    end
    labeled = isempty(kwargs) ?
        (; (Symbol("X$i") => X for (i, X) in enumerate(objects))...) :
        (; kwargs...)

    # at least one, to know the category
    if isempty(labeled)
        throw(ArgumentError(
            @annotated """
            A discrete diagram needs at least one object to know its \
            category; for the empty diagram, use \
            $(codeclr("diagram(emptyShape(), C)")).
            """
        ))
    end
    J = discreteShape(keys(labeled)...)
    return diagram(J, category(first(labeled)); labeled...)
end

# =========================================================
# =================== DIAGONAL FUNCTORS ===================
# =========================================================

"""
    FuncDiagonal(J)

The diagonal functor `Δ: C → [J, C]` for a shape `J :: FreeCat`, an object of
`Hom(Cat[C], Cat[FunctorCat(J, C)])`. It sends an object `X` to the constant
diagram at `X`, whose arrows are all `id(X)`, and a morphism `u` to the natural
transformation whose components are all `u`. Build it with
[`diagonal`](@ref).
"""
struct FuncDiagonal
    shape::FreeCat
end

function checkInCategory(Δ::FuncDiagonal, H::Hom{<:Any, <:FunctorCat, CatCat})
    # into the functor category on its shape
    if object(codomain(H)) != FunctorCat(Δ.shape, object(domain(H)))
        throw(NotInCategory(Δ, H,
            @annotated """
            The diagonal functor of shape $(Δ.shape) is not a morphism in \
            $H, since it lands in \
            $(FunctorCat(Δ.shape, object(domain(H)))).
            """
        ))
    end
    return true
end

checkInterface(::FuncDiagonal, ::Hom{<:Any, <:FunctorCat, CatCat}) = true

"""
    diagonal(J::FreeCat, C::Category)

The diagonal functor `Δ: C → [J, C]`, see [`FuncDiagonal`](@ref).
"""
function diagonal(J::FreeCat, C::Category)
    return Hom(Cat[C], Cat[FunctorCat(J, C)])[FuncDiagonal(J), force=true]
end

function (Δ::OIC{FuncDiagonal, <:Hom{CatT, <:FunctorCat, CatCat}})(
    X::OIC{<:Any, CatT}
) where CatT
    J, C = object(Δ).shape, category(X)
    D = diagram(J, C; force=true,
        (v => X for v in J.vertices)..., (a => id(X) for a in keys(J.arrows))...)
    return FunctorCat(J, C)[D, force=true]
end

function (Δ::OIC{FuncDiagonal, <:Hom{CatT, <:FunctorCat, CatCat}})(
    u::OIC{<:Any, <:HomLike{<:Any, <:Any, CatT}}
) where CatT
    J = object(Δ).shape
    Kind = category(u) isa Iso ? Iso : Hom
    return Kind(Δ(domain(category(u))), Δ(codomain(category(u))))[
        MorphNat((; (v => u for v in J.vertices)...)), force=true
    ]
end

name(::OIC{FuncDiagonal, <:Hom{<:Any, <:FunctorCat, CatCat}}) = "Δ"
