# =========================================================
# ======================== SHAPES =========================
# =========================================================

"""
    nvertices(J)

The number of objects of a shape `J`, a category diagrams are functors from;
its objects are the vertices `1:nvertices(J)`. With [`generators`](@ref), all
that diagrams, functor categories and limits need to know of `J`.
[`FreeCat`](@ref) defines both; any other category may be used as a shape by
defining them too.
"""
function nvertices(J::Category)
    throw(InterfaceViolation(
        @annotated """
        The category $J cannot be the shape of a diagram, since it does not \
        count its objects. When appropriate, you may make it a shape by \
        overloading
        $(overloadHint("nvertices", ("J", @annotated("the category $J"),
            typeString(typeof(J)))))
        and $(codeclr("generators")).
        """
    ))
end

"""
    vertices(J)

The objects of a shape `J`, the integers `1:nvertices(J)`.
"""
vertices(J::Category) = 1:nvertices(J)

"""
    generators(J)

The generating arrows of a shape `J`, a tuple of `source => target` pairs of
[`vertices`](@ref)`(J)`; arrow `k` is `generators(J)[k]`. Every morphism of
`J` should be a composite of these: a diagram gives a morphism for each of
them, and a cone need only commute with them.
"""
function generators(J::Category)
    throw(InterfaceViolation(
        @annotated """
        The category $J cannot be the shape of a diagram, since it does not \
        list its generating arrows. When appropriate, you may make it a shape \
        by overloading
        $(overloadHint("generators", ("J", @annotated("the category $J"),
            typeString(typeof(J)))))
        and $(codeclr("nvertices")).
        """
    ))
end

"""
    FreeCat(n, arrows = ())

The free category on a finite graph, used as the shape of a diagram. Its
objects are the vertices `1:n`, written `J[i]`. Its morphisms are the paths
along its `arrows`, a tuple of `source => target` pairs, arrow `k` being
`arrows[k]`, e.g.

```julia
J = FreeCat(2, (1 => 2, 1 => 2))
```

# Standardized Interface
- `generator(J, k)` — the arrow `k` as a morphism
- `compose(q, p)`, `id(J[i])` — joining paths, and the empty path
- `discreteShape`, `emptyShape`, `parallelPairShape`, `cospanShape`,
  `spanShape` — common shapes

# Interface Specification Assumptions
- `J :: FreeCat`; `p, q` are its morphisms
"""
struct FreeCat <: Category
    n::Int
    arrows::Tuple{Vararg{Pair{Int, Int}}}

    function FreeCat(n::Integer, arrows=())
        # a number of vertices
        if n < 0
            throw(ArgumentError(
                @annotated """
                A free category must have a nonnegative number of vertices, \
                but it is given $(valclr(n)).
                """
            ))
        end

        for (k, ends) in enumerate(arrows)
            # arrows are `source => target` pairs
            if !(ends isa Pair{<:Integer, <:Integer})
                throw(ArgumentError(
                    @annotated """
                    The arrow $(valclr(k)) of a free category must be given \
                    as $(codeclr("source => target")), but it is
                    $TAB$(valclr(ends)).
                    """
                ))
            end

            # between vertices
            if !(first(ends) in 1:n && last(ends) in 1:n)
                throw(ArgumentError(
                    @annotated """
                    The arrow $(valclr(k)) goes from $(valclr(first(ends))) \
                    to $(valclr(last(ends))), which are not both among the \
                    vertices $(valclr(1:n)).
                    """
                ))
            end
        end

        return new(n, Tuple(Int(first(e)) => Int(last(e)) for e in arrows))
    end
end

"""
    GenericMorphFreeCat(path)

A morphism of a [`FreeCat`](@ref): a path, given as the indices of its arrows
in the order they are followed. The empty path is the identity.
"""
struct GenericMorphFreeCat
    path::Tuple{Vararg{Int}}
end

GenericMorphFreeCat(path::AbstractVector) = GenericMorphFreeCat(Tuple(path))

nvertices(J::FreeCat) = J.n
generators(J::FreeCat) = J.arrows

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj, J::FreeCat)
    # a vertex
    if !(obj isa Int && obj in vertices(J))
        throw(NotInCategory(obj, J,
            @annotated """
            The value
            $TAB$(valclr(obj))
            is not an object of $J, whose objects are its vertices.
            """
        ))
    end
    return true
end


function checkInCategory(morph::GenericMorphFreeCat, H::Hom{Int, Int, FreeCat})
    J = category(H)
    current = object(domain(H))

    for k in morph.path
        # an arrow of `J`
        if !(k in eachindex(J.arrows))
            throw(NotInCategory(morph, H,
                @annotated """
                The path $(valclr(morph.path)) is not a morphism in $H, \
                since $(valclr(k)) is not an arrow of $J.
                """
            ))
        end

        # which continues the path
        if first(J.arrows[k]) != current
            throw(NotInCategory(morph, H,
                @annotated """
                The path $(valclr(morph.path)) is not a morphism in $H, \
                since the arrow $(valclr(k)) starts at \
                $(valclr(first(J.arrows[k]))), not at $(valclr(current)), \
                where the path so far ends.
                """
            ))
        end
        current = last(J.arrows[k])
    end

    # ending at the codomain
    if current != object(codomain(H))
        throw(NotInCategory(morph, H,
            @annotated """
            The path $(valclr(morph.path)) is not a morphism in $H, since it \
            ends at $(valclr(current)).
            """
        ))
    end

    return true
end


# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    H[path::Tuple, force=false]

The path `path`, a tuple of arrow indices in the order they are followed, as a
morphism in `H = Hom(J[i], J[j])`, e.g. `Hom(J[1], J[3])[(1, 2)]`; `()` is the
identity.
"""
function Base.getindex(
    H::Hom{Int, Int, FreeCat}, path::Tuple{Vararg{Int}}; force::Bool=false
)
    return H[GenericMorphFreeCat(path), force=force]
end

"""
    generator(J::FreeCat, k::Int)

The arrow `k` of `J`, as a morphism of `J`.
"""
function generator(J::FreeCat, k::Int)
    # an arrow of `J`
    if !(k in eachindex(J.arrows))
        throw(ArgumentError(
            @annotated """
            $(valclr(k)) is not an arrow of $J, whose arrows are \
            $(valclr(eachindex(J.arrows))).
            """
        ))
    end
    source, target = J.arrows[k]
    return Hom(J[source], J[target])[GenericMorphFreeCat((k,)), force=true]
end

function compose(
    q::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}},
    p::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}
)
    P, Q = category(p), category(q)

    # `p` ends where `q` starts
    if codomain(P) != domain(Q)
        throw(ArgumentError(
            @annotated """
            The paths
            $TAB$q
            and
            $TAB$p
            cannot be composed, since the second ends at \
            $(objclr(name(codomain(P)))) but the first starts at \
            $(objclr(name(domain(Q)))).
            """
        ))
    end

    return Hom(domain(P), codomain(Q))[
        GenericMorphFreeCat((object(p).path..., object(q).path...)), force=true
    ]
end

id(X::OIC{Int, FreeCat}) = Hom(X, X)[GenericMorphFreeCat(()), force=true]

"""
    discreteShape(n)

The free category with `n` vertices and no arrows, the shape of a product or
coproduct of `n` objects.
"""
discreteShape(n::Integer) = FreeCat(n)

"""
    Point

The terminal category, the free category with a single vertex and no arrows.
Its only object is `Point[1]`, and its only morphism is `id(Point[1])`.
"""
const Point = FreeCat(1)

"""
    emptyShape()

The free category with no vertices, the shape of a terminal or initial object.
"""
emptyShape() = FreeCat(0)

"""
    parallelPairShape()

The free category on two arrows `1 → 2`, the shape of an equalizer or
coequalizer.
"""
parallelPairShape() = FreeCat(2, (1 => 2, 1 => 2))

"""
    cospanShape()

The free category on the arrows `1 → 3` and `2 → 3`, the shape of a pullback.
"""
cospanShape() = FreeCat(3, (1 => 3, 2 => 3))

"""
    spanShape()

The free category on the arrows `1 → 2` and `1 → 3`, the shape of a pushout.
"""
spanShape() = FreeCat(3, (1 => 2, 1 => 3))

# =========================================================
# ======================= PRINTING ========================
# =========================================================

function name(J::FreeCat)
    # arrow `k` prints as `s → t`, or `s →ₖ t` when another arrow is parallel
    # to it, as its morphism does
    arrows = join((count(==(ends), J.arrows) == 1 ?
        "$(first(ends)) → $(last(ends))" :
        "$(first(ends)) →$(join('₀' + d for d in reverse(digits(k)))) $(last(ends))"
        for (k, ends) in enumerate(J.arrows)), ", ")
    return "FreeCat($(J.n)$(isempty(arrows) ? "" : "; $arrows"))"
end

name(X::OIC{Int, FreeCat}) = string(object(X))

function name(p::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}})
    path = object(p).path
    arrows = category(category(p)).arrows

    # arrow `k` prints as `s → t`, or `s →ₖ t` when another arrow is parallel
    # to it, and a composite as its arrows in parentheses, right to left
    arrowName(k) = count(==(arrows[k]), arrows) == 1 ?
        "$(first(arrows[k])) → $(last(arrows[k]))" :
        "$(first(arrows[k])) →$(join('₀' + d for d in reverse(digits(k)))) $(last(arrows[k]))"
    isempty(path) && return "id"
    length(path) == 1 && return arrowName(only(path))
    return join(("($(arrowName(k)))" for k in reverse(path)), " ∘ ")
end

# every path is monic and epic, since a free category cancels on both sides,
# and only the empty paths are invertible
isMono(::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}) = true
isEpi(::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}) = true
isIso(p::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}) = isempty(object(p).path)

function Base.inv(p::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}; force::Bool=false)
    # an identity, the only isomorphisms of a free category
    if !force && !isIso(p)
        throw(ArgumentError(
            @annotated """
            The path
            $TAB$p
            has no inverse, since the only isomorphisms of a free category \
            are its identities.
            """
        ))
    end
    return p
end

"""
    firstDifference(p, q)

For paths `p, q: X → Y` of a free category, `nothing` when they follow the same
arrows, and otherwise `(path = (), left = p, right = q)`: paths have no
elements to differ at, so they differ as a whole.
"""
function firstDifference(
    p::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}},
    q::OIC{GenericMorphFreeCat, <:Hom{Int, Int, FreeCat}}
)
    return object(p).path == object(q).path ? nothing : (path = (), left = p, right = q)
end

