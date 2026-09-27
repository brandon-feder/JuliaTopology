# Style Guide

## Naming Conventions

* A category is a `PascalCase` `struct` subtyping `Category`, named
    `CatSomething` (e.g. `CatFinSet`, `CatFinCard`). Its global instance is
    exported under the un-prefixed, lowercase-first name (`FinSet`,
    `FinCard`).
* `Hom`, `Epi`, `Mono`, `Iso` are the exception: they are categories (`Cat`
    would apply) but keep their own short names, since they are parameterized
    by domain/codomain rather than standing alone.
* Type parameters holding a plain, unwrapped type are named for what they
    hold (`ObjT`, `DomT`, `CodT`, or plain `T`), not a fixed placeholder name
    like `Carrier`. There is no `Carrier` concept in this design — there is
    only ever one wrapper, `ObjectInCategory`.
* An implementation of a category's required interface (e.g.
    `GenericMorphFinSet`) is prefixed `Generic` only when it is the
    reference/default implementation and others are expected; a category with
    exactly one sensible representation does not need the prefix.

## File Organization

* A file that defines a category or a substantial implementation is divided
    into sections with multiline comment banners:
    ```julia
    # =========================================================
    # ================== SOME ALL-CAPS TITLE ==================
    # =========================================================
    ```
    The two sections common to nearly every category file are
    `REQUIRED INTERFACE` and `STANDARDIZED INTERFACE`, in that order.
* Every `.jl` file under `src/` must be reachable from an `include` in
    `src/JuliaTopology.jl` (directly or transitively). A file that is not
    `include`d is dead code; either wire it in or delete it, do not leave it
    sitting in the tree.

## Docstrings

* A category's docstring is split into up to three sections, in this order:
    - `# Required Interface` — one bullet per required function, with its
        declared signature (e.g. `` `cardinality(::OIC{T, CatFinSet})::Int` ``).
    - `# Standardized Interface` — same format, for functions built
        generically on top of the required interface.
    - `# Interface Specification Assumptions` — the shorthand used throughout
        the rest of the docstring (e.g. `` `X, Y :: FinSet` ``), so bullets
        don't need to re-explain it.
    See `CatFinSet` or `GenericMorphFinSet` for the canonical shape.
* The set of functions listed under a category's `# Required Interface` must
    be exactly the set asserted by that category's `checkInterface` —
    neither documenting an obligation that isn't checked, nor checking one
    that isn't documented. Membership rules enforced by `checkInCategory`
    (not `checkInterface`) are noted separately, since they're not part of
    the same check.
* Every exported name must have a docstring attached directly to it, not only
    mentioned in the prose of another docstring — this is what lets
    `@autodocs` render it under [API Reference](api.md). A function with many
    per-category methods and no single canonical one gets a documented stub:
    ```julia
    """
        cardinality(X)::Int

    The number of elements of `X`. ...
    """
    function cardinality end
    ```
    as `cardinality`/`areIsomorphic`/`≅` do in `Category.jl`.

## Printing

* A category overloads `name(cat::CatSomething)`; an object's own name
    defaults to `repr(object(oic))` and rarely needs overloading. Neither
    should overload `Base.show`/`Base.print` directly — the generic methods in
    `Printing.jl`, built from `name`, already cover every
    `Category`/`ObjectInCategory`: `coloredPrint` for the compact one-line
    form (`show(io, x)`, used inside messages) and `coloredTree` for the
    layered form the REPL displays (`show(io, MIME"text/plain"(), x)`).
* Plain Julia values that are not wrapped in a category are interpolated into
    messages as `valclr(x)`, so they read differently from objects.
* Colors are `StyledStrings` faces (`juliatopology_object`,
    `juliatopology_category`, ...), shown only when the `IO` supports color.
    A plain `"...$x..."` string discards them, so any message with colored
    parts is written `@annotated """..."""` instead, and an exception's
    `showerror` prints its reason as a separate argument
    (`print(io, "Name: ", e.reason)`) rather than interpolating it.
* Code in messages, such as a method to overload, goes through `codeclr`,
    which syntax highlights it as Julia. `overloadHint` already does this.

## Isomorphism

* Object isomorphism should *never* be expressed by overloading `Base.:(==)`.
    Use `areIsomorphic(x, y)::Bool` (and `≅`) instead, and only overload it for
    a category when isomorphism is actually decidable (and worth deciding) —
    e.g. `CatFinSet`/`CatFinCard` decide it from `cardinality` alone.
* Plain `==`/`hash`, where overloaded at all, should stay strict identity
    unless a category has a specific, well-understood reason to make it
    extensional (see the "Equality" note in [The category FinSet](finset-category.md)
    for why `FinSet` itself does not).

## Membership

* `checkInCategory(x, C)` is the only membership hook a category overloads —
    there is no separate boolean-returning predicate to keep in sync with it.
    `x in C` is derived from it generically, by catching the `NotInCategory` it
    throws (any other exception is a bug, and propagates);
    never overload `Base.in` directly for a specific category.

## The `force` Flag

* Any constructor or conversion that would otherwise re-validate an object
    that the caller already knows is valid (e.g. `ObjectInCategory`, `lift`,
    a category's own `[...]` sugar) should accept a `force::Bool=false`
    keyword that skips those checks. Default to `false`; never make skipping
    checks the default behavior.

## Mutable Implementations

* A standardized-interface function must never cache or memoize a value
    derived from a wrapped object's state unless that cache is invalidated by
    every mutating entry point of every implementation it could be called on.
    Until that invalidation exists, recompute from current state on every
    call.
