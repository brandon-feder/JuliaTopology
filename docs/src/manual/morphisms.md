```@meta
CurrentModule = JuliaTopology
```

# Homs between categories

Morphisms are not a separate wrapper type. Given two objects `D, C :: OIC` of
the same category, `Hom(D, C)` is itself a [`Category`](@ref), and a morphism
from `D` to `C` is any object of it:

```julia
D, C = FinSet[[1, 2]], FinSet[[:a, :b]]
H = Hom(D, C)
a, b = @ascat(D), @ascat(C)
f = H[[a[1] => b[:a], a[2] => b[:b]]]   # f :: OIC{_, Hom{...}}
```

`Epi(D, C)`, `Mono(D, C)` and `Iso(D, C)` are the same idea, restricted to
surjective, injective, or bijective morphisms respectively. `Hom` itself does
not know what "injective" means for an arbitrary category — it is only a tag;
each underlying category (e.g. `CatFinSet`) decides, in its own
`checkInCategory`, whether a given object qualifies for each kind (see
[Morphisms of FinSet](@ref) for that example).

`HomLike{DomT, CodT, CatT}` is the union of the four, for code that works the
same way regardless of kind.

## Required Interface

None of its own — `Hom`/`Epi`/`Mono`/`Iso` are always valid categories once
`D` and `C` are objects of the same category. What is required to actually
have objects *in* one of them is the underlying category's own interface for
morphisms (see [Morphisms of FinSet](@ref)).

## Standardized Interface

- `Kind(D, C)`, `Kind(D, C, cat)` for `Kind` one of `Hom`, `Epi`, `Mono`,
  `Iso` — build the category; an `ArgumentError` says what is wrong when
  `D`, `C` are not objects of one category (or of `cat`)
- `domain(H)`, `codomain(H)`, `category(H)` — `D`, `C`, and the shared
  category `D`/`C` belong to.
- `f == g`, `hash(f)` on `H`/`Epi`/`Mono`/`Iso` themselves — default identity;
  not overloaded here (see [The category FinSet](@ref) for a discussion of
  why equality is left as plain identity rather than made extensional).

## Interface Specification Assumptions

- `D, C :: OIC{_, Cat}` for some shared category `Cat`.
- `H :: HomLike{<:Any, <:Any, Cat}`, one of `Hom(D, C)`, `Epi(D, C)`,
  `Mono(D, C)`, `Iso(D, C)`.
- `f, g` are objects of `H`.
