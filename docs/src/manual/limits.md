```@meta
CurrentModule = JuliaTopology
```

# Limits and colimits

## Diagrams

A diagram of shape `J` in `C` is a functor from `J` to `C`, an object of
`Hom(J, C)`: it assigns an object to each vertex and a morphism to each
generating arrow of `J` ([`FuncDiagram`](@ref)). A shape is any category
counting its objects and listing its generating arrows, by
[`nvertices`](@ref) and [`generators`](@ref): its vertices are `1:n`, and arrow
`k` is the pair `generators(J)[k] == s => t`. A cone only has to commute with
the generators, so this is all diagrams, functor categories and limits use.
The usual shapes are free categories on finite graphs, [`FreeCat`](@ref)s;
another category becomes a shape by defining the two functions:

```julia
struct WalkingArrow <: Category end          # 1 --> 2
JuliaTopology.nvertices(::WalkingArrow) = 2
JuliaTopology.generators(::WalkingArrow) = (1 => 2,)
```

- `diagram(J, (X₁, …), (f₁, …))`, `diagram(J, C, (X₁, …), (f₁, …))` — any
  shape, with the object at each vertex and the morphism at each arrow, in the
  category of its objects or in `C`
- `objects(D)`, `arrows(D)`, `D(J[i])`, `shape(D)` — the objects and morphisms
  of `D` by position, the object at a vertex, and the shape of `D`
- `parallelPair(f, g)`, `cospan(f, g)`, `span(f, g)`, `discrete(X₁, …)` —
  common shapes

The functors from `J` to `C` form the functor category
[`FunctorCat`](@ref)`(J, C)`, for any categories `J` and `C`. For a shape
`J`, a natural transformation `η: F → G` is a tuple of components
`Hom(F, G)[(η₁, η₂, …)]`, one at each vertex. Checking it needs the
[`diagram`](@ref)`(F)` of each functor, its objects and morphisms at the
vertices and generating arrows: a diagram is its own, a functor out of a
`FreeCat` is evaluated on them, and any other functor may define it. Then the
components, with a square at each arrow, form a diagram of shape `J` in the
arrow category [`arrowCategory`](@ref)`(C)`, and that the squares commute is
exactly naturality. Between functors without diagrams, `force=true` trusts
the transformation. [`diagonal`](@ref)`(J, C)` is the functor
`Δ: C → [J, C]`, sending `X` to `constant(X) ∘ toPoint(J)`.

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
`C`; a category without them needs `force=true`.

## Standardized Interface

- `Cone(D)[ℓ₁, ℓ₂, …]`, `Cocone(D)[ℓ₁, ℓ₂, …]` — a cone or cocone from its
  legs, one per vertex; `Cone(D)[X, (ℓ₁, …)]` also gives the apex
- `Hom(c₁, c₂)[u]` — the morphism of cones or cocones given by `u`
- `apex(c)`, `legs(c)`, `leg(c, j)`, `diagram(K)` for `K = Cone(D)`
- `apexMorphism(m)` — the map of apexes of a morphism of cones or cocones

A category computes its limits by defining `terminal` for its cones,
`terminal(K::ConeIn{SomeCategory})`, and its colimits by doing so for cones in
its opposite, `terminal(K::ConeIn{Op{SomeCategory}})`; the rest, including
`canonicalHom` into a limit and out of a colimit, is up to that category.
Otherwise `limit` and `colimit` throw an `InterfaceViolation`. With them:

- `limit(D)`, `colimit(D)`, `terminal(C)`, `initial(C)`
- `product`, `equalizer`, `pullback`, `coproduct`, `coequalizer`, `pushout`,
  `A × B`, `A ⊔ B` — limits and colimits of common shapes

## Interface Specification Assumptions

- `J` is a shape; `D` is a diagram of shape `J`
- `c, c₁, c₂` are cones or cocones over `D`

## Basic Example

Cones over a diagram in a free category, where `r` and `q ∘ p` are different:

```julia
C = FreeCat(3, (1 => 2, 2 => 3, 1 => 3))
p, q, r = generator(C, 1), generator(C, 2), generator(C, 3)
S = Slice(C[3])           # the cones over the one-object diagram at 3
Hom(S[q ∘ p], S[q])[p]    # a morphism of cones, since q ∘ p == q ∘ p
Hom(S[r], S[q])[p]        # throws, since q ∘ p != r
```
