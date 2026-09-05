```@meta
CurrentModule = JuliaTopology
```

# JuliaTopology.jl

A Julia library for computational algebraic topology.

## Installation

Not yet registered. From a clone of the repo:

```julia
using Pkg
Pkg.develop(path="/path/to/JuliaTopology")
```

## Quick start

```julia
using JuliaTopology
using JuliaTopology.Presets  # torus

F = @wrap GenericFiniteField(7) FiniteField

for n in 0:dimension(torus)
    println("Betti($n) = ", betti(torus, F, n))
end
```

See [Guide](guide.md) for the object/category model and [Examples](examples.md) for a
full walkthrough.
