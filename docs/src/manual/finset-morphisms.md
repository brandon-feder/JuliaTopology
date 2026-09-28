```@meta
CurrentModule = JuliaTopology
```

# Morphisms of FinSet

As with any pair of categories (see [Homs between categories](@ref)), a
morphism of finite sets is any object of `Hom(D, C)::Hom{<:Any, <:Any,
CatFinSet}`. [`GenericMorphFinSet`](@ref) is currently the only
implementation satisfying the required interface below, but nothing about
`Hom{OIC{_, CatFinSet}, OIC{_, CatFinSet}}` ties it to that one type: it is a
`Dict` sending each element of the domain to an element of the codomain.

## Construction

`GenericMorphFinSet(dict)` checks nothing: `dict` should send elements of
`ascat(D)` to elements of `ascat(C)`, where `D` and `C` are the domain and
codomain of the `H` it is wrapped in. Whether it is a morphism is checked by
`checkInCategory` when it is wrapped in `H`, e.g. by `H[dict]`.

## Required Interface

`f(x)`, which is defined for every `GenericMorphFinSet`, and which
`checkInterface` requires of every object of `H`. `checkInCategory` throws a
`NotInCategory` unless:

- its keys are exactly the elements of `ascat(D)`
- its values are elements of `ascat(C)`

## Standardized Interface

- `H[dict]`, `H[[x => y, ...]]`, `H[GenericMorphFinSet(dict)]` —
  construct a map in `H`, checking that it lies in `H` unless `force=true`. For
  the first two, each `x`, `y` must already be an element of `ascat(D)` or
  `ascat(C)`; an `ArgumentError` is thrown for an entry that is not a pair, an
  `x` or `y` that is not such an element, or an `x` given twice.
- `H[f::Function]` — the lazy map `x ↦ f(x)`, where `f` sends elements of
  `ascat(D)` to elements of `ascat(C)`
- `H[pairs, values=true]`, `H[f, values=true]` — the same, written on plain
  values, which are wrapped (and checked unless `force=true`)
- `A × B`, `A ⊔ B` — the product and disjoint union, as sets
- `homSet(A, B)` — the set of all maps from `A` to `B`; with
  `evaluation(A, B)`, `curry(f, C, A)` and `uncurry(g, A)`, FinSet is
  cartesian closed. `homFrom(X)` and `homTo(X)` are the representable functors
  `Hom(X, -)` and `Hom(-, X)`, and a unique map is the only element of its
  hom-set: `canonicalHom(A, B) == object(only(homSet(A, B)))`
- `image(f)`, `imageFactorization(f)` — the image of `f`, and `f` as a
  surjection onto it followed by its inclusion
- `f(x)` — apply `f` to an element `x` of the domain
- `f == g`, `hash(f)`
- `compose(f, g)`, `f ∘ g` (`g` first), `id(X)`
- `isMono(f)`, `isEpi(f)`, `isIso(f)` — injective, surjective, bijective
- `inv(f; force=false)` — the inverse of a bijection; `force=true` skips
  checking that `f` is one
- `firstDifference(f, g)` — where `f` and `g` first disagree, if anywhere
- `globalElement(x)`, `element(p)` — an element `x` as the map `1 → X`
  picking it out, and back; `f(p)` composes `f` with such a map

## Interface Specification Assumptions

- `f, g :: GenericMorphFinSet`
- `H :: Hom{<:Any, <:Any, CatFinSet}`, i.e. `Hom(D, C)`
- `D, C :: FinSet` — the domain and codomain of `H`
- `x, y` are elements of `ascat(D)`, `ascat(C)`

## Basic Example

```julia
D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b, :c]]
d, c = ascat(D), ascat(C)
f = Hom(D, C)[[d[1] => c[:a], d[2] => c[:b], d[3] => c[:c]]]
isIso(f)         # true
f(d[1])          # :a ∈ ascat([:a, :b, :c])
inv(f)(c[:a])    # 1 ∈ ascat([1, 2, 3])
```
