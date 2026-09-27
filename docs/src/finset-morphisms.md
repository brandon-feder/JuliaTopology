```@meta
CurrentModule = JuliaTopology
```

# Morphisms of FinSet

As with any pair of categories (see [Homs between categories](@ref)), a
morphism of finite sets is any object of `Hom(D, C)::Hom{<:Any, <:Any,
CatFinSet}` — and further of `Epi`, `Mono` or `Iso` when it is surjective,
injective, or both. [`GenericMorphFinSet`](@ref) is currently the only
implementation satisfying the required interface below, but nothing about
`Hom{OIC{_, CatFinSet}, OIC{_, CatFinSet}}` ties it to that one type: it is a
`Dict` sending each element of the domain to an element of the codomain.

## Construction

`GenericMorphFinSet(D, C, dict)` checks nothing: `dict` should send elements of
`@ascat D` to elements of `@ascat C`. Whether it is a morphism is checked by
`checkInCategory` when it is wrapped in `H`, e.g. by `H[dict]`.

## Required Interface

`f(x)`, which is defined for every `GenericMorphFinSet`, and which
`checkInterface` requires of every object of `H`. `checkInCategory` throws a
`NotInCategory` unless:

| Condition | Kinds |
|---|---|
| its domain and codomain are those of `H` | all |
| its keys are exactly the elements of `@ascat D` | all |
| its values are elements of `@ascat C` | all |
| no two keys have the same value (injective) | `Mono`, `Iso` |
| every element of `@ascat C` is a value (surjective) | `Epi`, `Iso` |

## Standardized Interface

- `H[dict]`, `H[[x => y, ...]]`, `H[GenericMorphFinSet(D, C, dict)]` —
  construct a map in `H`, checking that it lies in `H` unless `force=true`. For
  the first two, each `x`, `y` must already be an element of `@ascat D` or
  `@ascat C`; an `ArgumentError` is thrown for an entry that is not a pair, an
  `x` or `y` that is not such an element, or an `x` given twice.
- `H[f::Function]` — the lazy map `x ↦ f(x)`, where `f` sends elements of
  `@ascat D` to elements of `@ascat C`
- `f(x)` — apply `f` to an element `x` of the domain
- `f == g`, `hash(f)`
- `compose(f, g)`, `f ∘ g` (`g` first) — kind is the most specific of
  `Iso`/`Mono`/`Epi`/`Hom` that `f` and `g` guarantee
- `id(X)::Iso`, `inv(f)` (for `f :: Iso`)

## Interface Specification Assumptions

- `f, g :: GenericMorphFinSet`
- `H :: HomLike{<:Any, <:Any, CatFinSet}` — one of `Hom(D, C)`, `Epi(D, C)`,
  `Mono(D, C)`, `Iso(D, C)`
- `D, C :: FinSet` — the domain and codomain of `H`
- `x, y` are elements of `@ascat D`, `@ascat C`

## Basic Example

```julia
D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b, :c]]
d, c = @ascat(D), @ascat(C)
f = Iso(D, C)[[d[1] => c[:a], d[2] => c[:b], d[3] => c[:c]]]
f(d[1])          # :a ∈ @ascat [:a, :b, :c]
inv(f)(c[:a])    # 1 ∈ @ascat [1, 2, 3]
```
