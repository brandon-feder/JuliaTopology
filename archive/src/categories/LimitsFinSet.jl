# =========================================================
# ======================== LIMITS =========================
# =========================================================

# Cone categories whose diagrams land in `C`, for dispatch
const ConeIn{C} = Comma{<:OIC{FuncDiagonal, <:Hom{C}}, <:OIC{FuncDiagram}}

"""
    pointCones(D)

The cones over a diagram `D` of finite sets from the one-point set, each given
by where its legs send the point: the `NamedTuple`s with an element of `D(j)`
for each vertex `j` such that `D(f)(x_j) == x_k` for each arrow `f: j → k`.
These are the elements of the limit of `D`, since `lim D ≅ Hom(1, lim D)` is
the set of cones from `1`. They are found by choosing an element for each
vertex in turn: a vertex reached by an arrow from a chosen vertex is
determined by it, and any other ranges over its set.
"""
function pointCones(D)
    J = shape(D)
    arrows = object(D).arrows

    # the order to assign vertices in, and the arrow determining each, if any
    order, determinedBy = Symbol[], Dict{Symbol, Any}()
    while length(order) < length(vertices(J))
        remaining = [v for v in vertices(J) if !(v in order)]
        next = findfirst(v -> any(((a, (s, t)),) -> t == v && s in order,
            pairs(generators(J))), remaining)
        v = next === nothing ? first(remaining) : remaining[next]
        determinedBy[v] = next === nothing ? nothing :
            findfirst(((s, t),) -> t == v && s in order, generators(J))
        push!(order, v)
    end

    elements = NamedTuple[]
    assignment = Dict{Symbol, Any}()
    function assign(i)
        if i > length(order)
            push!(elements, NamedTuple{vertices(J)}(Tuple(assignment[v]
                for v in vertices(J))))
            return
        end
        v = order[i]
        a = determinedBy[v]
        candidates = a === nothing ? D(v) :
            (arrows[a](assignment[first(generators(J)[a])]),)
        for x in candidates
            assignment[v] = x
            consistent = all(pairs(generators(J))) do (label, (s, t))
                !(v in (s, t)) || !haskey(assignment, s) ||
                    !haskey(assignment, t) ||
                    arrows[label](assignment[s]) == assignment[t]
            end
            consistent && assign(i + 1)
        end
        delete!(assignment, v)
    end
    assign(1)
    return elements
end

"""
    limit(D)

The limit of a diagram `D`, a terminal object of [`Cone`](@ref)`(D)`, i.e.
`terminal(Cone(D))`: the universal cone over `D`, through which every other
cone factors uniquely, by `canonicalHom(c, limit(D))`.
"""
limit(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = terminal(Cone(D))

"""
    terminal(K)

A terminal object of the category `K`: for a category of cones, a limit; for
a category of cocones (the opposite of one of cones), a colimit; for a slice,
the identity. Terminal objects of comma categories are universal arrows, so
this is the one universal construction the others are built from.

For cones over a diagram `D` of finite sets, the apex of the terminal cone is
the set of [`pointCones`](@ref) of `D`, i.e. of `NamedTuple`s
`(A = a, B = b, …)` respecting every arrow, and its legs are the projections
`p ↦ object(p)[j]`. For a diagram without arrows, a product, the apex is
`Iterators.product` of its sets, whose elements are only made when iterated;
otherwise it is computed once, from the sets as they are when it is built.
"""
function terminal(K::ConeIn{CatFinSet})
    D = diagram(K)
    J = shape(D)
    elements = isempty(generators(J)) ?
        Iterators.map(NamedTuple{vertices(J)},
            Iterators.product((D(v) for v in vertices(J))...)) :
        pointCones(D)
    L = FinSet[elements, force=true]
    legs = (; (j => Hom(L, D(j))[p -> object(p)[j], force=true]
        for j in vertices(J))...)
    return K[L, legs, force=true]
end

"""
    universalArrow(K)

The universal arrow of a comma category `K`, i.e. its terminal object, see
[`terminal`](@ref).
"""
universalArrow(K::Comma) = terminal(K)

# the terminal objects of other cone categories are not computed
function terminal(K::Cone)
    throw(InterfaceViolation(
        @annotated """
        A terminal object of $K, i.e. a limit, can only be computed for \
        diagrams of finite sets and their opposites. When appropriate, you may \
        compute it for other diagrams by overloading
        $(overloadHint("terminal", ("K", @annotated("the category of cones $K"),
            typeString(typeof(K)))))
        """
    ))
end

"""
    canonicalHom(c, L)

For cones `c` and `L` over the same diagram of finite sets, the unique
morphism of cones from `c` to `L`: the map sending each `x` in the apex of `c`
to the one `p` in the apex of `L` with `leg(L, j)(p) == leg(c, j)(x)` for
every vertex `j`. Throws a `NoCanonicalHomError` unless there is exactly one
such `p` for each `x`, as there is when `L` is a limit, e.g. built by
[`limit`](@ref).
"""
function canonicalHom(c::OIC{GenericComma, <:Cone}, L::OIC{GenericComma, <:Cone})
    # over the same diagram
    if category(c) != category(L)
        throw(NoCanonicalHomError(c, L,
            @annotated """
            A canonical morphism of cones is only defined between cones over \
            the same diagram, but
            $TAB$c
            and
            $TAB$L
            are cones over different diagrams.
            """
        ))
    end

    C = category(L).F |> category |> domain |> object

    # of finite sets, or of their opposites, i.e. cocones of finite sets
    if !(C isa Union{CatFinSet, Op{CatFinSet}})
        throw(NoCanonicalHomError(c, L,
            @annotated """
            Canonical morphisms of cones are only computed for diagrams of \
            finite sets and their opposites, but these cones are in \
            $(category(L)).
            """
        ))
    end

    # a morphism of cones in `Op(FinSet)` is a map of finite sets from the
    # apex of `L` to that of `c`, fixed where the legs of `L` reach
    C isa Op && return op(dualCanonicalHom(op(L), op(c)))

    J = object(category(L).F).shape
    legValues(p, cone) = (; (j => leg(cone, j)(p) for j in vertices(J))...)

    # the elements of `L`'s apex, by the values of the legs at them
    atValues = Dict{Any, Vector{Any}}()
    for p in apex(L)
        push!(get!(atValues, legValues(p, L), Any[]), p)
    end

    for x in apex(c)
        matches = get(atValues, legValues(x, c), Any[])

        # something to send `x` to
        if isempty(matches)
            throw(NoCanonicalHomError(c, L,
                @annotated """
                There is no morphism of cones from
                $TAB$c
                to
                $TAB$L
                since no element of the apex of the second has the same leg \
                values as the element $(objclr(name(x))) of the first.
                """
            ))
        end

        # only one thing
        if length(matches) > 1
            throw(NoCanonicalHomError(c, L,
                @annotated """
                There is no unique morphism of cones from
                $TAB$c
                to
                $TAB$L
                since the element $(objclr(name(x))) of the apex of the first \
                could be sent to any of \
                $(join((objclr(name(p)) for p in matches), ", ")).
                """
            ))
        end
    end

    u = Hom(apex(c), apex(L))[x -> only(atValues[legValues(x, c)]), force=true]
    return Hom(c, L)[u, force=true]
end

# For cocones `L` and `c` under the same diagram of finite sets, the unique
# morphism of cocones from `L` to `c`: the map sending `leg(L, j)(x)` to
# `leg(c, j)(x)` for every vertex `j` and element `x`, if it is one. This is
# the canonical morphism of cones in `Op(FinSet)`, from `op(c)` to `op(L)`.
function dualCanonicalHom(L, c)
    D = diagram(category(L))

    # where each element of `L`'s apex must go, as fixed by the legs
    target = Dict{Any, Any}()
    for j in vertices(shape(D)), x in D(j)
        r, y = leg(L, j)(x), leg(c, j)(x)

        # consistently
        if haskey(target, r) && target[r] != y
            throw(NoCanonicalHomError(L, c,
                @annotated """
                There is no morphism from
                $TAB$L
                to
                $TAB$c
                commuting with their legs, since the element \
                $(objclr(name(r))) of the first would have to be sent to both \
                $(objclr(name(target[r]))) and $(objclr(name(y))).
                """
            ))
        end
        target[r] = y
    end

    # elements no leg reaches can only go to the single element, if any
    unreached = [r for r in apex(L) if !haskey(target, r)]
    if !isempty(unreached)
        if cardinality(apex(c)) != 1
            throw(NoCanonicalHomError(L, c,
                @annotated """
                There is no unique morphism from
                $TAB$L
                to
                $TAB$c
                commuting with their legs, since no leg reaches the element \
                $(objclr(name(first(unreached)))) of the first, which could be \
                sent to any element of the second.
                """
            ))
        end
        for r in unreached
            target[r] = only(apex(c))
        end
    end

    u = Hom(apex(L), apex(c))[r -> target[r], force=true]
    return Hom(L, c)[u, force=true]
end

"""
    product(X₁, X₂, …)
    product(; A = X₁, B = X₂, …)

The product of finite sets, the [`limit`](@ref) of [`discrete`](@ref)`(…)`: a
cone whose apex has the elements `(X1 = x₁, X2 = x₂, …)`, or
`(A = x₁, B = x₂, …)`, and whose legs are the projections.
"""
product(objects::OIC{<:Any, CatFinSet}...; kwargs...) =
    limit(discrete(objects...; kwargs...))

"""
    A × B

The product of finite sets `A` and `B` as a set, the apex of
[`product`](@ref)`(A, B)`.
"""
×(A::OIC{<:Any, CatFinSet}, B::OIC{<:Any, CatFinSet}) = apex(product(A, B))

"""
    equalizer(f, g)

The equalizer of maps `f, g: X → Y` of finite sets, the [`limit`](@ref) of
[`parallelPair`](@ref)`(f, g)`: a cone whose apex has an element
`(X = x, Y = f(x))` for each `x` with `f(x) == g(x)`.
"""
equalizer(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}) = limit(parallelPair(f, g))

"""
    pullback(f, g)

The pullback of maps `f: A → C` and `g: B → C` of finite sets, the
[`limit`](@ref) of [`cospan`](@ref)`(f, g)`: a cone whose apex has an element
`(A = a, B = b, C = f(a))` for each `a`, `b` with `f(a) == g(b)`.
"""
pullback(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}) = limit(cospan(f, g))


"""
    terminal(C::Category)

A terminal object of `C`, the apex of the limit of the empty diagram in `C`,
e.g. the one-point set for `C = FinSet`. `canonicalHom(X, T)` is the unique
morphism into it.
"""
terminal(C::Category) = apex(limit(diagram(emptyShape(), C)))

# =========================================================
# ======================= COLIMITS ========================
# =========================================================

"""
    CategoryOfElements(D)
    ∫(D)

The category of elements `∫D` of a diagram `D` of finite sets: its objects are
the pairs `(vertex = j, element = x)` with `x` an element of `D(j)`, and it is
generated by an arrow `(j, x) → (k, D(f)(x))` for each arrow `f: j → k` of the
shape and element `x`. For a single set `X`, it is the discrete category
`ascat(X)`. Its objects form a set, [`objectSet`](@ref), and its connected
components are the colimit of `D`, see [`componentMap`](@ref) and
[`π₀`](@ref).
"""
struct CategoryOfElements{DT} <: Category
    diagram::DT
end

"""
    ∫(D)

The category of elements of a diagram `D` of finite sets, see
[`CategoryOfElements`](@ref).
"""
∫(D::OIC{FuncDiagram, <:Hom{<:Any, CatFinSet, CatCat}}) = CategoryOfElements(D)

function checkInCategory(obj, E::CategoryOfElements)
    D = E.diagram

    # a pair of a vertex and one of its elements
    if !(obj isa NamedTuple{(:vertex, :element)} && obj.vertex in vertices(shape(D)) &&
            obj.element isa OIC && category(obj.element) == OICAsCat(D(obj.vertex)))
        throw(NotInCategory(obj, E,
            @annotated """
            The value
            $TAB$(valclr(obj))
            is not an object of $E, whose objects are the pairs \
            $(codeclr("(vertex = j, element = x)")) of a vertex and an \
            element of its set.
            """
        ))
    end
    return true
end

# a small category's objects form a set: those of `E` are its pairs `(j, x)`,
# listed vertex by vertex
function Base.iterate(E::CategoryOfElements, state=nothing)
    D = E.diagram
    members, i = state === nothing ?
        ([(vertex = j, element = x) for j in vertices(shape(D)) for x in D(j)], 1) :
        state
    i > length(members) && return nothing
    return members[i], (members, i + 1)
end

Base.length(E::CategoryOfElements) =
    sum((cardinality(E.diagram(j)) for j in vertices(shape(E.diagram))); init=0)

"""
    objectSet(E::CategoryOfElements)

The objects of the category of elements `E = ∫D`, as a finite set: the
disjoint union of the sets of `D`, whose elements are the pairs
`(vertex = j, element = x)`.
"""
objectSet(E::CategoryOfElements) = FinSet[E, force=true]

# The first member of the component of each object of `E`, found by
# union-find along the generating arrows `(j, x) → (k, D(f)(x))`
function componentRepresentatives(E::CategoryOfElements)
    D = E.diagram
    members = collect(E)
    index = Dict(m => i for (i, m) in enumerate(members))
    classes = IntDisjointSets(length(members))
    for (label, (j, k)) in pairs(generators(shape(D))), x in D(j)
        union!(classes, index[(vertex = j, element = x)],
            index[(vertex = k, element = D(label)(x))])
    end
    first = Dict{Int, Any}()
    for (i, m) in enumerate(members)
        get!(first, find_root!(classes, i), m)
    end
    return Dict(m => first[find_root!(classes, i)] for (i, m) in enumerate(members))
end

"""
    componentMap(E::CategoryOfElements)

The quotient map of the category of elements `E = ∫D` onto its connected
components, a surjection from [`objectSet`](@ref)`(E)` to [`π₀`](@ref)`(E)`:
it sends each object `(j, x)` to its component, shown by the first member of
the component. Two objects are connected exactly when they have the same
image, and the members of a component are its [`fiber`](@ref). The components
are computed once, from the sets as they are when it is called.
"""
function componentMap(E::CategoryOfElements)
    representative = componentRepresentatives(E)
    S = objectSet(E)
    Q = FinSet[unique(values(representative)) |> collect, force=true]
    return Hom(S, Q)[o -> OICAsCat(Q)[representative[object(o)], force=true], force=true]
end

"""
    π₀(E::CategoryOfElements)

The set of connected components of `E`, each shown by its first member: the
codomain of [`componentMap`](@ref)`(E)`. Each call computes it anew, so to use
it with the map, take `codomain(category(componentMap(E)))`.
"""
π₀(E::CategoryOfElements) = codomain(category(componentMap(E)))

"""
    colimit(D)

The colimit of a diagram `D`, an initial object of [`Cocone`](@ref)`(D)`,
i.e. `initial(Cocone(D))`: the universal cocone under `D`, through which every
other cocone factors uniquely, by `canonicalHom(colimit(D), c)`. Since a
cocone is a cone in the opposite category, this is `op` of the terminal cone
over `op(D)`.

For finite sets, the apex is the set of connected components of the category
of elements [`∫`](@ref)`(D)`, each shown by a representative
`(vertex = j, element = x)`, and the leg at `j` is the inclusion of `D(j)` into
the disjoint union of the sets followed by [`componentMap`](@ref)`(∫D)`, which
sends `(j, x)` to its component. It is computed once, from the sets as they are when it is built.
"""
colimit(D::OIC{FuncDiagram, <:Hom{<:Any, <:Any, CatCat}}) = initial(Cocone(D))

# a terminal cone over a diagram of opposites of finite sets is the opposite
# of a colimit of those sets: the components of their category of elements
function terminal(K::ConeIn{Op{CatFinSet}})
    D = op(diagram(K))

    # the disjoint union of the sets of `D`, followed by the quotient onto the
    # components of `∫D`
    q = componentMap(∫(D))
    S, Q = domain(category(q)), codomain(category(q))
    legs = (; (j => compose(q, Hom(D(j), S)[
            x -> OICAsCat(S)[(vertex = j, element = x), force=true], force=true])
        for j in vertices(shape(D)))...)
    return K[op(Q), map(op, legs), force=true]
end

name(E::CategoryOfElements) = "∫$(name(E.diagram))"

"""
    coproduct(X₁, X₂, …)
    coproduct(; A = X₁, B = X₂, …)

The coproduct of finite sets, the [`colimit`](@ref) of
[`discrete`](@ref)`(…)`: a cocone whose apex is their disjoint union and whose
legs are the inclusions.
"""
coproduct(objects::OIC{<:Any, CatFinSet}...; kwargs...) =
    colimit(discrete(objects...; kwargs...))

"""
    A ⊔ B

The disjoint union of finite sets `A` and `B` as a set, the apex of
[`coproduct`](@ref)`(A, B)`.
"""
⊔(A::OIC{<:Any, CatFinSet}, B::OIC{<:Any, CatFinSet}) = apex(coproduct(A, B))

"""
    coequalizer(f, g)

The coequalizer of maps `f, g: X → Y` of finite sets, the [`colimit`](@ref)
of [`parallelPair`](@ref)`(f, g)`: a cocone whose apex is `Y` divided by the
smallest equivalence relating `f(x)` and `g(x)` for each `x`.
"""
coequalizer(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}) = colimit(parallelPair(f, g))

"""
    pushout(f, g)

The pushout of maps `f: C → A` and `g: C → B` of finite sets, the
[`colimit`](@ref) of [`span`](@ref)`(f, g)`: a cocone whose apex is the
disjoint union of `A` and `B`, with `f(c)` and `g(c)` identified for each `c`.
"""
pushout(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}) = colimit(span(f, g))

"""
    initial(C::Category)

An initial object of `C`, the apex of the colimit of the empty diagram in `C`,
e.g. the empty set for `C = FinSet`. `canonicalHom(I, X)` is the unique
morphism out of it.
"""
initial(C::Category) = apex(colimit(diagram(emptyShape(), C)))

# =========================================================
# ================= UNIQUE MAPS OF SETS ===================
# =========================================================

"""
    canonicalHom(X, Y)

For finite sets `X` and `Y`, the unique map from `X` to `Y`, which exists when
`Y` has one element (e.g. [`terminal`](@ref)`(FinSet)`) or `X` has none (e.g.
[`initial`](@ref)`(FinSet)`). Throws a `NoCanonicalHomError` otherwise.
"""
function canonicalHom(X::OIC{<:Any, CatFinSet}, Y::OIC{<:Any, CatFinSet})
    # out of an empty set
    cardinality(X) == 0 && return object(only(homSet(X, Y)))

    # into a one-element set
    if cardinality(Y) != 1
        throw(NoCanonicalHomError(X, Y,
            @annotated """
            There is no unique map from
            $TAB$X
            to
            $TAB$Y
            since it has $(cardinality(X)) elements and the second has \
            $(cardinality(Y)). A map of finite sets is unique only into a \
            one-element set or out of the empty set.
            """
        ))
    end
    return object(only(homSet(X, Y)))
end

# =========================================================
# =================== GLOBAL ELEMENTS =====================
# =========================================================

"""
    globalElement(x)

The element `x` of a finite set `X` as a morphism `1 → X` from the terminal set
[`terminal`](@ref)`(FinSet)`, picking out `x`. The elements of `X` and the maps
`1 → X` correspond exactly; [`element`](@ref) goes back, and a map `f: X → Y`
applied to a global element composes with it, agreeing with
`globalElement(f(x))` (see [`firstDifference`](@ref)).
"""
function globalElement(x::OIC{<:Any, <:OICAsCat{<:Any, CatFinSet}})
    return Hom(terminal(FinSet), oic(category(x)))[_ -> x, force=true]
end

"""
    element(p)

The element picked out by a morphism `p: T → X` of finite sets from a
one-element set `T`, such as a [`globalElement`](@ref).
"""
function element(p::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}})
    T = domain(category(p))

    # from a one-element set
    if cardinality(T) != 1
        throw(ArgumentError(
            @annotated """
            The map
            $TAB$p
            does not pick out an element, since its domain has \
            $(cardinality(T)) elements rather than one.
            """
        ))
    end
    return p(only(T))
end

# a map applied to a morphism into its domain, e.g. a global element, composes
# with it
function (f::OIC{GenericMorphFinSet, <:Hom{DomT, <:Any, CatFinSet}})(
    p::OIC{<:Any, <:Hom{<:Any, DomT, CatFinSet}}
) where DomT
    return compose(f, p)
end

# =========================================================
# ======================= HOM-SETS ========================
# =========================================================

"""
    HomSet(A, B)

The set of all maps from the finite set `A` to `B`, as a lazy finite set:
there are `|B|^|A|` of them, each made only when iterated. Build it as a
FinSet object with [`homSet`](@ref).
"""
struct HomSet
    domain::OIC
    codomain::OIC
end

function Base.iterate(h::HomSet, state=nothing)
    if state === nothing
        xs = collect(h.domain)
        choices = Iterators.product((collect(h.codomain) for _ in xs)...)
        next = iterate(choices)
    else
        xs, choices, rest = state
        next = iterate(choices, rest)
    end
    next === nothing && return nothing
    ys, rest = next
    f = Hom(h.domain, h.codomain)[Dict(zip(xs, ys)), force=true]
    return f, (xs, choices, rest)
end

function Base.length(h::HomSet)
    n = 1
    for _ in 1:cardinality(h.domain)
        n = Base.checked_mul(n, cardinality(h.codomain))
    end
    return n
end

Base.in(f, h::HomSet) = f isa OIC && category(f) == Hom(h.domain, h.codomain)

"""
    homSet(A, B)

The finite set of all maps from `A` to `B`, whose elements are the morphisms
of `Hom(A, B)`, so that `f in homSet(A, B)` for any of them. Its elements are
made only when iterated. With it, FinSet is cartesian closed: see
[`evaluation`](@ref), [`curry`](@ref) and [`uncurry`](@ref). The maps from the
one-point set are the elements of `B`, see [`globalElement`](@ref), and the
unique map of [`canonicalHom`](@ref) is the only element of a hom-set with
one.
"""
homSet(A::OIC{<:Any, CatFinSet}, B::OIC{<:Any, CatFinSet}) = FinSet[HomSet(A, B), force=true]

"""
    evaluation(A, B)

The evaluation map `homSet(A, B) × A → B`, sending `(f, a)` to `f(a)`.
"""
function evaluation(A::OIC{<:Any, CatFinSet}, B::OIC{<:Any, CatFinSet})
    return Hom(homSet(A, B) × A, B)[p -> object(object(p).X1)(object(p).X2), force=true]
end

"""
    curry(f, C, A)

For a map `f: C × A → B`, the map `C → homSet(A, B)` sending `c` to
`a ↦ f(c, a)`. [`uncurry`](@ref) undoes it.
"""
function curry(
    f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}, C::OIC{<:Any, CatFinSet},
    A::OIC{<:Any, CatFinSet}
)
    P, B = domain(category(f)), codomain(category(f))

    # from the product of `C` and `A`
    if P != C × A
        throw(ArgumentError(
            @annotated """
            The map
            $TAB$f
            cannot be curried along $C and $A, since its domain is not \
            $(codeclr("C × A")).
            """
        ))
    end

    H = homSet(A, B)
    return Hom(C, H)[c -> OICAsCat(H)[Hom(A, B)[
            a -> f(OICAsCat(P)[(X1 = c, X2 = a), force=true]), force=true],
        force=true], force=true]
end

"""
    uncurry(g, A)

For a map `g: C → homSet(A, B)`, the map `C × A → B` sending `(c, a)` to
`g(c)(a)`; it undoes [`curry`](@ref).
"""
function uncurry(g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}, A::OIC{<:Any, CatFinSet})
    C, H = domain(category(g)), codomain(category(g))

    # into a hom-set out of `A`
    if !(object(H) isa HomSet && object(H).domain == A)
        throw(ArgumentError(
            @annotated """
            The map
            $TAB$g
            cannot be uncurried along $A, since it does not land in a set of \
            maps out of $A.
            """
        ))
    end

    B = object(H).codomain
    return Hom(C × A, B)[p -> object(g(object(p).X1))(object(p).X2), force=true]
end

# =========================================================
# ================ REPRESENTABLE FUNCTORS =================
# =========================================================

"""
    FuncHomFrom(X)

The covariant hom-functor `Hom(X, -): FinSet → FinSet`, sending a set `Y` to
[`homSet`](@ref)`(X, Y)` and a map `g: Y → Z` to `f ↦ g ∘ f`. Build it with
[`homFrom`](@ref).
"""
struct FuncHomFrom
    object::OIC
end

"""
    FuncHomTo(X)

The contravariant hom-functor `Hom(-, X): FinSetᵒᵖ → FinSet`, sending
`op(Y)` to [`homSet`](@ref)`(Y, X)` and `op(g)`, for `g: Y → Z`, to
`f ↦ f ∘ g`. Build it with [`homTo`](@ref).
"""
struct FuncHomTo
    object::OIC
end

checkInCategory(::FuncHomFrom, ::Hom{CatFinSet, CatFinSet, CatCat}) = true
checkInCategory(::FuncHomTo, ::Hom{Op{CatFinSet}, CatFinSet, CatCat}) = true

"""
    homFrom(X)

The representable functor `Hom(X, -)`, see [`FuncHomFrom`](@ref).
"""
homFrom(X::OIC{<:Any, CatFinSet}) = Hom(FinSet, FinSet)[FuncHomFrom(X)]

"""
    homTo(X)

The representable functor `Hom(-, X)` from the opposite of FinSet, see
[`FuncHomTo`](@ref).
"""
homTo(X::OIC{<:Any, CatFinSet}) = Hom(Op(FinSet), FinSet)[FuncHomTo(X)]

(F::OIC{FuncHomFrom, <:Hom{CatFinSet, CatFinSet, CatCat}})(Y::OIC{<:Any, CatFinSet}) =
    homSet(object(F).object, Y)

function (F::OIC{FuncHomFrom, <:Hom{CatFinSet, CatFinSet, CatCat}})(
    g::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}
)
    X = object(F).object
    Y, Z = domain(category(g)), codomain(category(g))
    target = F(Z)
    return Hom(F(Y), target)[
        f -> OICAsCat(target)[compose(g, object(f)), force=true], force=true]
end

(F::OIC{FuncHomTo, <:Hom{Op{CatFinSet}, CatFinSet, CatCat}})(Y::OIC{<:Any, Op{CatFinSet}}) =
    homSet(op(Y), object(F).object)

function (F::OIC{FuncHomTo, <:Hom{Op{CatFinSet}, CatFinSet, CatCat}})(
    m::OIC{<:Any, <:Hom{<:Any, <:Any, Op{CatFinSet}}}
)
    g = op(m)
    Y, Z = domain(category(g)), codomain(category(g))
    target = F(op(Y))
    return Hom(F(op(Z)), target)[
        f -> OICAsCat(target)[compose(object(f), g), force=true], force=true]
end

name(F::OIC{FuncHomFrom, <:Hom{CatFinSet, CatFinSet, CatCat}}) =
    "Hom($(shortName(object(F).object)), -)"
name(F::OIC{FuncHomTo, <:Hom{Op{CatFinSet}, CatFinSet, CatCat}}) =
    "Hom(-, $(shortName(object(F).object)))"
name(H::OIC{HomSet, CatFinSet}) =
    "homSet($(shortName(object(H).domain)), $(shortName(object(H).codomain)))"

# =========================================================
# ================== IMAGE FACTORIZATION ==================
# =========================================================

"""
    image(f)

The image of a map `f: A → B` of finite sets, the set of values of `f`: the
object through which [`imageFactorization`](@ref) factors `f`.
"""
image(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}) =
    FinSet[unique(object(f(x)) for x in domain(category(f))), force=true]

"""
    fiber(f, y)

The fiber of a map `f: A → B` of finite sets over an element `y` of `B`: the
pullback of `f` along the map `1 → B` picking out `y`, i.e.
`pullback(f, globalElement(y))`. Its apex has an element `(A = x, …)` for each
`x` that `f` sends to `y`, and its leg at `:A` is the inclusion of the fiber
into `A`. For example, the fibers of [`componentMap`](@ref) are the
components.
"""
fiber(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}}, y::OIC{<:Any, <:OICAsCat{<:Any, CatFinSet}}) =
    pullback(f, globalElement(y))

"""
    imageFactorization(f)

The factorization of a map `f: A → B` of finite sets through its
[`image`](@ref) `I`, as `(epi = e, mono = m)`: the surjection `e: A → I`
sending `a` to `f(a)`, and the inclusion `m: I → B`, with `m ∘ e == f`.
"""
function imageFactorization(f::OIC{<:Any, <:Hom{<:Any, <:Any, CatFinSet}})
    A, B = domain(category(f)), codomain(category(f))
    I = image(f)
    e = Hom(A, I)[x -> OICAsCat(I)[object(f(x)), force=true], force=true]
    m = Hom(I, B)[i -> OICAsCat(B)[object(i), force=true], force=true]
    return (epi = e, mono = m)
end

