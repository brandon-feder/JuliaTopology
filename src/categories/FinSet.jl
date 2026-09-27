"""
    CatFinSet()

The category of finite sets. Its global instance is [`FinSet`](@ref).
"""
struct CatFinSet <: Category end

"""
    FinSet

The global instance of [`CatFinSet`](@ref), the category of finite sets.
"""
FinSet = CatFinSet()

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

# anything that looks like an iterator with a length is automatically
# an element of this category.
function checkInCategory(obj::T, cat::CatFinSet) where T
    required = [
        (Base.iterate, Tuple{T}, "Base.iterate(x::$(typeString(T)))"),
        (Base.iterate, Tuple{T, Any},
            "Base.iterate(x::$(typeString(T)), state)"),
        (Base.length, Tuple{T}, "Base.length(x::$(typeString(T)))"),
    ]
    missing = [sig for (f, types, sig) in required if !hasmethod(f, types)]
    if !isempty(missing)
        throw(NotInCategory(obj, cat,
            @annotated """
            The value
            $TAB$(valclr(obj))
            is not an object of $cat, since objects of $cat must be finite \
            collections, but values of type $(dtclr(typeString(T))) are missing \
            the methods
            $(join((@annotated("$TAB$(codeclr(sig))") for sig in missing), "\n"))
            When appropriate, you may define them, or skip this check for \
            this one value with `force=true`.
            """
        ))
    end
    if !(Base.IteratorSize(T) isa Union{Base.HasLength, Base.HasShape})
        throw(NotInCategory(obj, cat,
            @annotated """
            The value
            $TAB$(valclr(obj))
            is not an object of $cat, since objects of $cat must be finite \
            collections, but values of type $(dtclr(typeString(T))) do not \
            have a known length: the method
            $TAB$(codeclr("Base.IteratorSize(::Type{$(typeString(T))})"))
            returns $(codeclr(string(Base.IteratorSize(T)))) instead of \
            $(codeclr("Base.HasLength()")) or $(codeclr("Base.HasShape()")).
            """
        ))
    end
    return true
end

function checkInterface(obj::T, cat::CatFinSet) where T
    @checkMethod obj cat cardinality Tuple{OIC{T, CatFinSet}}
    @checkMethod obj cat length Tuple{OIC{T, CatFinSet}}
    @checkMethod obj cat Base.iterate Tuple{OIC{T, CatFinSet}}
    @checkMethod obj cat Base.iterate Tuple{OIC{T, CatFinSet}, <:Any}
    @checkMethod obj cat Base.IteratorSize Tuple{OIC{T, CatFinSet}}
    if !(Base.IteratorSize(OIC{T, CatFinSet}) isa Base.HasLength)
        throw(InterfaceViolation(
            @annotated """
            The category $cat requires iterating over its objects to have a \
            known length, which is not the case for objects represented by values of type \
            $(dtclr(typeString(T))), such as
            $TAB$(valclr(obj)).
            The method
            $TAB$(codeclr("Base.IteratorSize(::Type{OIC{$(typeString(T)), \
                $(typeString(typeof(cat)))}})"))
            returns $(codeclr(string(Base.IteratorSize(OIC{T, CatFinSet})))) \
            where it should return $(codeclr("Base.HasLength()")).
            """
        ))
    end
    return true
end


function cardinality(
    oic::OIC{<:Any, CatFinSet}
)
    return length(object(oic))
end

# the elements are wrapped; when the elements of `T` are not of one concrete
# type, neither are the wrapped ones
function Base.eltype(
    oic::OIC{T, CatFinSet}
) where T
    E = Base.eltype(T)
    return isconcretetype(E) ? OIC{E, OICAsCat{T, CatFinSet}} :
        OIC{<:E, OICAsCat{T, CatFinSet}}
end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

function areIsomorphic(
    setA::OIC{<:Any, CatFinSet},
    setB::OIC{<:Any, CatFinSet}
)
    return cardinality(setA) == cardinality(setB)
end

function (≅)(
    setA::OIC{<:Any, CatFinSet},
    setB::OIC{<:Any, CatFinSet}
)
    return areIsomorphic(setA, setB)
end

function Base.iterate(
    oic::OIC{T, CatFinSet}
) where T
    next = Base.iterate(object(oic))
    if next === nothing
        return nothing
    else
        (res, sts) = next
        return (@ascat oic)[res, force=true], sts
    end
end

function Base.iterate(
    oic::OIC{T, CatFinSet}, sts
) where T
    next = Base.iterate(object(oic), sts)
    if next === nothing
        return nothing
    else
        (res, sts) = next
        return (@ascat oic)[res, force=true], sts
    end
end

Base.length(oic::OIC{T, CatFinSet}) where T = cardinality(oic)

Base.IteratorSize(::Type{OIC{T, CatFinSet}}) where T = Base.HasLength()

# =========================================================
# ======================= PRINTING ========================
# =========================================================

function name(::CatFinSet)
    return "FinSet"
end

# =========================================================
# =================== SETS AS CATEGORIES ==================
# =========================================================

# automatically wrap objects of a set
function checkInCategory(
    obj::Any, cat::OICAsCat{<:Any, CatFinSet}
)
    if obj in object(oic(cat))
        return true
    else
        throw(NotInCategory(obj, cat,
            @annotated """
            The value
            $TAB$(valclr(obj))
            is not an element of $(objclr(shortName(oic(cat)))), so it is \
            not an object of $cat.
            """
        ))
    end
end

# there is no required interface for sets as categories since
# elements could be literally anything.
checkInterface(
    obj::Any, cat::OICAsCat{<:Any, CatFinSet}
) = true