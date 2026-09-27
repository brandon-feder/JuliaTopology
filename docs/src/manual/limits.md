```@meta
CurrentModule = JuliaTopology
```

# Limits and colimits

## Diagrams

A diagram of shape `J` in `C` is a functor from `J` to `C`, an object of
`Hom(Cat[J], Cat[C])`. Shapes are free categories on finite graphs,
[`FreeCat`](@ref)s, so a diagram assigns an object to each vertex and a
morphism to each arrow ([`FuncDiagram`](@ref)). Since a cone only has to
commute with the arrows, this covers every finite diagram.

- `diagram(J, C; X = …, f = …)` — any shape
- `parallelPair(f, g)`, `cospan(f, g)`, `span(f, g)`, `discrete(X₁, …)` —
  common shapes

The diagrams of shape `J` in `C` form the functor category
[`FunctorCat`](@ref)`(J, C)`, whose morphisms are natural transformations
([`MorphNat`](@ref)), and [`diagonal`](@ref)`(J, C)` is the functor
`Δ: C → [J, C]` sending `X` to the constant diagram at `X`.

## Cones and cocones

`Cone(D)` is the comma category `Δ ↓ D` and `Cocone(D)` is `D ↓ Δ` (see
[Comma categories](comma.md)): a cone is an apex `X` with a leg `X → D(j)` for
each vertex `j`, commuting with the arrows of `D`, and a morphism of cones is a
map of apexes commuting with the legs. A limit is a terminal object of
`Cone(D)`, and a colimit an initial object of `Cocone(D)`.

## Required Interface

None of its own. Checking that a cone commutes, or that a transformation is
natural, needs `compose` and [`firstDifference`](@ref) for the morphisms of
`C`; FinSet has both. Otherwise, pass `force=true`.

## Standardized Interface

- `Cone(D)[(A = legA, …)]`, `Cocone(D)[(A = legA, …)]` — a cone or cocone from
  its legs; `Cone(D)[X, legs]` also names the apex
- `Hom(c₁, c₂)[u]` — the morphism of cones or cocones given by `u`
- `apex(c)`, `legs(c)`, `leg(c, :A)`

For finite sets:

- `limit(D)` — the cone on the set of `NamedTuple`s `(A = a, B = b, …)`
  respecting every arrow, with the projections as legs
- `colimit(D)` — the cocone on the classes of the disjoint union of the sets,
  each shown by a representative `(vertex = j, element = x)`
- `canonicalHom(c, limit(D))`, `canonicalHom(colimit(D), c)` — the unique
  morphisms of cones and cocones
- `product`, `equalizer`, `pullback`, `coproduct`, `coequalizer`, `pushout` —
  limits and colimits of common shapes
- `terminal(FinSet)`, `initial(FinSet)` — the one-point and empty sets, with
  `canonicalHom` into and out of them

## Interface Specification Assumptions

- `J :: FreeCat`; `D` is a diagram of shape `J`
- `c, c₁, c₂` are cones or cocones over `D`

## Basic Example

```julia
A, C = FinSet[1:4], FinSet[[:even, :odd]]
c = @ascat(C)
parity = Hom(A, C)[x -> c[iseven(object(x)) ? :even : :odd]]
E = equalizer(parity, Hom(A, C)[x -> c[:odd]])
collect(apex(E))   # the odd numbers, as (X = x, Y = :odd)
```

See the Limits and colimits tutorial for more.
