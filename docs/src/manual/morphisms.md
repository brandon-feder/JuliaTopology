```@meta
CurrentModule = JuliaTopology
```

# Homs between categories

Morphisms are not a separate wrapper type. Given two objects `D, C :: OIC` of
the same category, `Hom(D, C)` is itself a [`Category`](@ref), and a morphism
from `D` to `C` is any object of it:

```julia
J = FreeCat(2, (1 => 2,))
D, C = J[1], J[2]
H = Hom(D, C)
f = H[(1,)]                               # f :: OIC{_, Hom{...}}
```

Whether a morphism is an epimorphism, monomorphism or isomorphism is a
property of it, not a category it is in: [`isEpi`](@ref), [`isMono`](@ref)
and [`isIso`](@ref), which each implementation of morphisms defines.

## Required Interface

None of its own — `Hom(D, C)` is always a valid category once `D` and `C` are
objects of the same category. What is required to actually have objects *in*
it is the underlying category's own interface for morphisms.

## Standardized Interface

- `Hom(D, C)`, `Hom(D, C, cat)` — build the category; an `ArgumentError` says
  what is wrong when `D`, `C` are not objects of one category (or of `cat`).
  For categories `A`, `B`, `Hom(A, B)` is `Hom(Cat[A], Cat[B])`, the functors.
- `domain(H)`, `codomain(H)`, `category(H)` — `D`, `C`, and the shared
  category `D`/`C` belong to
- `compose(g, f)`, `g ∘ f`, `id(D)`, `firstDifference(f, g)`, `agrees(f, g)`
  — defined by each implementation of morphisms; calling one that is not
  throws an `InterfaceViolation` naming the method to define
- `isEpi(f)`, `isMono(f)`, `isIso(f)`, `inv(f; force=false)` — likewise
- `f == g`, `hash(f)` on `H` itself — default identity; not overloaded here
  (use `agrees(f, g)` to compare what morphisms do)

## Interface Specification Assumptions

- `D, C :: OIC{_, Cat}` for some shared category `Cat`.
- `H :: Hom{<:Any, <:Any, Cat}`, i.e. `Hom(D, C)`.
- `f, g` are objects of `H`.
