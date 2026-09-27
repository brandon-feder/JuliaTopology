"""
    CatPoint()

The terminal category, with a single object and only its identity morphism.
Its global instance is [`Point`](@ref).
"""
struct CatPoint <: Category end

"""
    Point

The global instance of [`CatPoint`](@ref), the terminal category: a single
object `Point[:pt]` whose only morphism is its identity, `id(Point[:pt])`.
"""
Point = CatPoint()

"""
    MorphPoint()

The only morphism of [`CatPoint`](@ref), the identity of `Point[:pt]`.
"""
struct MorphPoint end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInCategory(obj, cat::CatPoint)
    # the only object is `:pt`
    if obj !== :pt
        throw(NotInCategory(obj, cat,
            @annotated """
            The value
            $TAB$(valclr(obj))
            is not an object of $cat, whose only object is $(valclr(:pt)).
            """
        ))
    end
    return true
end

checkInterface(::Symbol, ::CatPoint) = true

# every morphism of `Point` is the identity of its only object
checkInCategory(::MorphPoint, ::HomLike{Symbol, Symbol, CatPoint}) = true

checkInterface(::MorphPoint, ::HomLike{Symbol, Symbol, CatPoint}) = true

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

id(pt::OIC{Symbol, CatPoint}) = Iso(pt, pt)[MorphPoint(), force=true]

function compose(
    ::OIC{MorphPoint, <:HomLike{Symbol, Symbol, CatPoint}},
    ::OIC{MorphPoint, <:HomLike{Symbol, Symbol, CatPoint}}
)
    return id(Point[:pt])
end

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(::CatPoint) = "•"

name(::OIC{MorphPoint, <:HomLike{Symbol, Symbol, CatPoint}}) = "id"
