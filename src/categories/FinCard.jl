"""
    CatFinCard()

The category of finite cardinals. Its global instance is [`FinCard`](@ref).
"""
struct CatFinCard <: Category end

"""
    FinCard

The global instance of [`CatFinCard`](@ref), the category of finite cardinals.
"""
FinCard = CatFinCard()

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(n::Int, cat::CatFinCard)
    n >= 0 || throw(NotInCategory(n, cat,
        @annotated """
        The value
        $TAB$(valclr(n))
        is not an object of $cat, since finite cardinals must be \
        non-negative.
        """
    ))
    return true
end

function checkInCategory(obj, Cat::CatFinCard)
    throw(NotInCategory(obj, Cat,
        @annotated """
        The value
        $TAB$(valclr(obj))
        is not an object of $Cat, since the objects of $Cat are the \
        non-negative values of type $(dtclr("Int")), and it is a \
        $(dtclr(typeString(typeof(obj)))).
        """
    ))
end


# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

cardinality(card::OIC{Int, CatFinCard}) = object(card)

areIsomorphic(
    cardA::OIC{Int, CatFinCard}, 
    cardB::OIC{Int, CatFinCard}
) = (cardinality(cardA) == cardinality(cardB))

(≅)(
    cardA::OIC{Int, CatFinCard}, 
    cardB::OIC{Int, CatFinCard}
) = areIsomorphic(cardA, cardB)

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(::CatFinCard) = "FinCard"