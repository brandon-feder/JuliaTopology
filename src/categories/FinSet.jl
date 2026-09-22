"""
    struct CatFinSet
    
Category of finite sets. An `AbstractArray`, an `AbstractSet` or a `UnitRange`
is a finite set as is, e.g. `FinSet[[:a, :b]]` or `FinSet[Set([1, 2])]`.

The elements of a set `X` are objects in the category `OICAsCat(X)`, so that
`X[i]` and iterating over `X` give element objects, not plain values. For an
array or a set these hold the tuple `(i, x)`, the i-th element `x` in
enumeration order, so repeated values are still distinct elements. For a
`UnitRange` they hold the value itself. The order of an `AbstractSet` is that
of the underlying set, so mutating it afterwards changes the enumeration.

# Required Interface
- `cardinality(X)::Int` - Its cardinality (maybe optional, see below)
- `getindex(X, Int)` - The i-th element. All elements need to be unique.
- `Base.eltype(X)` - The type of the object held by each element, e.g.
        `Tuple{Int, Symbol}`. A method defined outside of `Base` is required.

# Standardized Interface
- `areIsomorphic(X, Y)::Bool` - Checks whether two
        sets are isomorphic
- `X ≅ Y` - Same as `areIsomorphic`
- `Base.iterate(X)` and `Base.iterate(X, sts)` - Iterate over the element
        objects. For an `AbstractSet` this is a single pass, while `X[i]` walks
        the set and costs O(i).
- `Base.IteratorSize(X) = Base.HasLength()`
- `Base.IteratorEltype(X) = Base.EltypeUnknown()` - Iteration yields element
        objects, which `eltype(X)` does not describe.
- `length(X)` - Same as `cardinality`.
- `FinSet[X, force=true]` - Skip the checks when wrapping `X`. Element
        access `X[i]` never needs them, so it always skips them.
- `element in (@ascat X)` and `(@ascat X)[element]` - Membership of an
        element, and the element as an object in `X`, from the object it holds
        (`(i, x)`, or `x` for a `UnitRange`). Throws `NotInCategory` explaining
        why an invalid element is not in `X`.

Maps between finite sets are described under [`GenericMorphFinSet`](@ref).

# Assumptions for interface Specification
- `obj`
- `Set::OIC(_, CatFinSet())`
- `X,Y::Set`
"""
struct CatFinSet <: Category end
FinSet = CatFinSet()

# By default, any `AbstractArray` or `AbstractSet` is in the category
inCategory(obj::AbstractArray, cat::CatFinSet) = true
inCategory(obj::AbstractSet, cat::CatFinSet) = true

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function checkInterface(obj::T, cat::CatFinSet) where T
    requireMethod(obj, cat, cardinality, Tuple{OIC{T, CatFinSet}})
    requireMethod(obj, cat, Base.getindex, Tuple{OIC{T, CatFinSet}, Int})
    # `Base` provides an `eltype` fallback for everything, so `hasmethod` would
    # always succeed; require a method defined outside of `Base` instead
    parentmodule(which(eltype, Tuple{OIC{T, CatFinSet}})) !== Base ||
        throw(InterfaceViolation(obj, cat,
            "missing required method `eltype` for argument types " *
            "$(Tuple{OIC{T, CatFinSet}})"))
    return true
end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

function areIsomorphic(
    setA::OIC{T, CatFinSet}, 
    setB::OIC{T, CatFinSet}
) where T
    return cardinality(setA) == cardinality(setB)
end

function (≅)(
    setA::OIC{T, CatFinSet}, 
    setB::OIC{T, CatFinSet}
) where T
    return areIsomorphic(setA, setB)
end

function Base.iterate(
    oic::OIC{T, CatFinSet}
) where T
    if cardinality(oic) > 0
        return oic[1], 1
    else
        return nothing
    end
end

function Base.iterate(
    oic::OIC{T, CatFinSet}, i
) where T
    if cardinality(oic) > i
        return oic[i+1], i+1
    else
        return nothing
    end
end

Base.length(oic::OIC{T, CatFinSet}) where T = cardinality(oic)

# `eltype(X)` describes the object inside each element, while iterating over
# `X` yields the element objects themselves, so iteration must not advertise it
Base.IteratorEltype(::Type{<:OIC{<:Any, CatFinSet}}) = Base.EltypeUnknown()

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

# there is no required interface for sets as categories since
# elements could be literally anything.
JuliaTopology.checkInterface(
    obj::Any, cat::JuliaTopology.OICAsCat{<:Any, JuliaTopology.CatFinSet}
) = true

# =========================================================
# ================ ABSTRACT ARRAYS AS SETS ================
# =========================================================

function cardinality(oic::OIC{T, CatFinSet}) where T <: AbstractArray
    return length(object(oic))
end

function Base.getindex(oic::OIC{T, CatFinSet}, i::Int) where T <: AbstractArray
    cat = @ascat oic
    # the element is read straight from the array, so it is in the set by
    # construction and the membership check would only repeat that lookup
    return cat[(i, getindex(object(oic), i)), force=true]
end

function Base.eltype(oic::OIC{T, CatFinSet}) where T <: AbstractArray
    return Tuple{Int, eltype(T)}
end

function JuliaTopology.inCategory(
    obj::Tuple{<:Int, T}, cat::JuliaTopology.OICAsCat{<:AbstractArray{T}, JuliaTopology.CatFinSet}
) where T
    arr = object(JuliaTopology.oic(cat))
    return obj[1] in eachindex(arr) && arr[obj[1]] == obj[2]
end

function JuliaTopology.checkInCategory(
    obj::Tuple{<:Int, T}, cat::JuliaTopology.OICAsCat{<:AbstractArray{T}, JuliaTopology.CatFinSet}
) where T
    arr = object(JuliaTopology.oic(cat))
    obj[1] in eachindex(arr) || throw(JuliaTopology.NotInCategory(obj, cat,
        "index $(obj[1]) is out of bounds for a set of cardinality $(length(arr))"))
    arr[obj[1]] == obj[2] || throw(JuliaTopology.NotInCategory(obj, cat,
        "element at index $(obj[1]) is $(repr(arr[obj[1]])), not $(repr(obj[2]))"))
    return true
end

# =========================================================
# ================= ABSTRACT SETS AS SETS =================
# =========================================================

# Elements are `(i, x)` for the i-th `x` in iteration order, as for arrays.
# A set has no random access, so `X[i]` walks the set and costs O(i), while
# iterating over `X` is a single pass. The order is that of the underlying
# set, so mutating it afterwards changes the enumeration of its elements.

function cardinality(oic::OIC{T, CatFinSet}) where T <: AbstractSet
    return length(object(oic))
end

function Base.getindex(oic::OIC{T, CatFinSet}, i::Int) where T <: AbstractSet
    set = object(oic)
    1 <= i <= length(set) || throw(BoundsError(set, i))
    cat = @ascat oic
    return cat[(i, first(Iterators.drop(set, i - 1))), force=true]
end

function Base.eltype(oic::OIC{T, CatFinSet}) where T <: AbstractSet
    return Tuple{Int, Base.eltype(T)}
end

function Base.iterate(oic::OIC{T, CatFinSet}) where T <: AbstractSet
    return _iterateSet(oic, iterate(object(oic)), 0)
end

function Base.iterate(
    oic::OIC{T, CatFinSet}, state::Tuple{Int, Any}
) where T <: AbstractSet
    i, inner = state
    return _iterateSet(oic, iterate(object(oic), inner), i)
end

function _iterateSet(oic, next, i)
    next === nothing && return nothing
    x, inner = next
    return (@ascat oic)[(i + 1, x), force=true], (i + 1, inner)
end

function JuliaTopology.inCategory(
    obj::Tuple{<:Int, T}, cat::JuliaTopology.OICAsCat{<:AbstractSet{T}, JuliaTopology.CatFinSet}
) where T
    set = object(JuliaTopology.oic(cat))
    return 1 <= obj[1] <= length(set) &&
        first(Iterators.drop(set, obj[1] - 1)) == obj[2]
end

function JuliaTopology.checkInCategory(
    obj::Tuple{<:Int, T}, cat::JuliaTopology.OICAsCat{<:AbstractSet{T}, JuliaTopology.CatFinSet}
) where T
    set = object(JuliaTopology.oic(cat))
    1 <= obj[1] <= length(set) || throw(JuliaTopology.NotInCategory(obj, cat,
        "index $(obj[1]) is out of bounds for a set of cardinality $(length(set))"))
    x = first(Iterators.drop(set, obj[1] - 1))
    x == obj[2] || throw(JuliaTopology.NotInCategory(obj, cat,
        "element at index $(obj[1]) is $(repr(x)), not $(repr(obj[2]))"))
    return true
end

# =========================================================
# ================ ACCESSORS FOR AN ELEMENT ================
# =========================================================

"""
    value(e)

The plain value an element of a finite set was built from: for `X[i]`, the
value `X` holds at position `i`. The inverse of [`findElement`](@ref).
"""
value(elem::OIC{<:Any, <:OICAsCat{<:Any, CatFinSet}}) = object(elem)[2]
value(elem::OIC{<:Any, <:OICAsCat{<:UnitRange, CatFinSet}}) = object(elem)

"""
    index(e)

The position of an element of a finite set in its enumeration, so that
`X[index(e)] == e`.
"""
index(elem::OIC{<:Any, <:OICAsCat{<:Any, CatFinSet}}) = object(elem)[1]
function index(elem::OIC{<:Any, <:OICAsCat{<:UnitRange, CatFinSet}})
    range = object(JuliaTopology.oic(category(elem)))
    return object(elem) - first(range) + 1
end

"""
    findElement(X, v)

The element of the finite set `X` whose plain value is `v`, the inverse of
[`value`](@ref). Throws an `ArgumentError` if `v` is not the value of any
element of `X`, or if it is the value of more than one (which `X` allows, e.g.
`FinSet[[1, 1, 2]]`, since elements are distinguished by position, not value).
"""
function findElement(X::OIC{<:Any, CatFinSet}, v)
    return _resolveElement(_elementTable(X), v, "set")
end

# The value a set was built from, for an element object of that set
const _elementValue = value

# =========================================================
# ================= UNITS RANGES AS SETS ==================
# =========================================================

function cardinality(oic::OIC{<:UnitRange, CatFinSet})
    return length(object(oic))
end

function Base.getindex(oic::OIC{<:UnitRange, CatFinSet}, i::Int)
    cat = @ascat oic
    return cat[getindex(object(oic), i), force=true]
end

function Base.eltype(oic::OIC{T, CatFinSet}) where T <: UnitRange
    return eltype(T)
end

function JuliaTopology.inCategory(
    obj::T, cat::JuliaTopology.OICAsCat{<:UnitRange{T}, JuliaTopology.CatFinSet}
) where T
    return obj in object(JuliaTopology.oic(cat))
end

function JuliaTopology.checkInCategory(
    obj::T, cat::JuliaTopology.OICAsCat{<:UnitRange{T}, JuliaTopology.CatFinSet}
) where T
    range = object(JuliaTopology.oic(cat))
    obj in range || throw(JuliaTopology.NotInCategory(obj, cat,
        "$(repr(obj)) is not in the range $(range)"))
    return true
end
