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