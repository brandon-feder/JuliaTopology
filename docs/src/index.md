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

A, B = FinSet[1:3], FinSet[[:a, :b]]
a, b = ascat(A), ascat(B)
f = Hom(A, B)[[a[1] => b[:a], a[2] => b[:b], a[3] => b[:a]]]
f(a[2])
```

## Where to go next

- **Tutorials** walk through the package with runnable examples, starting with
  [Getting started](@ref).
- **Manual** explains each concept: [Objects and categories](@ref),
  morphisms, finite sets and comma categories.
- **API Reference** lists every function and type.
- **Developer Docs** cover the [Design guide](@ref), the style guide, and
  [Writing docs and examples](@ref).
