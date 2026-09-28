"""
    Cat()

The category of all categories.
"""
struct CatCat <: Category end

"""
    Cat

The global instance of [`CatCat`](@ref), the category of all categories.
"""
Cat = CatCat()

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

checkInCategory(::Category, ::CatCat) = true


# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(::CatCat) = "Cat"

# set the name of objects
name(oic::OIC{T, CatCat}) where T = name(object(oic))

# =========================================================
# =================== FUNCTOR FALLBACKS ===================
# =========================================================

"""
    (F::OIC{<:Any, <:Hom{DomT, CodT, CatCat}})(
        morph::OIC{<:Any, <:Hom{<:Any, <:Any, DomT}}
    )

Apply the functor `F` to a morphism of its domain, giving a morphism of its
codomain.

This generic fallback always throws an [`InterfaceViolation`](@ref); functors
overload it for their own types.
"""
function (F::OIC{<:Any, <:Hom{DomT, CodT, CatCat}})(
    morph::OIC{<:Any, <:Hom{<:Any, <:Any, DomT}}
) where DomT where CodT
    throw(InterfaceViolation(
        @annotated """
        The type
        $TAB$(dtclr(typeString(typeof(object(F)))))
        does not define how its objects in $(category(F)) map the morphisms \
        of $(object(domain(category(F)))), so the functor
        $TAB$F
        cannot be applied to
        $TAB$morph.
        When appropriate, you may define this by overloading
        $(overloadHint(nothing,
            ("F", @annotated("any element of $(category(F)) represented by \
                that type"),
                "OIC{$(typeString(typeof(object(F)))), \
                $(typeString(typeof(category(F))))}"),
            ("m", @annotated("any morphism of \
                $(object(domain(category(F))))"),
                "OIC{<:Any, <:Hom{<:Any, <:Any, $(typeString(DomT))}}"),
        ))
        """
    ))
end
