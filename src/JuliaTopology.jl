module JuliaTopology

using Base.Iterators, FLoops, Transducers
using DataStructures
using Crayons
import Nemo

include("Utils.jl")
include("Settings.jl")
include("Category.jl")
include("Hom.jl")
include("Printing.jl")

include("categories/Cat.jl")
include("categories/Lifts.jl")
include("categories/FinSet.jl")
include("categories/FinCard.jl")
include("categories/MorphFinSet.jl")

export Category, ObjectInCategory, OIC, object, category, @ascat
export NotInCategory, InterfaceViolation
export Hom, Epi, Mono, Iso, domain, codomain
export FinSet, cardinality, areIsomorphic, value, index, findElement
export Lifts, Cat, canLift, lift
export FinCard
export GenericMorphFinSet, compose, id
export ≅, in

end