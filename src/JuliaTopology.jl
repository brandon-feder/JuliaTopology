module JuliaTopology

using Base.Iterators, FLoops, Transducers
using DataStructures
import LinearAlgebra: ×
using StyledStrings: AnnotatedString, Face, addface!, annotatedstring, annotations
using JuliaSyntaxHighlighting: highlight
import Nemo

include("Utils.jl")
include("Settings.jl")
include("Category.jl")
include("Hom.jl")
include("Printing.jl")

include("categories/Cat.jl")
include("categories/FinCard.jl")
include("categories/FreeCat.jl")
include("categories/Op.jl")
# include("categories/MorphFinCard.jl")

include("functors/Basic.jl")
include("categories/FunctorCat.jl")
include("functors/Diagram.jl")
include("categories/Comma.jl")
include("categories/Cone.jl")
include("categories/Limits.jl")


# =========================================================
# ===================== EXPORT STUFF ======================
# =========================================================

# Objects and categories
export Category, ObjectInCategory, OIC, object, category, ascat, OICAsCat, oic

# Exceptions
export NoCanonicalHomError, InterfaceViolation, NotInCategory

# Morphisms
export Hom, domain, codomain, compose, id, firstDifference, agrees, isEpi, isMono,
    isIso, canonicalHom, →

# Categories
export Op, op, GenericMorphOp, Cat, CatCat, FinCard, CatFinCard, Point, FreeCat,
    FunctorCat, Comma, ↓, Cone, Cocone, Slice, Coslice

# Finite cardinals
export cardinality, areIsomorphic, ≅

# Functors and diagrams
export FuncIdentity, FuncCompose, toPoint, mapCone, FuncDiagram,
    FuncDiagonal, constant, diagram, diagonal, shape, parallelPair, cospan, span,
    discrete, objects, arrows

# Shapes and free categories
export nvertices, vertices, generators, GenericMorphFreeCat, generator, discreteShape, emptyShape,
    parallelPairShape, cospanShape, spanShape

# Functor and comma categories
export GenericMorphFunctorCat, components, arrowCategory, GenericComma, GenericMorphComma, source, target,
    arrow, apex, legs, leg, apexMorphism

# Limits and colimits
export limit, colimit, terminal, initial, universalArrow, ConeIn, product,
    coproduct, equalizer, coequalizer, pullback, pushout, ×, ⊔

# Misc
export in

end