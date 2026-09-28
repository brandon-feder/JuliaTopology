```@meta
CurrentModule = JuliaTopology
```

# Limits and colimits

## Diagrams

A diagram of shape `J` in `C` is a functor from `J` to `C`, an object of
`Hom(J, C)`: it assigns an object to each vertex and a morphism to each
generating arrow of `J` ([`FuncDiagram`](@ref)). A shape is any category
listing its objects and generating arrows, by [`vertices`](@ref) and
[`generators`](@ref); a cone only has to commute with the generators, so this
is all diagrams, functor categories and limits use. The usual shapes are free
categories on finite graphs, [`FreeCat`](@ref)s; another category becomes a
shape by defining the two functions:

```julia
struct WalkingArrow <: Category end          # A --f--> B
JuliaTopology.vertices(::WalkingArrow) = (:A, :B)
JuliaTopology.generators(::WalkingArrow) = (f = :A => :B,)
```

- `diagram(J; X = …, f = …)`, `diagram(J, C; …)` — any shape, in the category
  of its objects or in `C`
- `D(:X)`, `D(:f)`, `shape(D)` — the object or morphism at a label, and the
  shape of `D`
- `parallelPair(f, g)`, `cospan(f, g)`, `span(f, g)`, `discrete(X₁, …)` —
  common shapes

The diagrams of shape `J` in `C` form the functor category
[`FunctorCat`](@ref)`(J, C)`. Its morphisms, natural transformations, are
themselves diagrams of shape `J` in the arrow category
[`arrowCategory`](@ref)`(C)`: a component `η_j` at each vertex and a
commuting square at each arrow, so naturality is checked as the squares are
built. [`diagonal`](@ref)`(J, C)` is the functor `Δ: C → [J, C]`, sending `X`
to `constant(X) ∘ toPoint(J)`.

Functors compose (`G ∘ F`); a diagram followed by a functor is again a diagram,
and [`mapCone`](@ref)`(F, c)` carries a cone over `D` to one over `F ∘ D`.

## Cones and cocones

`Cone(D)` is the comma category `Δ ↓ D` (see [Comma categories](comma.md)): a
cone is an apex `X` with a leg `X → D(j)` for each vertex `j`, commuting with
the arrows of `D`, and a morphism of cones is a map of apexes commuting with
the legs. A cocone is a cone in the opposite category,
`Cocone(D) == Op(Cone(op(D)))` (see [Opposite categories](opposite.md)). A
limit is a terminal object of `Cone(D)`, and a colimit an initial object of
`Cocone(D)`: `limit(D) == terminal(Cone(D))` and
`colimit(D) == initial(Cocone(D))`. A terminal object of a comma category is a
universal arrow ([`universalArrow`](@ref)), and `terminal` is the one
construction the rest are built from.

## Required Interface

None of its own. Checking that a cone commutes, or that a transformation is
natural, needs `compose` and [`firstDifference`](@ref) for the morphisms of
`C`; FinSet has both. Otherwise, pass `force=true`.

## Standardized Interface

- `Cone(D)[(A = legA, …)]`, `Cocone(D)[(A = legA, …)]` — a cone or cocone from
  its legs; `Cone(D)[X, legs]` also names the apex
- `Hom(c₁, c₂)[u]` — the morphism of cones or cocones given by `u`
- `apex(c)`, `legs(c)`, `leg(c, :A)`, `diagram(K)` for `K = Cone(D)`
- `apexMorphism(m)` — the map of apexes of a morphism of cones or cocones

For finite sets:

- `limit(D)` — the cone on the set of cones over `D` from the one-point set,
  [`pointCones`](@ref)`(D)`: the `NamedTuple`s `(A = a, B = b, …)` respecting
  every arrow, with the projections as legs
- `colimit(D)` — the cocone on the connected components of the category of
  elements [`∫`](@ref)`(D)`, each shown by a representative
  `(vertex = j, element = x)`: the codomain of its quotient map
  [`componentMap`](@ref), which sends each `(j, x)` to its component; the
  members of a component are its [`fiber`](@ref)
- `canonicalHom(c, L)`, `canonicalHom(L, c)` — the unique morphism of cones
  into `L`, or of cocones out of it, found from the legs; it exists for every
  `c` exactly when `L` is a limit or colimit, however it was built
- `product`, `equalizer`, `pullback`, `coproduct`, `coequalizer`, `pushout` —
  limits and colimits of common shapes
- `terminal(FinSet)`, `initial(FinSet)` — a one-point and the empty set;
  `canonicalHom(X, Y)` is the unique map into any one-element set or out of
  any empty set

The apex of a limit or colimit is computed once, from the sets as they are
when it is built; its legs and universal morphisms are computed on lookup.

## Interface Specification Assumptions

- `J :: FreeCat`; `D` is a diagram of shape `J`
- `c, c₁, c₂` are cones or cocones over `D`

## Basic Example

```julia
A, C = FinSet[1:4], FinSet[[:even, :odd]]
c = ascat(C)
parity = Hom(A, C)[x -> iseven(x) ? :even : :odd, values=true]
E = equalizer(parity, Hom(A, C)[x -> c[:odd]])
collect(apex(E))   # the odd numbers, as (X = x, Y = :odd)
```

See the Limits and colimits tutorial for more.
