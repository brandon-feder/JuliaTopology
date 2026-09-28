```@meta
CurrentModule = JuliaTopology
```

# JuliaTopology.jl

JuliaTopology represents mathematical objects as plain Julia values paired with
the [`Category`](@ref) they belong to. Morphisms are themselves objects of
categories such as `Hom(A, B)`, so the same machinery checks, prints and
explains all of them.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/brandon-feder/JuliaTopology.git")
```

## A first example

```@example home
using JuliaTopology

C = FreeCat(3, (1 => 2, 2 => 3))
p, q = generator(C, 1), generator(C, 2)
q ∘ p
```

## Where to go next

- **Manual** explains each concept: [Objects and categories](@ref),
  morphisms, comma categories, limits and opposite categories.
- **API Reference** lists every function and type.
- **Developer Docs** cover the [Design guide](@ref), the style guide, and
  [Writing docs and examples](@ref).
