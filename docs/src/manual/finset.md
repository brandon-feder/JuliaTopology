```@meta
CurrentModule = JuliaTopology
```

# The category FinSet

`FinSet` (`CatFinSet`) is the category of finite sets. An `AbstractArray`,
`AbstractSet` or `UnitRange` with unique values is a finite set as is:

```julia
FinSet[[:a, :b, :c]]
FinSet[Set([1, 2, 3])]
FinSet[1:5]
```

A repeated value (e.g. `[1, 1, 2]`) is rejected with `NotInCategory`, unless
built with `FinSet[..., force=true]`.

## Required Interface

To wrap a custom type `T` as a `FinSet`, overload:

| Method | Signature | Meaning |
|---|---|---|
| `cardinality` | `cardinality(::OIC{T, CatFinSet})::Int` | the number of elements |
| `getindex` | `Base.getindex(::OIC{T, CatFinSet}, ::Int)` | the i-th element (order not meaningful); must be an object of `@ascat X` |

These are exactly what `checkInterface` verifies for `CatFinSet`.

## Standardized Interface

Built from `cardinality`/`getindex` above:

- `areIsomorphic(X, Y)`, `X ≅ Y` — `cardinality(X) == cardinality(Y)`
- `Base.iterate(X)`, `Base.length(X)`, `Base.IteratorSize(X)`
- `FinSet[X, force=true]` — skip the uniqueness/interface checks

## Interface Specification Assumptions

- `X, Y :: FinSet` means `X, Y :: ObjectInCategory{_, CatFinSet}`

## Basic Example

```julia
X = FinSet[[10, 20, 30]]
cardinality(X)        # 3
X ≅ FinSet[1:3]        # true, same cardinality
collect(X)             # the 3 element objects, X[1], X[2], X[3]
```
