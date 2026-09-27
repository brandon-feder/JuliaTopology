# =========================================================
# =================== FinSet To FinCard ===================
# =========================================================

"""
    struct FuncFinSetToCard end

Functor from `FinSet` to `FinCard`
"""
struct FuncFinSetToCard end

checkInCategory(::FuncFinSetToCard, ::Hom{CatFinSet, CatFinCard, CatCat}) = true

checkInterface(::FuncFinSetToCard, ::Hom{CatFinSet, CatFinCard, CatCat}) = true

name(::OIC{FuncFinSetToCard, Hom{CatFinSet, CatFinCard, CatCat}}) = "Equivalence"

function (::OIC{FuncFinSetToCard, Hom{CatFinSet, CatFinCard, CatCat}})(obj::OIC{<:Any, CatFinSet})
    return FinCard[cardinality(obj)]
end

# =========================================================
# =================== FinCard To FinSet ===================
# =========================================================

"""
    struct FuncFinSetToCard end

Functor from `FinCard` to `FinSet`
"""
struct FuncFinCardToSet end

checkInCategory(::FuncFinCardToSet, ::Hom{CatFinCard, CatFinSet, CatCat}) = true

checkInterface(::FuncFinCardToSet, ::Hom{CatFinCard, CatFinSet, CatCat}) = true

name(::OIC{FuncFinCardToSet, Hom{CatFinCard, CatFinSet, CatCat}}) = "Equivalence"

function (::OIC{FuncFinCardToSet, Hom{CatFinCard, CatFinSet, CatCat}})(obj::OIC{<:Any, CatFinCard})
    return FinSet[1:cardinality(obj)]
end

# =========================================================
# ==================== CANONICAL HOMS =====================
# =========================================================

canonicalHom(::CatFinSet, ::CatFinCard) = 
    Hom(Cat[FinSet], Cat[FinCard])[FuncFinSetToCard()]

canonicalHom(::CatFinCard, ::CatFinSet) = 
    Hom(Cat[FinCard], Cat[FinSet])[FuncFinCardToSet()]