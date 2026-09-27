```@meta
CurrentModule = JuliaTopology
```

# Comma categories

Given functors `F: A → C` and `G: B → C`, i.e. objects of
`Hom(Cat[A], Cat[C])` and `Hom(Cat[B], Cat[C])`, the comma category
`F ↓ G` (or [`Comma`](@ref)`(F, G)`) has:

- objects `ObjComma(a, b, h)`: `a` in `A`, `b` in `B`, and `h: F(a) → G(b)` in
  `C`;
- morphisms `MorphComma(α, β)` from `(a, b, h)` to `(a′, b′, h′)`: `α: a → a′`
  in `A` and `β: b → b′` in `B` with `G(β) ∘ h == h′ ∘ F(α)`.

Its building blocks are the terminal category [`Point`](@ref) (one object,
`Point[:pt]`), the identity functor `id(Cat[C])`, and the constant functor
`Hom(Cat[Point], Cat[C])[FuncConstant(X)]` at an object `X`.

## Slices and coslices

- `Slice(X)` — `C/X`, i.e. `id(Cat[C]) ↓ Δ(X)`: objects are morphisms
  `f: A → X`, and a morphism from `f` to `g: B → X` is an `h: A → B` with
  `g ∘ h == f`.
- `Coslice(X)` — `X/C`, i.e. `Δ(X) ↓ id(Cat[C])`: objects are morphisms
  `f: X → A`, and a morphism from `f` to `g: X → B` is an `h: A → B` with
  `h ∘ f == g`.

## Required Interface

None of its own. Membership checks that each component lies in the right
category and, for morphisms, that the square commutes, which is checked
pointwise when `C` is FinSet (otherwise, pass `force=true`). Only `Hom` and
`Iso` (both components in an `Iso`) are checked; `Epi` and `Mono` are not.

## Standardized Interface

- `source(o)`, `target(o)`, `arrow(o)` — the `a`, `b`, `h` of `o`
- `compose(n, m)`, `id(o)` — componentwise
- `Slice(X)[f]`, `Coslice(X)[f]` — the object of a morphism `f`
- `Hom(o, o′)[h]` — the morphism of a slice or coslice given by `h`
- `terminal(Slice(X))`, `initial(Coslice(X))` — `id(X)`, with
  `canonicalHom(f, terminal(Slice(X)))` and
  `canonicalHom(initial(Coslice(X)), f)` the unique morphisms

## Interface Specification Assumptions

- `F, G` are functors with the same codomain `C`
- `o, o′` are objects of `F ↓ G`; `m, n` are morphisms between them
- `X` is an object of `C`

## Basic Example

```julia
X, A = FinSet[1:2], FinSet[1:4]
x = @ascat(X)
f = Slice(X)[Hom(A, X)[t -> x[mod1(object(t), 2)]]]
canonicalHom(f, terminal(Slice(X)))   # f itself, as a morphism into id(X)
```
