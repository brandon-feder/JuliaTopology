```@meta
CurrentModule = JuliaTopology
```

# Guide

## Structure of Types

Objects in this library are not wrapped in a signature- or model-specific
type. There is exactly one wrapper, [`ObjectInCategory`](@ref) (aliased
`OIC`), pairing a plain value with the [`Category`](@ref) it belongs to:

```julia
X = ObjectInCategory([1, 2, 3], FinSet)   # or FinSet[[1, 2, 3]]
```

* A category is a plain `struct` subtyping `Category`, named `CatSomething`,
  with a lowercase global instance (`FinSet = CatFinSet()`). See
  [Categories](@ref).
* A category declares a *required interface* — the functions a type must
  implement to be one of its objects — checked by `checkInCategory`
  (membership) and `checkInterface` (the rest of the interface). Building
  `ObjectInCategory(x, C)` runs both, unless
  `force=true`.
* A category may also declare a *standardized interface*: functions built
  generically on top of the required interface, so every implementation gets
  them for free. See [The category FinSet](@ref) for a full example of both.
* A category may opt into letting the elements of its own objects be treated
  as objects of a further category, `@ascat X` for `X :: OIC`. This is not
  universal — `FinSet` does it, `FinCard` doesn't, since an integer has no
  elements of its own. See [Categories](@ref) and
  [Finite sets as categories](@ref).
* Morphisms are not a separate wrapper either. Given `D, C :: OIC` of the same
  category, `Hom(D, C)` (and `Epi`/`Mono`/`Iso`) is itself a `Category`, and a
  morphism is any object of it. See [Homs between categories](@ref).
* A conversion between categories ("lifting") is registered as a morphism
  *between categories themselves*, and resolved along a path of registered
  conversions. See [Lifts between categories](@ref).

See [Home](index.md) for the design principles behind this structure (why
morphisms live in a Hom-category, why traits are forgetful functors, etc.).
