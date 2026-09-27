# =========================================================
# =================== IDENTITY FUNCTORS ===================
# =========================================================

"""
    struct FuncIdentity end

The identity functor of a category `C`, an object of `Iso(Cat[C], Cat[C])`
sending every object and morphism of `C` to itself. `id(Cat[C])` builds it.
"""
struct FuncIdentity end

function checkInCategory(obj::FuncIdentity, H::HomLike{<:Any, <:Any, CatCat})
    # from a category to itself
    if domain(H) != codomain(H)
        throw(NotInCategory(obj, H,
            @annotated """
            An identity functor is not a morphism in $H, since its domain \
            and codomain are different categories.
            """
        ))
    end
    return true
end

checkInterface(::FuncIdentity, ::HomLike{<:Any, <:Any, CatCat}) = true

id(X::OIC{<:Category, CatCat}) = Iso(X, X)[FuncIdentity(), force=true]

function (::OIC{FuncIdentity, <:HomLike{CatT, CatT, CatCat}})(
    obj::OIC{<:Any, CatT}
) where CatT
    return obj
end

function (::OIC{FuncIdentity, <:HomLike{CatT, CatT, CatCat}})(
    morph::OIC{<:Any, <:HomLike{<:Any, <:Any, CatT}}
) where CatT
    return morph
end

name(::OIC{FuncIdentity, <:HomLike{<:Any, <:Any, CatCat}}) = "Id"

# =========================================================
# =================== CONSTANT FUNCTORS ===================
# =========================================================

"""
    FuncConstant(X)

The functor `Δ(X)` from the terminal category [`Point`](@ref) to the category
of `X`, an object of `Hom(Cat[Point], Cat[category(X)])`. It sends `Point[:pt]`
to `X` and `id(Point[:pt])` to `id(X)`.
"""
struct FuncConstant
    value::OIC
end

function checkInCategory(obj::FuncConstant, H::Hom{CatPoint, <:Any, CatCat})
    # into the category of its value
    if category(obj.value) != object(codomain(H))
        throw(NotInCategory(obj, H,
            @annotated """
            The constant functor at
            $TAB$(obj.value)
            is not a morphism in $H, since its value is not an object of \
            $(object(codomain(H))).
            """
        ))
    end
    return true
end

checkInterface(::FuncConstant, ::Hom{CatPoint, <:Any, CatCat}) = true

function (F::OIC{FuncConstant, <:Hom{CatPoint, <:Any, CatCat}})(
    ::OIC{Symbol, CatPoint}
)
    return object(F).value
end

function (F::OIC{FuncConstant, <:Hom{CatPoint, <:Any, CatCat}})(
    ::OIC{MorphPoint, <:HomLike{Symbol, Symbol, CatPoint}}
)
    return id(object(F).value)
end

function name(F::OIC{FuncConstant, <:Hom{CatPoint, <:Any, CatCat}})
    return "Δ($(shortName(object(F).value)))"
end
