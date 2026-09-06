# Examples

## Betti numbers of standard surfaces

From `examples/torus/torus-example.jl`: Betti numbers of four preset
triangulated surfaces — `sphere`, `torus`, `kleinBottle`, and
`realProjectivePlane` from `JuliaTopology.Presets` — computed over both
`𝔽₂` and `𝔽₃`, to show how coefficient choice affects homology in the
presence of torsion.

```julia
using JuliaTopology
using JuliaTopology.Pretty
using JuliaTopology.Presets: sphere, torus, kleinBottle, realProjectivePlane

# shorthand
ASC = AbstractSimplicialComplex
GenericASC = GenericAbstractSimplicialComplex

# define rings
F2 = @wrap GenericFiniteField(2) FiniteField
F3 = @wrap GenericFiniteField(3) FiniteField

println("$INF Homology of a sphere")
println("$INF$TAB over 𝔽₂")
for i in 0:dimension(sphere)
    println("$INF$TAB$TAB β($i) = ", betti(sphere, F2, i))
end
println("\n$INF$TAB over 𝔽₃")
for i in 0:dimension(sphere)
    println("$INF$TAB$TAB β($i) = ", betti(sphere, F3, i))
end

println("\n$INF Homology of a torus")
println("$INF$TAB over 𝔽₂")
for i in 0:dimension(torus)
    println("$INF$TAB$TAB β($i) = ", betti(torus, F2, i))
end
println("\n$INF$TAB over 𝔽₃")
for i in 0:dimension(torus)
    println("$INF$TAB$TAB β($i) = ", betti(torus, F3, i))
end

println("\n$INF Homology of a Klein bottle")
println("$INF$TAB over 𝔽₂")
for i in 0:dimension(kleinBottle)
    println("$INF$TAB$TAB β($i) = ", betti(kleinBottle, F2, i))
end
println("\n$INF$TAB over 𝔽₃")
for i in 0:dimension(kleinBottle)
    println("$INF$TAB$TAB β($i) = ", betti(kleinBottle, F3, i))
end

println("\n$INF Homology of a ℝP²")
println("$INF$TAB over 𝔽₂")
for i in 0:dimension(realProjectivePlane)
    println("$INF$TAB$TAB β($i) = ", betti(realProjectivePlane, F2, i))
end
println("\n$INF$TAB over 𝔽₃")
for i in 0:dimension(realProjectivePlane)
    println("$INF$TAB$TAB β($i) = ", betti(realProjectivePlane, F3, i))
end
```

Running this gives the following.

| Surface       | β over 𝔽₂    | β over 𝔽₃    |
|:--------------|:-------------|:-------------|
| Sphere        | (1, 0, 1)    | (1, 0, 1)    |
| Torus         | (1, 2, 1)    | (1, 2, 1)    |
| Klein bottle  | (1, 2, 1)    | (1, 1, 0)    |
| ℝP²           | (1, 1, 1)    | (1, 0, 0)    |

