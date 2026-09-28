# =========================================================
# ======================== SHAPES =========================
# =========================================================

"""
    vertices(J)

The objects of a shape `J`, a category diagrams are functors from, as a tuple
of `Symbol`s; with [`generators`](@ref), all that diagrams, functor categories
and limits need to know of `J`. [`FreeCat`](@ref) defines both; any other
category may be used as a shape by defining them too.
"""
function vertices(J::Category)
    throw(InterfaceViolation(
        @annotated """
        The category $J cannot be the shape of a diagram, since it does not \
        list its objects. When appropriate, you may make it a shape by \
        overloading
        $(overloadHint("vertices", ("J", @annotated("the category $J"),
            typeString(typeof(J)))))
        and $(codeclr("generators")).
        """
    ))
end

"""
    generators(J)

The generating arrows of a shape `J`, as a `NamedTuple` sending each label to
`source => target`, both among [`vertices`](@ref)`(J)`. Every morphism of `J`
should be a composite of these: a diagram gives a morphism for each of them,
and a cone need only commute with them.
"""
function generators(J::Category)
    throw(InterfaceViolation(
        @annotated """
        The category $J cannot be the shape of a diagram, since it does not \
        list its generating arrows. When appropriate, you may make it a shape \
        by overloading
        $(overloadHint("generators", ("J", @annotated("the category $J"),
            typeString(typeof(J)))))
        and $(codeclr("vertices")).
        """
    ))
end

"""
    FreeCat(vertices, arrows)

The free category on a finite graph, used as the shape of a diagram. Its
objects are the `vertices`, a collection of `Symbol`s, written `J[:X]`. Its
morphisms are the paths along its `arrows`, given as `label => (source =>
target)` pairs, e.g.

```julia
J = FreeCat((:X, :Y), (f = :X => :Y, g = :X => :Y))
```

# Standardized Interface
- `generator(J, :f)` — the arrow `f` as a morphism
- `compose(q, p)`, `id(J[:X])` — joining paths, and the empty path
- `discreteShape`, `emptyShape`, `parallelPairShape`, `cospanShape`,
  `spanShape` — common shapes

# Interface Specification Assumptions
- `J :: FreeCat`; `p, q` are its morphisms
"""
struct FreeCat <: Category
    vertices::Tuple{Vararg{Symbol}}
    arrows::NamedTuple

    function FreeCat(vertices, arrows)
        vertices = Tuple(vertices)
        arrows = (; arrows...)

        # vertices are distinct `Symbol`s
        if !all(v -> v isa Symbol, vertices) || !allunique(vertices)
            throw(ArgumentError(
                @annotated """
                The vertices of a free category must be distinct `Symbol`s, \
                but they are
                $TAB$(valclr(vertices)).
                """
            ))
        end

        for (label, ends) in pairs(arrows)
            # arrows are `source => target` pairs
            if !(ends isa Pair{Symbol, Symbol})
                throw(ArgumentError(
                    @annotated """
                    The arrow $(valclr(label)) of a free category must be \
                    given as $(codeclr("source => target")), but it is
                    $TAB$(valclr(ends)).
                    """
                ))
            end

            # between vertices
            if !(first(ends) in vertices && last(ends) in vertices)
                throw(ArgumentError(
                    @annotated """
                    The arrow $(valclr(label)) goes from \
                    $(valclr(first(ends))) to $(valclr(last(ends))), which \
                    are not both among the vertices
                    $TAB$(valclr(vertices)).
                    """
                ))
            end

            # labeled apart from the vertices
            if label in vertices
                throw(ArgumentError(
                    @annotated """
                    The label $(valclr(label)) names both a vertex and an \
                    arrow of the free category.
                    """
                ))
            end
        end

        return new(vertices, arrows)
    end
end

"""
    GenericMorphFreeCat(path)

A morphism of a [`FreeCat`](@ref): a path, given as the labels of its arrows in
the order they are followed. The empty path is the identity.
"""
struct GenericMorphFreeCat
    path::Tuple{Vararg{Symbol}}
end

GenericMorphFreeCat(path::AbstractVector) = GenericMorphFreeCat(Tuple(path))

vertices(J::FreeCat) = J.vertices
generators(J::FreeCat) = J.arrows

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj, J::FreeCat)
    # a vertex
    if !(obj isa Symbol && obj in J.vertices)
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


function checkInCategory(morph::GenericMorphFreeCat, H::Hom{Symbol, Symbol, FreeCat})
    J = category(H)
    current = object(domain(H))

    for label in morph.path
        # an arrow of `J`
        if !haskey(J.arrows, label)
            throw(NotInCategory(morph, H,
                @annotated """
                The path $(valclr(morph.path)) is not a morphism in $H, \
                since $(valclr(label)) is not an arrow of $J.
                """
            ))
        end

        # which continues the path
        if first(J.arrows[label]) != current
            throw(NotInCategory(morph, H,
                @annotated """
                The path $(valclr(morph.path)) is not a morphism in $H, \
                since the arrow $(valclr(label)) starts at \
                $(valclr(first(J.arrows[label]))), not at $(valclr(current)), \
                where the path so far ends.
                """
            ))
        end
        current = last(J.arrows[label])
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

The path `path`, a tuple of arrow labels in the order they are followed, as a
morphism in `H = Hom(J[:X], J[:Y])`, e.g. `Hom(J[:A], J[:C])[(:f, :g)]`; `()`
is the identity.
"""
function Base.getindex(
    H::Hom{Symbol, Symbol, FreeCat}, path::Tuple{Vararg{Symbol}}; force::Bool=false
)
    return H[GenericMorphFreeCat(path), force=force]
end

"""
    generator(J::FreeCat, label::Symbol)

The arrow `label` of `J`, as a morphism of `J`.
"""
function generator(J::FreeCat, label::Symbol)
    # an arrow of `J`
    if !haskey(J.arrows, label)
        throw(ArgumentError(
            @annotated """
            $(valclr(label)) is not an arrow of $J.
            """
        ))
    end
    source, target = J.arrows[label]
    return Hom(J[source], J[target])[GenericMorphFreeCat((label,)), force=true]
end

function compose(
    q::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}},
    p::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}}
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

id(X::OIC{Symbol, FreeCat}) = Hom(X, X)[GenericMorphFreeCat(()), force=true]

"""
    discreteShape(labels::Symbol...)

The free category with the vertices `labels` and no arrows, the shape of a
product or coproduct.
"""
discreteShape(labels::Symbol...) = FreeCat(labels, NamedTuple())

"""
    Point

The terminal category, the free category with the single vertex `:pt` and no
arrows. Its only object is `Point[:pt]`, and its only morphism is
`id(Point[:pt])`.
"""
const Point = FreeCat((:pt,), NamedTuple())

"""
    emptyShape()

The free category with no vertices, the shape of a terminal or initial object.
"""
emptyShape() = FreeCat((), NamedTuple())

"""
    parallelPairShape()

The free category on `f, g: X → Y`, the shape of an equalizer or coequalizer.
"""
parallelPairShape() = FreeCat((:X, :Y), (f = :X => :Y, g = :X => :Y))

"""
    cospanShape()

The free category on `f: A → C` and `g: B → C`, the shape of a pullback.
"""
cospanShape() = FreeCat((:A, :B, :C), (f = :A => :C, g = :B => :C))

"""
    spanShape()

The free category on `f: C → A` and `g: C → B`, the shape of a pushout.
"""
spanShape() = FreeCat((:C, :A, :B), (f = :C => :A, g = :C => :B))

# =========================================================
# ======================= PRINTING ========================
# =========================================================

function name(J::FreeCat)
    arrows = join(("$label: $(first(ends)) → $(last(ends))"
        for (label, ends) in pairs(J.arrows)), ", ")
    return "FreeCat($(join(J.vertices, ", "))$(isempty(arrows) ? "" : "; $arrows"))"
end

name(X::OIC{Symbol, FreeCat}) = string(object(X))

function name(p::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}})
    path = object(p).path
    return isempty(path) ? "id" : join(reverse(path), "∘")
end

# every path is monic and epic, since a free category cancels on both sides,
# and only the empty paths are invertible
isMono(::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}}) = true
isEpi(::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}}) = true
isIso(p::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}}) = isempty(object(p).path)

function Base.inv(p::OIC{GenericMorphFreeCat, <:Hom{Symbol, Symbol, FreeCat}}; force::Bool=false)
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
