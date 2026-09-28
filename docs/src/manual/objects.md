```@meta
CurrentModule = JuliaTopology
```

# Objects and categories

Objects in this library are not wrapped in a signature- or model-specific
type. There is exactly one wrapper, [`ObjectInCategory`](@ref) (aliased
`OIC`), pairing a plain value with the [`Category`](@ref) it belongs to:

```julia
X = ObjectInCategory([1, 2, 3], FinSet)   # or FinSet[[1, 2, 3]]
```

* A category is a plain `struct` subtyping `Category`, named `CatSomething`,
  with a lowercase global instance (`FinSet = CatFinSet()`). See
  [Categories](@ref) below.
* A category declares a *required interface* — the functions a type must
  implement to be one of its objects — checked by `checkInCategory`
  (membership) and `checkInterface` (the rest of the interface). Building
  `ObjectInCategory(x, C)` runs both, unless
  `force=true`.
* A category may also declare a *standardized interface*: functions built
  generically on top of the required interface, so every implementation gets
  them for free. See [The category FinSet](@ref) for a full example of both.
* A category may opt into letting the elements of its own objects be treated
  as objects of a further category, `ascat(X)` for `X :: OIC`. This is not
  universal — `FinSet` does it, `FinCard` doesn't, since an integer has no
  elements of its own. See [Categories](@ref) and
  [Finite sets as categories](@ref).
* Morphisms are not a separate wrapper either. Given `D, C :: OIC` of the same
  category, `Hom(D, C)` is itself a `Category`, and a
  morphism is any object of it. See [Homs between categories](@ref).
* A conversion between categories ("lifting") is registered as a morphism
  *between categories themselves*, and resolved along a path of registered
  conversions. See [Lifts between categories](@ref).

See the [Design guide](@ref) for the principles behind this structure (why
morphisms live in a Hom-category, why traits are forgetful functors, etc.).

## Categories

A [`Category`](@ref) is a plain, usually field-less, `struct` naming a
category (e.g. `CatFinSet`, `CatFinCard`, `CatCat`). By convention its type is
prefixed `Cat`; a global instance of it is exported without the prefix
(`FinSet = CatFinSet()`, `FinCard = CatFinCard()`).

An object of a category is not wrapped in a category-specific type. Instead,
any Julia value can be *paired* with a category via
[`ObjectInCategory`](@ref) (aliased `OIC`):

```julia
X = ObjectInCategory([1, 2, 3], FinSet)   # or FinSet[[1, 2, 3]]
object(X)     # [1, 2, 3]
category(X)   # FinSet
```

`C[x]` is sugar for `ObjectInCategory(x, C)`.

### Required Interface

A category overloads, for its own objects:

- `checkInCategory(x, C::Category)` — is `x` an object of `C`? Returns `true`
  if so; throws a [`NotInCategory`](@ref) explaining why otherwise. There is
  no separate boolean-returning predicate — this is the only membership hook.
  Defaults to always throwing, since no category-specific rule is known.
- `checkInterface(x, C::Category)` — checks that `x`'s type implements
  whatever standardized-interface functions `C` needs (see e.g.
  [The category FinSet](@ref)); throws an
  [`InterfaceViolation`](@ref) if not. Defaults to requiring nothing.
- `name(C::Category)::String` — how `C` prints. Defaults to the type name.

`ObjectInCategory(x, C)` calls `checkInCategory` then `checkInterface`, so
building one already validates `x`. Pass `force=true` to skip both checks,
e.g. when `x` is already known to be valid.

### Standardized Interface

- `x in C` — `true` if `checkInCategory(x, C)` succeeds, `false` if it throws
  a [`NotInCategory`](@ref). Any other exception is a bug in a check and
  propagates.

`ascat(X)` (i.e. `OICAsCat(X)`), regarding the elements of `X :: OIC` as
objects of their own category, is not part of every category's standardized
interface — it is a mechanism a category can opt into by overloading
`checkInCategory` for `OICAsCat{_, C}`, not a guarantee that comes for free.
`CatFinSet` does this, since its elements are meaningfully individual objects
(see [Finite sets as categories](@ref)); `CatFinCard` does not, since an `Int`
has no elements of its own to speak of.

### Interface Specification Assumptions

- `x` is a plain Julia value.
- `C :: Category`.
- `X, Y :: OIC` means `X, Y :: ObjectInCategory{_, C}` for some category `C`.
