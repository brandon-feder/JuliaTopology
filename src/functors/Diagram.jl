# =========================================================
# ======================= DIAGRAMS ========================
# =========================================================

"""
    FuncDiagram(objects, arrows)

A diagram of shape `J` in a category `C`, i.e. a functor from `J` to
`C`, an object of `Hom(Cat[J], Cat[C])`: `NamedTuple`s assigning an object of
`C` to each vertex and a morphism of `C` to each arrow of `J`. Build one with
[`diagram`](@ref), or [`parallelPair`](@ref), [`cospan`](@ref),
[`span`](@ref) or [`discrete`](@ref). The shape `J` may be any category
defining [`vertices`](@ref) and [`generators`](@ref), such as a
[`FreeCat`](@ref). Applied to a vertex `J[:X]` it gives the
object at `X`, and applied to a path, the composite of the arrows along it.
"""
struct FuncDiagram
    objects::NamedTuple
    arrows::NamedTuple
end

"""
    shape(D)

The shape of a diagram `D`, the category it is a functor from.
"""
shape(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = object(domain(category(D)))

function checkInCategory(D::FuncDiagram, H::Hom{<:Any, <:Any, CatCat})
    J, C = object(domain(H)), object(codomain(H))

    # one object for each vertex
    if Set(keys(D.objects)) != Set(vertices(J))
        throw(NotInCategory(D, H,
            @annotated """
            A diagram of shape $J must have one object for each of the \
            vertices $(valclr(vertices(J))), but it has objects for \
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
    if Set(keys(D.arrows)) != Set(keys(generators(J)))
        throw(NotInCategory(D, H,
            @annotated """
            A diagram of shape $J must have one morphism for each of the \
            arrows $(valclr(keys(generators(J)))), but it has morphisms for \
            $(valclr(keys(D.arrows))).
            """
        ))
    end

    # of `C`, between the objects at its ends
    for (label, (s, t)) in pairs(generators(J))
        m = D.arrows[label]
        if !(m isa OIC && category(m) isa Hom &&
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


function (D::OIC{FuncDiagram, <:Hom{JT, <:Any, CatCat}})(v::OIC{Symbol, JT}) where JT
    return object(D).objects[object(v)]
end

# by label: the object at a vertex, or the morphism at an arrow
function (D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})(label::Symbol)
    haskey(object(D).objects, label) && return object(D).objects[label]
    haskey(object(D).arrows, label) && return object(D).arrows[label]
    throw(ArgumentError(
        @annotated """
        $(valclr(label)) is neither a vertex nor an arrow of $(shape(D)).
        """
    ))
end

function (D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})(
    p::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}}
)
    path = object(p).path
    isempty(path) && return id(D(domain(category(p))))
    morph = object(D).arrows[first(path)]
    for label in path[2:end]
        morph = compose(object(D).arrows[label], morph)
    end
    return morph
end

function name(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})
    objects = join(("$v: $(shortName(X))" for (v, X) in pairs(object(D).objects)), ", ")
    return "Diagram($objects)"
end

"""
    op(D)

The opposite `Dᵒᵖ: Jᵒᵖ → Cᵒᵖ` of a diagram `D: J → C`, sending each vertex to
`op(D(j))` and each arrow to `op(D(a))`; `op(op(D)) == D`.
"""
function op(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})
    J, C = shape(D), object(codomain(category(D)))
    return diagram(op(J), op(C); force=true,
        (v => op(X) for (v, X) in pairs(object(D).objects))...,
        (a => op(f) for (a, f) in pairs(object(D).arrows))...)
end

"""
    diagram(J::Category, C::Category; objects_and_arrows...)
    diagram(J::Category; objects_and_arrows...)

The diagram of shape `J` in `C` given by keyword arguments naming each vertex
and arrow of `J`, e.g. `diagram(parallelPairShape(); X = A, Y = B, f = f,
g = g)`. Without `C`, the category is that of the objects. Checks that it is a
diagram unless `force=true`.
"""
function diagram(J::Category; force::Bool=false, kwargs...)
    given = findfirst(v -> haskey(kwargs, v), vertices(J))

    # an object to read the category off
    if given === nothing
        throw(ArgumentError(
            @annotated """
            No object is given for any vertex of $J, so there is none to \
            read the diagram's category off; give it explicitly, as \
            $(codeclr("diagram(J, C; …)")).
            """
        ))
    end
    return diagram(J, category(kwargs[vertices(J)[given]]); force, kwargs...)
end

function diagram(J::Category, C::Category; force::Bool=false, kwargs...)
    # every keyword names a vertex or an arrow
    for key in keys(kwargs)
        if !(key in vertices(J) || haskey(generators(J), key))
            throw(ArgumentError(
                @annotated """
                $(valclr(key)) is neither a vertex nor an arrow of $J.
                """
            ))
        end
    end
    objects = (; (v => kwargs[v] for v in vertices(J) if haskey(kwargs, v))...)
    arrows = (; (a => kwargs[a] for a in keys(generators(J)) if haskey(kwargs, a))...)
    return Hom(Cat[J], Cat[C])[FuncDiagram(objects, arrows), force=force]
end

"""
    constant(X)

The functor from [`Point`](@ref) to the category of `X` sending its one object
to `X`, i.e. the diagram of shape `Point` at `X`.
"""
constant(X::OIC) = diagram(Point, category(X); pt = X)

"""
    toPoint(J)

The unique functor from a shape `J` to [`Point`](@ref), sending every vertex
to `Point[:pt]` and every arrow to its identity. The constant diagram of shape
`J` at `X` is `constant(X) ∘ toPoint(J)`.
"""
function toPoint(J::Category)
    return diagram(J, Point; force=true, (v => Point[:pt] for v in vertices(J))...,
        (a => id(Point[:pt]) for a in keys(generators(J)))...)
end

"""
    parallelPair(f, g)

The diagram `f, g: X ⇉ Y` of two morphisms with the same domain and codomain,
of shape [`parallelPairShape`](@ref).
"""
function parallelPair(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
    X, Y = domain(category(f)), codomain(category(f))
    return diagram(parallelPairShape(), category(X); X, Y, f, g)
end

"""
    cospan(f, g)

The diagram `f: A → C ← B: g` of two morphisms with the same codomain, of
shape [`cospanShape`](@ref).
"""
function cospan(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
    A, B, C = domain(category(f)), domain(category(g)), codomain(category(f))
    return diagram(cospanShape(), category(A); A, B, C, f, g)
end

"""
    span(f, g)

The diagram `A ← C → B` of two morphisms `f: C → A` and `g: C → B` with the
same domain, of shape [`spanShape`](@ref).
"""
function span(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
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

The diagonal functor `Δ: C → [J, C]` for a shape `J`, an object of
`Hom(Cat[C], Cat[FunctorCat(J, C)])`. It sends an object `X` to the constant
diagram `constant(X) ∘ toPoint(J)`, whose arrows are all `id(X)`, and a
morphism `u` to the natural
transformation whose components are all `u`. Build it with
[`diagonal`](@ref).
"""
struct FuncDiagonal
    shape::Category
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


"""
    diagonal(J::Category, C::Category)

The diagonal functor `Δ: C → [J, C]`, see [`FuncDiagonal`](@ref).
"""
function diagonal(J::Category, C::Category)
    return Hom(Cat[C], Cat[FunctorCat(J, C)])[FuncDiagonal(J), force=true]
end

function (Δ::OIC{FuncDiagonal, <:Hom{CatT, <:FunctorCat, CatCat}})(
    X::OIC{<:Any, CatT}
) where CatT
    J = object(Δ).shape
    return FunctorCat(J, category(X))[constant(X) ∘ toPoint(J), force=true]
end

function (Δ::OIC{FuncDiagonal, <:Hom{CatT, <:FunctorCat, CatCat}})(
    u::OIC{<:Any, <:Hom{<:Any, <:Any, CatT}}
) where CatT
    J = object(Δ).shape
    return Hom(Δ(domain(category(u))), Δ(codomain(category(u))))[
        (; (v => u for v in vertices(J))...), force=true
    ]
end

name(::OIC{FuncDiagonal, <:Hom{<:Any, <:FunctorCat, CatCat}}) = "Δ"
