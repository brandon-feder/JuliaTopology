# =========================================================
# ======================== LIMITS =========================
# =========================================================

"""
    LimitSet(D)

The limit of a diagram `D` of finite sets, as a lazy finite set: its elements
are the `NamedTuple`s `(A = a, B = b, …)` with an element of `D(j)` for each
vertex `j`, such that `D(f)(x_j) == x_k` for each arrow `f: j → k`. Its
elements are computed when it is iterated, not stored. Built by
[`limit`](@ref).
"""
struct LimitSet
    diagram::OIC
end

# The elements of `s`, found by assigning an element to each vertex in turn:
# a vertex reached by an arrow from an assigned vertex is determined by it, and
# any other ranges over its set. Every arrow is checked once both of its ends
# are assigned.
function limitElements(s::LimitSet)
    D = s.diagram
    J = object(domain(category(D)))
    arrows = object(D).arrows

    # the order to assign vertices in, and the arrow determining each, if any
    order, determinedBy = Symbol[], Dict{Symbol, Any}()
    while length(order) < length(J.vertices)
        remaining = [v for v in J.vertices if !(v in order)]
        next = findfirst(v -> any(((a, (s, t)),) -> t == v && s in order,
            pairs(J.arrows)), remaining)
        v = next === nothing ? first(remaining) : remaining[next]
        determinedBy[v] = next === nothing ? nothing :
            findfirst(((s, t),) -> t == v && s in order, J.arrows)
        push!(order, v)
    end

    elements = NamedTuple[]
    assignment = Dict{Symbol, Any}()
    function assign(i)
        if i > length(order)
            push!(elements, NamedTuple{J.vertices}(Tuple(assignment[v]
                for v in J.vertices)))
            return
        end
        v = order[i]
        a = determinedBy[v]
        candidates = a === nothing ? D(J[v]) :
            (arrows[a](assignment[first(J.arrows[a])]),)
        for x in candidates
            assignment[v] = x
            consistent = all(pairs(J.arrows)) do (label, (s, t))
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

function Base.iterate(s::LimitSet, state=(limitElements(s), 1))
    elements, i = state
    i > length(elements) && return nothing
    return elements[i], (elements, i + 1)
end

Base.length(s::LimitSet) = length(limitElements(s))

function Base.in(x, s::LimitSet)
    D = s.diagram
    J = object(domain(category(D)))
    x isa NamedTuple && keys(x) == J.vertices || return false
    for v in J.vertices
        x[v] isa OIC && category(x[v]) == OICAsCat(D(J[v])) || return false
    end
    return all(((label, (j, k)),) -> object(D).arrows[label](x[j]) == x[k],
        pairs(J.arrows))
end

"""
    limit(D)

The limit of a diagram `D` of finite sets, a terminal object of
[`Cone`](@ref)`(D)`: the cone whose apex is the [`LimitSet`](@ref) of `D` and
whose legs are its projections, `p ↦ object(p)[j]`. For any cone `c` over
`D`, `canonicalHom(c, limit(D))` is the unique morphism of cones into it.
"""
function limit(D::OIC{FuncDiagram, <:Hom{FreeCat, CatFinSet, CatCat}})
    J = object(domain(category(D)))
    L = FinSet[LimitSet(D), force=true]
    legs = (; (j => Hom(L, D(J[j]))[p -> object(p)[j], force=true]
        for j in J.vertices)...)
    return Cone(D)[L, legs, force=true]
end

function canonicalHom(c::OIC{ObjComma, <:Cone}, L::OIC{ObjComma, <:Cone})
    D = object(object(category(L).G).value)

    # into a limit of the same diagram
    if category(c) != category(L) || !(object(apex(L)) isa LimitSet) ||
            object(apex(L)).diagram != D
        throw(NoCanonicalHomError(c, L,
            @annotated """
            In a category of cones, a canonical morphism is only defined into \
            a limit of its diagram, built by $(codeclr("limit")), but
            $TAB$L
            is not one.
            """
        ))
    end

    J = object(domain(category(D)))
    elements = OICAsCat(apex(L))
    u = Hom(apex(c), apex(L))[
        x -> elements[(; (j => leg(c, j)(x) for j in J.vertices)...), force=true],
        force=true
    ]
    return Hom(c, L)[u, force=true]
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
    equalizer(f, g)

The equalizer of maps `f, g: X → Y` of finite sets, the [`limit`](@ref) of
[`parallelPair`](@ref)`(f, g)`: a cone whose apex has an element
`(X = x, Y = f(x))` for each `x` with `f(x) == g(x)`.
"""
equalizer(f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}) = limit(parallelPair(f, g))

"""
    pullback(f, g)

The pullback of maps `f: A → C` and `g: B → C` of finite sets, the
[`limit`](@ref) of [`cospan`](@ref)`(f, g)`: a cone whose apex has an element
`(A = a, B = b, C = f(a))` for each `a`, `b` with `f(a) == g(b)`.
"""
pullback(f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}) = limit(cospan(f, g))

"""
    terminal(FinSet)

The terminal finite set, the apex of the limit of the empty diagram, whose
only element is `()`. `canonicalHom(X, terminal(FinSet))` is the unique map
into it.
"""
terminal(::CatFinSet) = apex(limit(diagram(emptyShape(), FinSet)))

# =========================================================
# ======================= COLIMITS ========================
# =========================================================

"""
    CoproductSet(D)

The disjoint union of the sets of a diagram `D` of finite sets, as a lazy
finite set: its elements are `(vertex = j, element = x)` for each vertex `j`
and element `x` of `D(j)`. Built by [`colimit`](@ref).
"""
struct CoproductSet
    diagram::OIC
end

function Base.iterate(s::CoproductSet, state=nothing)
    D = s.diagram
    J = object(domain(category(D)))
    elements, i = state === nothing ?
        ([(vertex = j, element = x) for j in J.vertices for x in D(J[j])], 1) :
        state
    i > length(elements) && return nothing
    return elements[i], (elements, i + 1)
end

function Base.length(s::CoproductSet)
    D = s.diagram
    J = object(domain(category(D)))
    return sum((cardinality(D(J[j])) for j in J.vertices); init=0)
end

function Base.in(x, s::CoproductSet)
    D = s.diagram
    J = object(domain(category(D)))
    return x isa NamedTuple{(:vertex, :element)} && x.vertex in J.vertices &&
        x.element isa OIC && category(x.element) == OICAsCat(D(J[x.vertex]))
end

"""
    QuotientSet(representatives, D)

The colimit of a diagram `D` of finite sets, as the set of one representative
`(vertex = j, element = x)` of each class of the disjoint union of its sets.
The classes themselves are given by the surjection built alongside it in
[`colimit`](@ref).
"""
struct QuotientSet
    representatives::Tuple
    diagram::OIC
end

Base.iterate(s::QuotientSet, i=1) =
    i > length(s.representatives) ? nothing : (s.representatives[i], i + 1)

Base.length(s::QuotientSet) = length(s.representatives)

Base.in(x, s::QuotientSet) = x in s.representatives

"""
    colimit(D)

The colimit of a diagram `D` of finite sets, an initial object of
[`Cocone`](@ref)`(D)`. Its apex is the [`QuotientSet`](@ref) of the disjoint
union of the sets of `D` by the smallest equivalence relating `(j, x)` and
`(k, D(f)(x))` for each arrow `f: j → k`, and its leg at `j` sends `x` to the
class of `(j, x)`. For any cocone `c` under `D`, `canonicalHom(colimit(D), c)`
is the unique morphism of cocones out of it. The classes are computed from the
sets as they are when `colimit` is called, and each call builds a new cocone.
"""
function colimit(D::OIC{FuncDiagram, <:Hom{FreeCat, CatFinSet, CatCat}})
    J = object(domain(category(D)))
    S = FinSet[CoproductSet(D), force=true]
    elements = collect(object(S))
    index = Dict(e => i for (i, e) in enumerate(elements))

    # the classes, relating `(j, x)` and `(k, D(f)(x))` for each `f: j → k`
    classes = IntDisjointSets(length(elements))
    for (label, (j, k)) in pairs(J.arrows)
        for x in D(J[j])
            y = object(D).arrows[label](x)
            union!(classes, index[(vertex = j, element = x)],
                index[(vertex = k, element = y)])
        end
    end

    # the first element of each class represents it
    representative = Dict{Int, Any}()
    for (i, e) in enumerate(elements)
        get!(representative, find_root!(classes, i), e)
    end
    Q = FinSet[QuotientSet(Tuple(unique(representative[find_root!(classes, i)]
        for i in eachindex(elements))), D), force=true]

    # the surjection onto the classes, and the legs through it
    inS, inQ = OICAsCat(S), OICAsCat(Q)
    q = Epi(S, Q)[Dict(inS[e, force=true] =>
        inQ[representative[find_root!(classes, i)], force=true]
        for (i, e) in enumerate(elements)), force=true]
    legs = (; (j => compose(q,
        Mono(D(J[j]), S)[x -> inS[(vertex = j, element = x), force=true],
            force=true])
        for j in J.vertices)...)
    return Cocone(D)[Q, legs, force=true]
end

function canonicalHom(L::OIC{ObjComma, <:Cocone}, c::OIC{ObjComma, <:Cocone})
    D = object(object(category(L).F).value)

    # out of a colimit of the same diagram
    if category(c) != category(L) || !(object(apex(L)) isa QuotientSet) ||
            object(apex(L)).diagram != D
        throw(NoCanonicalHomError(L, c,
            @annotated """
            In a category of cocones, a canonical morphism is only defined \
            out of a colimit of its diagram, built by \
            $(codeclr("colimit")), but
            $TAB$L
            is not one.
            """
        ))
    end

    u = Hom(apex(L), apex(c))[
        r -> leg(c, object(r).vertex)(object(r).element), force=true
    ]
    return Hom(L, c)[u, force=true]
end

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
    coequalizer(f, g)

The coequalizer of maps `f, g: X → Y` of finite sets, the [`colimit`](@ref)
of [`parallelPair`](@ref)`(f, g)`: a cocone whose apex is `Y` divided by the
smallest equivalence relating `f(x)` and `g(x)` for each `x`.
"""
coequalizer(f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}) = colimit(parallelPair(f, g))

"""
    pushout(f, g)

The pushout of maps `f: C → A` and `g: C → B` of finite sets, the
[`colimit`](@ref) of [`span`](@ref)`(f, g)`: a cocone whose apex is the
disjoint union of `A` and `B`, with `f(c)` and `g(c)` identified for each `c`.
"""
pushout(f::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}},
    g::OIC{<:Any, <:HomLike{<:Any, <:Any, CatFinSet}}) = colimit(span(f, g))

"""
    initial(FinSet)

The initial finite set, the apex of the colimit of the empty diagram, which is
empty. `canonicalHom(initial(FinSet), X)` is the unique map out of it.
"""
initial(::CatFinSet) = apex(colimit(diagram(emptyShape(), FinSet)))

# =========================================================
# ============ MAPS INTO TERMINAL, FROM INITIAL ===========
# =========================================================

function canonicalHom(X::OIC{<:Any, CatFinSet}, T::OIC{LimitSet, CatFinSet})
    # into the terminal set
    if T != terminal(FinSet)
        throw(NoCanonicalHomError(X, T,
            @annotated """
            Among finite sets, a canonical morphism is only defined into the \
            terminal set $(codeclr("terminal(FinSet)")) and out of the initial \
            set $(codeclr("initial(FinSet)")), and
            $TAB$T
            is not the terminal set.
            """
        ))
    end
    return Hom(X, T)[_ -> OICAsCat(T)[NamedTuple(), force=true], force=true]
end

function canonicalHom(I::OIC{QuotientSet, CatFinSet}, X::OIC{<:Any, CatFinSet})
    # out of the initial set
    if I != initial(FinSet)
        throw(NoCanonicalHomError(I, X,
            @annotated """
            Among finite sets, a canonical morphism is only defined into the \
            terminal set $(codeclr("terminal(FinSet)")) and out of the initial \
            set $(codeclr("initial(FinSet)")), and
            $TAB$I
            is not the initial set.
            """
        ))
    end
    return Hom(I, X)[Dict(), force=true]
end

function canonicalHom(I::OIC{QuotientSet, CatFinSet}, T::OIC{LimitSet, CatFinSet})
    # the empty map, when `I` is initial, and otherwise the map into `T`
    return I == initial(FinSet) ? Hom(I, T)[Dict(), force=true] :
        invoke(canonicalHom, Tuple{OIC{<:Any, CatFinSet}, OIC{LimitSet, CatFinSet}}, I, T)
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

function name(L::OIC{LimitSet, CatFinSet})
    D = object(L).diagram
    J = object(domain(category(D)))
    isempty(J.vertices) && return "{()}"
    isempty(J.arrows) &&
        return join((shortName(X) for X in object(D).objects), " × ")
    return "lim($(name(D)))"
end

function name(p::OIC{<:NamedTuple, OICAsCat{LimitSet, CatFinSet}})
    return "(" * join(("$j: $(name(x))" for (j, x) in pairs(object(p))), ", ") * ")"
end

function name(S::OIC{CoproductSet, CatFinSet})
    return join((shortName(X) for X in object(object(S).diagram).objects), " ⊔ ")
end

function name(x::OIC{<:NamedTuple, OICAsCat{CoproductSet, CatFinSet}})
    return "$(object(x).vertex): $(name(object(x).element))"
end

function name(Q::OIC{QuotientSet, CatFinSet})
    D = object(Q).diagram
    J = object(domain(category(D)))
    isempty(J.vertices) && return "{}"
    isempty(J.arrows) &&
        return join((shortName(X) for X in object(D).objects), " ⊔ ")
    return "colim($(name(D)))"
end

function name(r::OIC{<:NamedTuple, OICAsCat{QuotientSet, CatFinSet}})
    return "[$(object(r).vertex): $(name(object(r).element))]"
end
