# =========================================================
# ======================= DIAGRAMS ========================
# =========================================================

"""
    FuncDiagram(objects, arrows)

A diagram of shape `J` in a category `C`, i.e. a functor from `J` to
`C`, an object of `Hom(Cat[J], Cat[C])`: a tuple of objects of `C`, one for
each vertex `1:nvertices(J)`, and a tuple of morphisms of `C`, one for each
arrow of [`generators`](@ref)`(J)`. Build one with [`diagram`](@ref), or
[`parallelPair`](@ref), [`cospan`](@ref), [`span`](@ref) or
[`discrete`](@ref). The shape `J` may be any category defining
[`nvertices`](@ref) and [`generators`](@ref), such as a [`FreeCat`](@ref).
Applied to a vertex `J[i]` it gives the object at `i`, and applied to a path,
the composite of the arrows along it.
"""
struct FuncDiagram
    objects::Tuple
    arrows::Tuple
end

"""
    shape(D)

The shape of a diagram `D`, the category it is a functor from.
"""
shape(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = object(domain(category(D)))

"""
    objects(D)

The objects of a diagram `D`, a tuple with the object at each vertex.
"""
objects(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = object(D).objects

"""
    arrows(D)

The morphisms of a diagram `D`, a tuple with the morphism at each generating
arrow of its shape.
"""
arrows(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = object(D).arrows

function checkInCategory(D::FuncDiagram, H::Hom{<:Any, <:Any, CatCat})
    J, C = object(domain(H)), object(codomain(H))

    # one object for each vertex
    if length(D.objects) != nvertices(J)
        throw(NotInCategory(D, H,
            @annotated """
            A diagram of shape $J must have one object for each of its \
            $(valclr(nvertices(J))) vertices, but it has \
            $(valclr(length(D.objects))).
            """
        ))
    end

    # of `C`
    for (i, X) in enumerate(D.objects)
        if !(X isa OIC && category(X) == C)
            throw(NotInCategory(D, H,
                @annotated """
                The object at the vertex $(valclr(i))
                $TAB$(X isa OIC ? X : valclr(X))
                is not an object of $C, so it cannot be part of a diagram in \
                $C.
                """
            ))
        end
    end

    # one morphism for each arrow
    if length(D.arrows) != length(generators(J))
        throw(NotInCategory(D, H,
            @annotated """
            A diagram of shape $J must have one morphism for each of its \
            $(valclr(length(generators(J)))) arrows, but it has \
            $(valclr(length(D.arrows))).
            """
        ))
    end

    # of `C`, between the objects at its ends
    for (k, (s, t)) in enumerate(generators(J))
        m = D.arrows[k]
        if !(m isa OIC && category(m) isa Hom &&
                domain(category(m)) == D.objects[s] &&
                codomain(category(m)) == D.objects[t])
            throw(NotInCategory(D, H,
                @annotated """
                The morphism at the arrow $(valclr(k)), from the vertex \
                $(valclr(s)) to the vertex $(valclr(t)),
                $TAB$(m isa OIC ? m : valclr(m))
                is not a morphism from $(D.objects[s]) to $(D.objects[t]), \
                the objects at those vertices.
                """
            ))
        end
    end

    return true
end


function (D::OIC{FuncDiagram, <:Hom{JT, <:Any, CatCat}})(v::OIC{Int, JT}) where JT
    return objects(D)[object(v)]
end

function (D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})(
    p::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}
)
    path = object(p).path
    isempty(path) && return id(D(domain(category(p))))
    morph = arrows(D)[first(path)]
    for k in path[2:end]
        morph = compose(arrows(D)[k], morph)
    end
    return morph
end

name(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) =
    "Diagram($(join(map(shortName, objects(D)), ", ")))"

"""
    op(D)

The opposite `Dᵒᵖ: Jᵒᵖ → Cᵒᵖ` of a diagram `D: J → C`, sending each vertex to
`op(D(j))` and each arrow to `op(D(a))`; `op(op(D)) == D`.
"""
function op(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}})
    J, C = shape(D), object(codomain(category(D)))
    return diagram(op(J), op(C), map(op, objects(D)), map(op, arrows(D)); force=true)
end

"""
    diagram(J::Category, C::Category, objects = (), arrows = ())
    diagram(J::Category, objects, arrows = ())

The diagram of shape `J` in `C` with the object `objects[i]` at each vertex `i`
and the morphism `arrows[k]` at each generating arrow `k` of `J`, e.g.
`diagram(parallelPairShape(), (A, B), (f, g))`. Without `C`, the category is
that of the objects. Checks that it is a diagram unless `force=true`.
"""
function diagram(J::Category, Xs::Tuple, ms::Tuple=(); force::Bool=false)
    # an object to read the category off
    if isempty(Xs)
        throw(ArgumentError(
            @annotated """
            No object is given, so there is none to read the diagram's \
            category off; give it explicitly, as \
            $(codeclr("diagram(J, C, objects, arrows)")).
            """
        ))
    end
    return diagram(J, category(first(Xs)), Xs, ms; force)
end

function diagram(J::Category, C::Category, Xs::Tuple=(), ms::Tuple=(); force::Bool=false)
    return Hom(Cat[J], Cat[C])[FuncDiagram(Xs, ms), force=force]
end

"""
    diagram(F)

The diagram of a functor `F` out of a shape `J`: its object at each vertex and
its morphism at each generating arrow of `J`. A diagram is its own diagram; for
a functor out of a [`FreeCat`](@ref) it is `F` applied to each vertex `J[i]`
and each `generator(J, k)`. Other functors may define it, which lets natural
transformations between them be checked.
"""
diagram(F::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = F
diagram(F::OIC{FuncDiagram, <:Hom{FreeCat, <:Any, CatCat}}) = F

function diagram(F::OIC{<:Any, <:Hom{FreeCat, <:Any, CatCat}})
    J, C = object(domain(category(F))), object(codomain(category(F)))
    return diagram(J, C, map(i -> F(J[i]), Tuple(vertices(J))),
        map(k -> F(generator(J, k)), Tuple(eachindex(generators(J)))))
end

function diagram(F::OIC{<:Any, <:Hom{<:Any, <:Any, CatCat}})
    J = object(domain(category(F)))
    throw(InterfaceViolation(
        @annotated """
        The functor
        $TAB$F
        is not a diagram, and functors of type \
        $(dtclr(typeString(typeof(object(F))))) out of $J cannot be turned \
        into one, since there is no way to list their objects and morphisms \
        at the vertices and generating arrows of $J. When appropriate, you \
        may define this by overloading
        $(overloadHint("diagram", ("F", @annotated("any functor out of $J \
            represented by values of type \
            $(dtclr(typeString(typeof(object(F)))))"),
            "OIC{$(typeString(typeof(object(F)))), <:Hom{\
            $(typeString(typeof(J))), <:Any, CatCat}}")))
        to return a diagram, e.g. built by \
        $(codeclr("diagram(J, C, objects, arrows)")).
        """
    ))
end

# the fallback only throws, so it does not count as turning a functor into a
# diagram, e.g. for checking natural transformations
append!(FALLBACK_SIGNATURES, [
    which(Tuple{typeof(diagram), OIC{Nothing, Hom{Nothing, Nothing, CatCat}}}).sig,
])

"""
    constant(X)

The functor from [`Point`](@ref) to the category of `X` sending its one object
to `X`, i.e. the diagram of shape `Point` at `X`.
"""
constant(X::OIC) = diagram(Point, category(X), (X,))

"""
    toPoint(J)

The unique functor from a shape `J` to [`Point`](@ref), sending every vertex
to `Point[1]` and every arrow to its identity. The constant diagram of shape
`J` at `X` is `constant(X) ∘ toPoint(J)`.
"""
function toPoint(J::Category)
    return diagram(J, Point, ntuple(_ -> Point[1], nvertices(J)),
        map(_ -> id(Point[1]), generators(J)); force=true)
end

"""
    parallelPair(f, g)

The diagram `f, g: X ⇉ Y` of two morphisms with the same domain and codomain,
of shape [`parallelPairShape`](@ref), with `X` at vertex 1 and `Y` at 2.
"""
function parallelPair(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
    X, Y = domain(category(f)), codomain(category(f))
    return diagram(parallelPairShape(), (X, Y), (f, g))
end

"""
    cospan(f, g)

The diagram `f: A → C ← B: g` of two morphisms with the same codomain, of
shape [`cospanShape`](@ref), with `A`, `B`, `C` at vertices 1, 2, 3.
"""
function cospan(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
    A, B, C = domain(category(f)), domain(category(g)), codomain(category(f))
    return diagram(cospanShape(), (A, B, C), (f, g))
end

"""
    span(f, g)

The diagram `A ← C → B` of two morphisms `f: C → A` and `g: C → B` with the
same domain, of shape [`spanShape`](@ref), with `C`, `A`, `B` at vertices 1,
2, 3.
"""
function span(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
    C, A, B = domain(category(f)), codomain(category(f)), codomain(category(g))
    return diagram(spanShape(), (C, A, B), (f, g))
end

"""
    discrete(X₁, X₂, …)

The diagram of the objects `X₁, X₂, …` of one category, with no arrows, of
shape [`discreteShape`](@ref)`(n)`, with `Xᵢ` at vertex `i`.
"""
function discrete(Xs::OIC...)
    # at least one, to know the category
    if isempty(Xs)
        throw(ArgumentError(
            @annotated """
            A discrete diagram needs at least one object to know its \
            category; for the empty diagram, use \
            $(codeclr("diagram(emptyShape(), C)")).
            """
        ))
    end
    return diagram(discreteShape(length(Xs)), Xs)
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
        ntuple(_ -> u, nvertices(J)), force=true
    ]
end

name(::OIC{FuncDiagonal, <:Hom{<:Any, <:FunctorCat, CatCat}}) = "Δ"
