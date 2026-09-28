# Design conventions

Choices this package makes consistently, beyond the [Style guide](style.md).

## Everything is an object of a category

- A value becomes an object of a category by wrapping it, `C[x]`; there is no
  other wrapper type.
- Morphisms are objects of `Hom(X, Y)`; functors are morphisms of `Cat`,
  i.e. objects of `Hom(Cat[A], Cat[B])`; natural transformations are
  morphisms of a `FunctorCat`.
- The elements of an object `X` whose category opts into it are objects of
  `ascat(X)`, and are always wrapped when passed around.
- Objects and morphisms are built as `C[data]` and `Hom(X, Y)[data]`, where
  `data` is the plainest description: a path `(1, 2)`, the components
  `(η₁, η₂, …)` of a natural transformation, a comma object `(a, b, h)` or
  morphism `(α, β)`. The `Generic…` types are for implementers.
- A morphism stores that plain description, not the structure used to check
  it: a natural transformation is its tuple of components, and its check
  builds the diagram in the arrow category whose squares commuting is
  naturality.
- New constructions are built from existing ones where the mathematics allows:
  a slice is a cone over a one-object diagram, a cone is a comma category
  `Δ ↓ D`, `Point` is a free category, a constant functor is a diagram, a
  limit is `terminal(Cone(D))`.

## Shapes

- Anything that works with diagrams (functor categories, the diagonal, cones,
  limits) knows a shape only through `nvertices(J)` and `generators(J)`, and
  looks objects and morphisms up by position, `objects(D)[i]` and
  `arrows(D)[k]`, never through `J`'s own morphisms. Only applying a diagram to
  a path is specific to `FreeCat`.
- Nothing is labeled by `Symbol`s: vertices, arrows, legs and components are
  numbered `1:n`, and objects built from several others (a product of finite
  cardinals, say) are numbered too.

## Duality

- A construction dual to another is defined through the opposite category,
  not written a second time: a cocone is `Op(Cone(op(D)))`, a coslice a
  cocone, `initial(Op(K))` is `op(terminal(K))`. Only computations on the
  underlying objects themselves (e.g. a colimit of sets) are written out for
  each side. The user-facing functions of a dual construction convert with
  `op` at the boundary, so that users see the morphisms of `C`, not of `Cᵒᵖ`.

## Properties are predicates

- There is one category of morphisms, `Hom(X, Y)`. Being an epimorphism,
  monomorphism or isomorphism is a property, `isEpi`/`isMono`/`isIso`.
- A function that needs such a property (e.g. `inv`) checks it, and takes
  `force=true` to skip the check when the caller knows it holds.

## Checks and `force`

- `C[x]` checks membership (`checkInCategory`) and the interface
  (`checkInterface`); `force=true` skips both. Checks run by default. A
  category requires no interface unless it defines `checkInterface`.
- Code which builds an object it knows to be valid, e.g. a limit's legs or a
  universal morphism, passes `force=true`; tests rebuild such objects without
  it, so the checks confirm them.
- When something cannot be checked, e.g. naturality between functors with no
  [`diagram`](@ref), or commutativity where morphisms cannot be compared,
  building it without `force` throws a `NotInCategory` saying so, and
  `force=true` trusts it. Nothing is refused only because it cannot be
  checked.
- A property which is expensive to check is checked once, where it matters,
  not repeatedly.

## Equality and uniqueness

- `==` is identity, as for any immutable struct: two objects built the same
  way from the same parts are equal, but two different maps that agree on
  every element are not. Use `firstDifference(f, g)` to compare morphisms
  extensionally.
- So that things built twice compare equal, prefer immutable containers
  (`Tuple`s) to `Dict`s for the parts of a diagram, a natural
  transformation or a category.
- `canonicalHom(A, B)` is the unique morphism from `A` to `B`, decided from the
  morphisms themselves (e.g. by checking that a cone factors in exactly one
  way), never by checking how `B` was built. It throws a
  `NoCanonicalHomError` when there is no morphism or more than one.

## Laziness and caching

- Maps may be lazy, computing each value on lookup, where the category's
  representation of morphisms allows it.
- An object of a category of finite things needs a known size, so it is only
  lazy when its iterator has one; otherwise it is computed once when built
  and reflects its inputs as they were then.
- Nothing derived from a wrapped value is cached, since the value may be
  mutated.

## Generic fallbacks

- A function every implementation must provide gets a documented stub
  (`function compose end`), and, where calling it unimplemented is a likely
  mistake, a fallback throwing an `InterfaceViolation` with an overload hint.
- A fallback that only throws is registered in `FALLBACK_SIGNATURES`, so that
  `@checkCallable` does not count it as an implementation.

## Messages

- Each check is followed directly by the `throw` of its own message, written
  with `@annotated`, with no helper functions for message text.
- A message states what is wrong, then how to fix it, and mentions
  `force=true` last, if at all.
- Values are colored by what they are: `objclr` for objects, `catclr` for
  categories, `dtclr` for types, `valclr` for plain values, `codeclr` for
  code; an object or category interpolated directly prints in its compact
  form. A value being discussed goes on its own line, indented by `TAB`.
- Limits on how much is printed (`MAX_NAME_LENGTH`,
  `MAX_SET_MAP_PAIRS_SHOWN`) live in `Settings.jl`, each with a setter.

## Names

- Functions are `camelCase` (`canonicalHom`, `firstDifference`), types and
  categories `PascalCase`.
- Unicode operators are aliases of named functions: `↓` for `Comma`, `∘` for
  `compose`, `→` for `canonicalHom`, `≅` for `areIsomorphic`.

## Tests and examples

- Each topic has a test file `test/<Topic>.jl`, included from
  `test/runtests.jl`.
- Examples are Literate scripts in `examples/`; each becomes a tutorial page
  (see [Writing docs and examples](writing-docs.md)). An example showing an
  error catches it and prints it with `showerror`.
