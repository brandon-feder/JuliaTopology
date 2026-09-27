```@meta
CurrentModule = JuliaTopology
```

# Finite sets as categories

Once `X :: FinSet`, its own elements form a category, `@ascat X` (an
`OICAsCat`). An object of `@ascat X` is one of `X`'s plain values, wrapped so
it carries `X` with it.

```julia
X = FinSet[[:a, :b, :c]]
:b in (@ascat X)     # true
(@ascat X)[:b]        # the element object for :b
(@ascat X)[:z]        # throws NotInCategory
```

`X[i]` (from [`CatFinSet`](@ref)'s `getindex`) and iterating `X` both return
objects of `@ascat X`; `eltype(X)` gives their exact type.

## Required Interface

None — `checkInterface` for `@ascat X` always succeeds, since an element can
be any value. Membership (`checkInCategory` for `@ascat X`) is provided out of
the box when `X` is backed by an `AbstractArray` or `AbstractSet`, via
`Base.in` on the underlying container; a custom backing type would need to
overload this to support the syntax below.

## Standardized Interface

- `v in (@ascat X)` — is `v` an element of `X`
- `(@ascat X)[v]` — `v` as an element object; throws `NotInCategory` if not

## Interface Specification Assumptions

- `X :: FinSet`
- `v` is a plain value of the type `X` holds

## Basic Example

See above.
