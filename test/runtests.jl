using Test
using Random
using LinearAlgebra

using JuliaTopology

# The concrete category the generic machinery is tested over: the free
# category on X --p--> Y --q--> Z and X --r--> Z, in which `r` and `q ∘ p` are
# different morphisms X → Z
const C = FreeCat(3, (1 => 2, 2 => 3, 1 => 3))
const X, Y, Z = C[1], C[2], C[3]
const p, q, r = generator(C, 1), generator(C, 2), generator(C, 3)

include("Functors.jl")
include("FreeCat.jl")
include("Diagrams.jl")
include("Comma.jl")
include("Syntax.jl")
include("Op.jl")
