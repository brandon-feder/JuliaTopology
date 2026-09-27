```@meta
CurrentModule = JuliaTopology
```

# Lifts between categories

`Lifts` is a global registry of forgetful functors, letting an object
of one category be converted ("lifted") into another along a chain of
registered conversions.

A functor is registered as a morphism *between categories*: an object of
`Hom(Cat[Sub], Cat[Sup])`, where `Sub`/`Sup` are the categories themselves,
wrapped as objects of [`Cat`](@ref) (the category of all categories):

```julia
push!(Lifts, ObjectInCategory(myFunctor, Hom(Cat[Sub()], Cat[Sup()])))
```

`myFunctor` must be callable on an `ObjectInCategory` of `Sub`, returning a
plain value valid in `Sup`.

## Required Interface

None — registering a lift only requires `myFunctor` to be callable as above;
this is checked when it is actually used, not at registration.

## Standardized Interface

- `canLift(sub, sup)::Bool` — is `sup` reachable from `sub` (possibly through
  several registered lifts), or are they the same category?
- `lift(X, sup; force=false)`, `sup[X, force=false]` — convert `X` into an
  object of `sup`, applying every functor along the path. Throws if `sup` is
  unreachable. `force=true` skips re-validating the result of each hop.

## Interface Specification Assumptions

- `Sub, Sup :: Category`.
- `X :: OIC{_, Sub}`.
