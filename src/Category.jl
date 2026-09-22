# =========================================================
# ================== ABSTRACT CATEGORY ====================
# =========================================================

"""
    abstract type Category

Abstract type to be subtyped by categories.
"""
abstract type Category end

function coloredPrint(
    cat::Category; depth::Int=0, catdt=false,
)
    # add category name
    catname = catclr(name(cat))
    res = "$catname"

    # add data type if needed
    if catdt
        dtname = dtclr(string(typeof(cat)))
        res *= " :: $dtname"
    end

    return res
end

# =========================================================
# ================ OBJECTS IN CATEGORIES  =================
# =========================================================

"""
    struct ObjectInCategory

Wrap an object and category into a single unit.

By default the constructor validates the object with
[`checkInCategory`](@ref) and [`checkInterface`](@ref). Pass `force=true` to
skip both checks, which avoids their cost when the caller already knows the
object is valid. An invalid object built this way is not detected, so later
operations on it may fail or return wrong results.
"""
struct ObjectInCategory{ObjT, CatT}
    object::ObjT
    category::CatT

    function ObjectInCategory{ObjT, CatT}(
        object::ObjT, category::CatT; force::Bool=false
    ) where ObjT where CatT <: Category
        if !force
            checkInCategory(object, category)
            checkInterface(object, category)
        end
        return new{ObjT, CatT}(object, category)
    end
end

"""
    function ObjectInCategory(object, category; force=false)

A constructor for `ObjectInCategory`. With `force=true` the membership and
interface checks are skipped.
"""
function ObjectInCategory(
    object::ObjT, category::CatT; force::Bool=false
) where ObjT where CatT <: Category
    return ObjectInCategory{ObjT, CatT}(object, category; force=force)
end

"""
    OIC

Alias for [`ObjectInCategory`](@ref).
"""
const OIC = ObjectInCategory

"""
    inCategory(obj, Cat::Category)

Check whether an object belongs in a particular category.
This needs to be overloaded by particular categories in 
order to call `ObjectInCategory()`.
"""
inCategory(obj, Cat::Category) = false

"""
    struct NotInCategory <: Exception

Thrown by [`checkInCategory`](@ref) when `object` does not belong to `category`.
`reason` explains which condition failed.
"""
struct NotInCategory <: Exception
    object
    category
    reason::String
end

function Base.showerror(io::IO, e::NotInCategory)
    print(io, "NotInCategory: object::", typeof(e.object),
        " is not in category::", typeof(e.category), ": ", e.reason)
end

"""
    checkInCategory(obj, Cat::Category)

Check whether an object belongs in a particular category, returning `true`
if it does. This generic fallback is `@assert inCategory(obj, Cat)`, so a
failure carries no explanation. Categories may overload it to throw a
[`NotInCategory`](@ref) with an informative reason instead; an overload
should agree with `inCategory` on which objects pass.
"""
function checkInCategory(obj, Cat::Category)
    @assert inCategory(obj, Cat)
    return true
end

function Base.showerror(io::IO, e::InterfaceViolation)
    print(io, "InterfaceViolation: object::", typeof(e.object),
        " does not satisfy the interface of category::", typeof(e.category),
        ": ", e.reason)
end

"""
    requireMethod(object, category, f, argtypes)

Throw an [`InterfaceViolation`](@ref) unless `f` has a method for
`argtypes`. Meant for use inside `checkInterface` overloads.
"""
function requireMethod(object, category, f, argtypes::Type{<:Tuple})
    hasmethod(f, argtypes) || throw(InterfaceViolation(object, category,
        "missing required method `$(nameof(f))` for argument types " *
        "$(argtypes)"))
    return true
end

"""
    checkInterface(object, category::Category)

Checks whether `object` satisfies the interface required by `category`. This
generic fallback matches any category that hasn't defined its own, more specific
method: it warns that no such check exists, then returns `true` rather than
erroring. Define `checkInterface(obj::SomeType, cat::SomeCategory) = ...`
to actually enforce an interface for a given category; such methods should
return `true` and throw an [`InterfaceViolation`](@ref) explaining what is
wrong otherwise.
"""
function checkInterface(object, category::Category)
    @warn "checkInterface() not overloaded for object::$(typeof(object)) "*
        "in category::$(typeof(category))"
    return true
end

"""
    X ∈ Cat

Syntactic sugar for `inCategory`
"""
Base.in(object, category::Category) = inCategory(object, category)

"""
    function object(oic::OIC)

Retrieve the object from an instance of `ObjectInCategory`
"""
function object(oic::OIC)
    return oic.object
end

"""
    function category(oic::OIC)

Retrieve the category from an instance of `ObjectInCategory`
"""
function category(oic::OIC)
    return oic.category
end

"""
    Base.getindex(C::Category, x; force=false)

Syntactic sugar to write `C[x]` for `ObjectInCategory(x, C)`. Write
`C[x, force=true]` to skip the checks, as in `ObjectInCategory(x, C; force=true)`.
Keyword arguments in indexing require Julia 1.11 or later.
"""
Base.getindex(C::Category, x; force::Bool=false) = ObjectInCategory(x, C; force=force)

function coloredPrint(
    oic::OIC; depth::Int=0, 
    objdt=true, cat=true, catdt=false,
)
    objname = objclr(name(oic))
    res = "$objname"

    # add data type if needed
    if objdt
        dtname = dtclr(string(typeof(object(oic))))
        res *= " :: $dtname"
    end

    # add category
    if cat
        res *= " in "
        res *= coloredPrint(category(oic), catdt=catdt)
    end

    return res
end

# =========================================================
# ================== OICs AS CATEGORIES ===================
# =========================================================

struct OICAsCat{Obj, Cat} <: Category
    oic::OIC{Obj, Cat}
end

function oic(cat::OICAsCat{Obj, Cat}) where Obj where Cat
    return cat.oic
end

"""
    @ascat oic

Construct an [`OICAsCat`](@ref) from an [`ObjectInCategory`](@ref)
"""
macro ascat(oic)
    return :($OICAsCat($(esc(oic))))
end

# how to print
function coloredPrint(
    cat::OICAsCat, depth::Int=0;
    colored=true, catdt=false,
)
    strA = catclr("{")
    strB = coloredPrint(cat.oic; depth=depth+1, objdt=catdt)
    strC = catclr("}")
    return strA*strB*strC
end