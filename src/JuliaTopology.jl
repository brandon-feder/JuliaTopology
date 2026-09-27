module JuliaTopology

using Base.Iterators, FLoops, Transducers
using DataStructures
using StyledStrings: AnnotatedString, Face, addface!, annotatedstring, annotations
using JuliaSyntaxHighlighting: highlight
import Nemo

include("Utils.jl")
include("Settings.jl")
include("Category.jl")
include("Hom.jl")
include("Printing.jl")

include("categories/Cat.jl")
# include("categories/Lifts.jl")
include("categories/FinCard.jl")
include("categories/FinSet.jl")
include("categories/MorphFinSet.jl")
include("categories/Point.jl")
# include("categories/MorphFinCard.jl")

include("functors/SetCardEquiv.jl")
include("functors/Basic.jl")
include("categories/Comma.jl")


# =========================================================
# ===================== EXPORT STUFF ======================
# =========================================================

# OIC Stuff
export Category, ObjectInCategory, OIC, object, category, @ascat,
    OICAsCat, oic

# Exceptions
export NoCanonicalHomError, InterfaceViolation, NotInCategory

# Category Machinery
export Hom, Epi, Mono, Iso

# Particular Implementations
export CatPoint, Point, MorphPoint, FuncIdentity, FuncConstant
export Comma, ↓, ObjComma, MorphComma, source, target, arrow,
    Slice, Coslice, terminal, initial
export FuncFinCardToSet, FuncFinSetToCard, Lifts, Cat, CatCat, FinCard, CatFinCard, 
    GenericMorphFinSet, GenericMorphFinCard, FinCat, FinMap, FinSet, CatFinSet

# Methods On OICs/Categories
export compose, id, domain, codomain, cardinality, canonicalHom, areIsomorphic,
    canLift, lift

# Misc
export ≅, in, →

end