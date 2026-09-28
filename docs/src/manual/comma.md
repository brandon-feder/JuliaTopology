```@meta
CurrentModule = JuliaTopology
```

# Comma categories

Given functors `F: A → C` and `G: B → C`, i.e. objects of
`Hom(Cat[A], Cat[C])` and `Hom(Cat[B], Cat[C])`, the comma category
`F ↓ G` (or [`Comma`](@ref)`(F, G)`) has:

- objects `K[(a, b, h)]`: `a` in `A`, `b` in `B`, and `h: F(a) → G(b)` in
  `C`;
- morphisms `Hom(o, o′)[(α, β)]` from `(a, b, h)` to `(a′, b′, h′)`: `α: a → a′`
  in `A` and `β: b → b′` in `B` with `G(β) ∘ h == h′ ∘ F(α)`.

Its building blocks are the terminal category [`Point`](@ref) (the free
category with one object, `Point[:pt]`), the identity functor `id(Cat[C])`,
and the functor [`constant`](@ref)`(X)` from `Point` picking out an object `X`.

## Slices and coslices

Slices and coslices are cones and cocones over the one-object diagram
`constant(X)` (see [Limits and colimits](limits.md)):

- `Slice(X)` — `C/X`: objects are morphisms `f: A → X`, and a morphism from
  `f` to `g: B → X` is an `h: A → B` with `g ∘ h == f`.
- `Coslice(X)` — `X/C`: objects are morphisms `f: X → A`, and a morphism from
  `f` to `g: X → B` is an `h: A → B` with `h ∘ f == g`.

## Required Interface

None of its own. Membership checks that each component lies in the right
category and, for morphisms, that the square commutes, which is checked
using `compose` and [`firstDifference`](@ref) in `C`, e.g. pointwise when `C`
is FinSet (otherwise, pass `force=true`).

## Standardized Interface

- `source(o)`, `target(o)`, `arrow(o)` — the `a`, `b`, `h` of `o`
- `compose(n, m)`, `id(o)` — componentwise
- `Slice(X)[f]`, `Coslice(X)[f]` — the object of a morphism `f`
- `Hom(o, o′)[h]` — the morphism of a slice or coslice given by `h`
- `terminal(Slice(X))`, `initial(Coslice(X))` — the limit and colimit of
  `constant(X)`, isomorphic to `id(X)`, with
  `canonicalHom(f, terminal(Slice(X)))` and
  `canonicalHom(initial(Coslice(X)), f)` the unique morphisms

## Interface Specification Assumptions

- `F, G` are functors with the same codomain `C`
- `o, o′` are objects of `F ↓ G`; `m, n` are morphisms between them
- `X` is an object of `C`

## Basic Example

```julia
X, A = FinSet[1:2], FinSet[1:4]
x = ascat(X)
f = Slice(X)[Hom(A, X)[t -> mod1(t, 2), values=true]]
canonicalHom(f, terminal(Slice(X)))   # the unique morphism into the terminal object
```
