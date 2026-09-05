using JuliaTopology
using JuliaTopology.Pretty
using JuliaTopology.Presets

ASC = AbstractSimplicialComplex
GenericASC = GenericAbstractSimplicialComplex

# describe face tree
torusSimplices =  [
    (1,), (2,), (3,), (4,), (5,), (6,), (7,),
    (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
    (2, 3), (2, 4), (2, 5), (2, 6), (2, 7),
    (3, 4), (3, 5), (3, 6), (3, 7),
    (4, 5), (4, 6), (4, 7),
    (5, 6), (5, 7),
    (6, 7),
    (1, 2, 4), (1, 2, 6), (1, 3, 4), (1, 3, 7), (1, 5, 6), (1, 5, 7),
    (2, 3, 5), (2, 3, 7), (2, 4, 5), (2, 6, 7),
    (3, 4, 6), (3, 5, 6),
    (4, 5, 7), (4, 6, 7)
]

# create simplicial complex
complex = @wrap GenericASC(torusSimplices) ASC

println("$INF # simplices: $(nSimplices(complex))")
println("$INF dimension: $(dimension(complex))")

# choose ring to work over
F = @wrap GenericFiniteField(7) FiniteField

for n in 0:dimension(complex)
    println("Betti(", n, ") = ", betti(complex, F, n))
end
