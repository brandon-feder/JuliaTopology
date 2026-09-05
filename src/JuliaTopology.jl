module JuliaTopology

using Base: size
using FunctionWrappers: FunctionWrapper
using FLoops
using Transducers
import Nemo

include("./Pretty.jl")

# =========================================================
# ====================== CATEGORIES =======================
# =========================================================

include("./Category.jl")
export inCategory, NotInCategoryError, ObjectInCategory, assertInCategory, @wrap


# =========================================================
# ===================== METRIC SPACES =====================
# =========================================================

include("./MetricSpace/MetricSpace.jl")
export distance, nPoints, MetricSpace

include("./MetricSpace/GenericMetricSpace.jl")
export GenericMetricSpace


# =========================================================
# ======================== FIELDS =========================
# =========================================================

include("./Field/FiniteField.jl")
export FiniteField

include("./Field/GenericFiniteField.jl")
export GenericFiniteField

# =========================================================
# ======================== MODULES ========================
# =========================================================

include("./Modules/FreeModule.jl")
export FreeModule, Morphism, ring, dimension

include("./Modules/GenericFreeModule.jl")
export GenericFreeModule


# =========================================================
# ==================== MODULE MORPHISMS ===================
# =========================================================

include("./ModuleMorphism/FreeModuleMorphism.jl")
export FreeModuleMorphism, domain, codomain, rank

include("./ModuleMorphism/GenericFreeModuleMorphism.jl")
export GenericFreeModuleMorphism


# =========================================================
# =================== SIMPLICIAL COMPLEX ==================
# =========================================================

include("./AbstractSimplicialComplex/AbstractSimplicialComplex.jl")
export AbstractSimplicialComplex, nSimplices, dimension, simplexIterator, kSimplexFaceIdxIter, boundaryMap, betti

include("./AbstractSimplicialComplex/GenericAbstractSimplicialComplex.jl")
export GenericAbstractSimplicialComplex


# =========================================================
# ======================= PRESETS =========================
# =========================================================

include("./Presets.jl")

end