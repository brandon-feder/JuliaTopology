# =========================================================
# ================== ABSTRACT CATEGORY ====================
# =========================================================

"""
    abstract type Category

Abstract type to be subtyped by categories.
"""
abstract type Category end

# =========================================================
# ================ OBJECTS IN CATEGORIES  =================
# =========================================================

"""
    struct ObjectInCategory

Wrap an object and category into a single unit.

By default the constructor validates the object with
[`checkInCategory`](@ref) and [`checkInterface`](@ref). Pass `force=true` to
skip both checks.
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
    struct NotInCategory <: Exception

Thrown by [`checkInCategory`](@ref) when `object` does not belong to `category`.
`reason` explains which condition failed.
"""
struct NotInCategory <: Exception
    object
    category
    reason::AbstractString
end

function Base.showerror(io::IO, e::NotInCategory)
    print(io, "NotInCategory: ", e.reason)
end

"""
    checkInCategory(obj, Cat::Category)

Check whether an object belongs in a particular category, returning `true`
if it does, and throwing a [`NotInCategory`](@ref) explaining why otherwise.
This is the sole membership check a category needs to overload. This generic
fallback always throws a `NotInCategory` error.
"""
function checkInCategory(obj, Cat::Category)
    throw(NotInCategory(obj, Cat,
        @annotated """
        The value
        $TAB$(valclr(obj))
        cannot be regarded as an object of $Cat, since $Cat does not say \
        whether values of type $(dtclr(typeString(typeof(obj)))) are among \
        its objects. Most likely they are not meant to be. If they are, you \
        may say so by overloading
        $(overloadHint("checkInCategory",
            ("obj", @annotated("any value of type \
                $(dtclr(typeString(typeof(obj))))"), typeString(typeof(obj))),
            ("cat", @annotated("the category $Cat"), typeString(typeof(Cat))),
        ))
        or skip the check for this one value with `force=true`.
        """
    ))
end

function Base.showerror(io::IO, e::InterfaceViolation)
    print(io, "InterfaceViolation: ", e.reason)
end

"""
    @checkMethod object category f argtypes

Throw an [`InterfaceViolation`](@ref) unless the function `f` is defined and
has a method for `argtypes`. Here `f` must be a name such as `cardinality` or
`Base.getindex`. Meant for use inside `checkInterface` overloads.
"""
macro checkMethod(object, category, f, argtypes)
    fname = string(f)
    isdefinedexpr = if f isa Symbol
        :(isdefined($__module__, $(QuoteNode(f))))
    elseif Meta.isexpr(f, :., 2) && f.args[2] isa QuoteNode
        :(isdefined($(esc(f.args[1])), $(f.args[2])))
    else
        throw(ArgumentError(
            "@checkMethod expects a function name, got `$f`"))
    end
    return quote
        local obj = $(esc(object))
        local cat = $(esc(category))
        local types = $(esc(argtypes))
        local defined = $isdefinedexpr
        if !(defined && hasmethod($(esc(f)), types))
            local params = [T isa TypeVar ? T.ub : T
                for T in Base.unwrap_unionall(types).parameters]
            local hint = overloadHint($fname,
                (("x$i", describeArgType(T, cat), typeString(T))
                    for (i, T) in enumerate(params))...,
            )
            local problem = defined ? "which is missing for" :
                "but no function `$($fname)` is defined, so it is missing for"
            throw(InterfaceViolation(
                @annotated """
                The category $cat requires the method `$($fname)` of its \
                objects, $problem
                $TAB$(valclr(obj)).
                When appropriate, you may define it by overloading
                $hint
                or skip the check for this one value with `force=true`.
                """
            ))
        end
        true
    end
end

# Signatures of generic methods which only throw an error explaining that
# something is not implemented, e.g. applying a morphism to an element or
# composing morphisms. Finding one of these does not count as an
# implementation, in `@checkCallable` or `hasNonFallbackMethod`.
const FALLBACK_SIGNATURES = Type[]

# Whether calling with argument types `sig` has a method other than a fallback
function hasNonFallbackMethod(sig)
    Core._hasmethod(sig) || return false
    method = try
        which(sig)
    catch
        return true  # ambiguous, but not solely a fallback
    end
    return !(method.sig in FALLBACK_SIGNATURES)
end

"""
    @checkCallable object category argtypes

Throw an [`InterfaceViolation`](@ref) unless `object`, once wrapped as an
`ObjectInCategory{typeof(object), typeof(category)}`, is callable with arguments
of types `argtypes`, other than by a generic fallback which only throws. The
check is on types since the wrapper does not exist yet when `checkInterface`
runs. Meant for use inside `checkInterface` overloads.
"""
macro checkCallable(object, category, argtypes)
    return quote
        local obj = $(esc(object))
        local cat = $(esc(category))
        local types = $(esc(argtypes))
        local wrapped = OIC{typeof(obj), typeof(cat)}
        local sig = Base.rewrap_unionall(
            Tuple{wrapped, Base.unwrap_unionall(types).parameters...}, types)
        if !hasNonFallbackMethod(sig)
            local params = [T isa TypeVar ? T.ub : T
                for T in Base.unwrap_unionall(types).parameters]
            local argnames = ["x$i" for i in eachindex(params)]
            local hint = overloadHint(nothing,
                ("f", @annotated("any object of $cat represented by values of type \
                    $(dtclr(typeString(typeof(obj))))"),
                    typeString(wrapped)),
                ((argnames[i], describeArgType(T, cat), typeString(T))
                    for (i, T) in enumerate(params))...,
            )
            local call = codeclr("f($(join(argnames, ", ")))")
            throw(InterfaceViolation(
                @annotated """
                The category $cat requires its objects to be callable as \
                $call, but the type $(dtclr(typeString(typeof(obj)))) does \
                not define this, so it cannot represent
                $TAB$(valclr(obj)).
                When appropriate, you may define it by overloading
                $hint
                or skip the check for this one value with `force=true`.
                """
            ))
        end
        true
    end
end

"""
    checkInterface(object, category::Category)

Checks whether `object` satisfies the interface required by `category`,
returning `true` or throwing an [`InterfaceViolation`](@ref) explaining what is
missing. This generic fallback matches any category that hasn't defined its
own, more specific method, and returns `true`: a category requires nothing of
its objects unless it says so, by defining
`checkInterface(obj::SomeType, cat::SomeCategory) = ...`.
"""
checkInterface(object, category::Category) = true

"""
    X ∈ Cat

Membership, computed by attempting [`checkInCategory`](@ref) and reporting
whether it throws a [`NotInCategory`](@ref). All other exceptions
are rethrown.
"""
function Base.in(object, category::Category)
    try
        checkInCategory(object, category)
        return true
    catch e
        e isa NotInCategory && return false
        rethrow()
    end
end

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
"""
Base.getindex(C::Category, x; force::Bool=false) = ObjectInCategory(x, C; force=force)

# =========================================================
# ================== OICs AS CATEGORIES ===================
# =========================================================

"""
    struct OICAsCat{Obj, Cat}

The category whose objects are the elements of `X :: ObjectInCategory{Obj,
Cat}`, written `ascat(X)`. See [Categories](@ref).
"""
struct OICAsCat{Obj, Cat} <: Category
    oic::OIC{Obj, Cat}
end

"""
    oic(cat::OICAsCat)

The `ObjectInCategory` that `cat` (i.e. `ascat(oic(cat))`) is the elements of.
"""
function oic(cat::OICAsCat{Obj, Cat}) where Obj where Cat
    return cat.oic
end

"""
    ascat(X)

The object `X` regarded as a category, whose objects are its elements: an
[`OICAsCat`](@ref). `ascat(X)[x]` is the element `x` of `X`, and
[`oic`](@ref) goes back to `X`.
"""
ascat(X::OIC) = OICAsCat(X)