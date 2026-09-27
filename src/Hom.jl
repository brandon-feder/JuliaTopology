# =========================================================
# ================ DIFFERENT TYPES OF HOMS ================
# =========================================================

"""
    Hom

The category of morphisms between two objects
in the same category. Tracks that shared category directly, alongside
the domain and codomain.
"""
struct Hom{DomT, CodT, CatT} <: Category
    domain::OIC{DomT, CatT}
    codomain::OIC{CodT, CatT}
    category::CatT

    function Hom{DomT, CodT, CatT}(
        dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
    ) where DomT where CodT where CatT
        homCategoriesAgree(dom, cod, cat) ||
            throw(homArgsError(Hom, dom, cod, cat))
        return new{DomT, CodT, CatT}(dom, cod, cat)
    end
end

function Hom(
    dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}
) where DomT where CodT where CatT
    return Hom{DomT, CodT, CatT}(dom, cod, category(dom))
end

"""
    Epi

The category of morphisms between two objects
in the same category. Tracks that shared category directly, alongside
the domain and codomain.
"""
struct Epi{DomT, CodT, CatT} <: Category
    domain::OIC{DomT, CatT}
    codomain::OIC{CodT, CatT}
    category::CatT

    function Epi{DomT, CodT, CatT}(
        dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
    ) where DomT where CodT where CatT
        homCategoriesAgree(dom, cod, cat) ||
            throw(homArgsError(Epi, dom, cod, cat))
        return new{DomT, CodT, CatT}(dom, cod, cat)
    end
end

function Epi(
    dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}
) where DomT where CodT where CatT
    return Epi{DomT, CodT, CatT}(dom, cod, category(dom))
end

"""
    Mono

The category of morphisms between two objects
in the same category. Tracks that shared category directly, alongside
the domain and codomain.
"""
struct Mono{DomT, CodT, CatT} <: Category
    domain::OIC{DomT, CatT}
    codomain::OIC{CodT, CatT}
    category::CatT

    function Mono{DomT, CodT, CatT}(
        dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
    ) where DomT where CodT where CatT
        homCategoriesAgree(dom, cod, cat) ||
            throw(homArgsError(Mono, dom, cod, cat))
        return new{DomT, CodT, CatT}(dom, cod, cat)
    end
end

function Mono(
    dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}
) where DomT where CodT where CatT
    return Mono{DomT, CodT, CatT}(dom, cod, category(dom))
end

"""
    Iso

The category of morphisms between two objects
in the same category. Tracks that shared category directly, alongside
the domain and codomain.
"""
struct Iso{DomT, CodT, CatT} <: Category
    domain::OIC{DomT, CatT}
    codomain::OIC{CodT, CatT}
    category::CatT

    function Iso{DomT, CodT, CatT}(
        dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
    ) where DomT where CodT where CatT
        homCategoriesAgree(dom, cod, cat) ||
            throw(homArgsError(Iso, dom, cod, cat))
        return new{DomT, CodT, CatT}(dom, cod, cat)
    end
end

function Iso(
    dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}
) where DomT where CodT where CatT
    return Iso{DomT, CodT, CatT}(dom, cod, category(dom))
end

# =========================================================
# ================== MALFORMED HOMS =======================
# =========================================================

# `Kind(dom, cod)` is between objects of one category, `Kind(dom, cod, cat)`
# additionally names it. Anything else is reported by `homArgsError`, worded
# according to what is actually wrong with the arguments.
for Kind in (:Hom, :Epi, :Mono, :Iso)
    @eval begin
        function $Kind(
            dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
        ) where DomT where CodT where CatT
            return $Kind{DomT, CodT, CatT}(dom, cod, cat)
        end

        $Kind(objA, objB) = throw(homArgsError($Kind, objA, objB))
        $Kind(objA, objB, cat) = throw(homArgsError($Kind, objA, objB, cat))
    end
end

# Whether both `dom` and `cod` belong to `cat`
homCategoriesAgree(dom, cod, cat) = category(dom) == cat && category(cod) == cat

# The error explaining why `Kind(objA, objB)`, or `Kind(objA, objB, cat)`, cannot
# be built
function homArgsError(Kind, objA, objB, cats...)
    kind = catclr(string(nameof(Kind)))
    if !isempty(cats) && !(first(cats) isa Category)
        return ArgumentError(
            @annotated """
            The category of a $kind must be a Category. However, the value
            $TAB$(valclr(first(cats)))
            is not.
            """
        )
    elseif !(objA isa ObjectInCategory)
        return ArgumentError(
            @annotated """
            The domain of a $kind must be an ObjectInCategory. However,
            $TAB$(valclr(objA))
            is not. You may wrap it in a category first, e.g. $(codeclr("FinSet[x]")).
            """
        )
    elseif !(objB isa ObjectInCategory)
        return ArgumentError(
            @annotated """
            The codomain of a $kind must be an ObjectInCategory. However,
            $TAB$(valclr(objB))
            is not. You may wrap it in a category first, e.g. $(codeclr("FinSet[x]")).
            """
        )
    elseif isempty(cats)
        return ArgumentError(
            @annotated """
            A $kind is a morphism between two objects of the same category. \
            However,
            $TAB$objA
            and
            $TAB$objB
            belong to different categories. When appropriate, a map between \
            objects of different categories is instead a functor between the \
            categories, see `canonicalHom`.
            """
        )
    else
        cat = first(cats)
        side, obj = category(objA) != cat ? ("domain", objA) : ("codomain", objB)
        return ArgumentError(
            @annotated """
            The $side of a $kind in the category
            $TAB$cat
            must belong to that category. However,
            $TAB$obj
            does not.
            """
        )
    end
end

"""
    HomLike{DomT, CodT, CatT}

Union of the categories of morphisms [`Hom`](@ref), [`Epi`](@ref),
[`Mono`](@ref) and [`Iso`](@ref) between objects `DomT` and `CodT` of `CatT`,
for methods that apply to all of them.
"""
const HomLike{DomT, CodT, CatT} = Union{
    Hom{DomT, CodT, CatT}, Epi{DomT, CodT, CatT},
    Mono{DomT, CodT, CatT}, Iso{DomT, CodT, CatT},
}

"""
    compose(g, f)

The composite `g ∘ f` of morphisms `f: X → Y` and `g: Y → Z` of one category,
applying `f` first. Each implementation of morphisms overloads it for its own.
"""
function compose end

"""
    firstDifference(f, g)

Compare morphisms `f` and `g` with the same domain and codomain: `nothing` when
they agree, and otherwise the first place they differ, as `(at, left, right)`,
where `f` gives `left` and `g` gives `right` at `at`. Each implementation of
morphisms overloads it for its own.
"""
function firstDifference end

"""
    id(X)

The identity morphism of the object `X`, in `Iso(X, X)`. Each category
overloads it for its own objects.
"""
function id end

"""
    function domain(hom::AbstractHom)

Get the domain.
"""
function domain(hom::Union{Hom, Epi, Mono, Iso})
    return hom.domain
end

"""
    function codomain(hom::AbstractHom)

Get the codomain.
"""
function codomain(hom::Union{Hom, Epi, Mono, Iso})
    return hom.codomain
end

"""
    function category(hom::AbstractHom)

Retrieve the category that `hom`'s domain and codomain live in.
"""
function category(hom::Union{Hom, Epi, Mono, Iso})
    return hom.category
end

# =========================================================
# ==================== CANONICAL HOMS =====================
# =========================================================

struct NoCanonicalHomError <: Exception
    A
    B
    reason::AbstractString
end

function Base.showerror(io::IO, e::NoCanonicalHomError)
    print(io, "NoCanonicalHomError: ", e.reason)
end

"""
    canonicalHom(A, B)

The canonical morphism from `A` to `B`: for objects of one category, an object
of `Hom(A, B)` (or a more specific `Epi`, `Mono`, `Iso`); for two categories, a
functor between them. Throws a `NoCanonicalHomError` when none is defined;
categories overload this for their own objects.
"""
function canonicalHom(A, B)
    if A isa ObjectInCategory && B isa ObjectInCategory
        if category(A) != category(B)
            throw(NoCanonicalHomError(A, B, 
                @annotated """
                Canonical morphisms between objects are only defined when both \
                 objects belong to the same category. However,
                $TAB$A
                and
                $TAB$B
                belong to different categories.
                """
            ))
        else
            throw(NoCanonicalHomError(A, B, 
                @annotated """
                No canonical morphism is defined between the objects
                $TAB$A
                and
                $TAB$B.
                When appropriate, you may define a canonical morphism between \
                these by overloading
                $(overloadHint("canonicalHom",
                    ("A", @annotated("any object of $(coloredPrint(category(A)))"),
                        "OIC{<:Any, $(typeof(category(A)))}"),
                    ("B", @annotated("any object of $(coloredPrint(category(B)))"),
                        "OIC{<:Any, $(typeof(category(B)))}"),
                ))
                """
            ))
        end
    elseif A isa Category && B isa Category
        throw(NoCanonicalHomError(A, B, 
            @annotated """
            No canonical morphism is defined between the categories
            $TAB$A
            and
            $TAB$B.
            When appropriate, you may define a canonical morphism between \
            these by overloading
            $(overloadHint("canonicalHom",
                ("A", @annotated("the category $(coloredPrint(A))"), string(typeof(A))),
                ("B", @annotated("the category $(coloredPrint(B))"), string(typeof(B))),
            ))
            """
        ))
    else
        throw(NoCanonicalHomError(A, B, 
            @annotated """
            Canonical morphisms are only defined between objects \
            in the same categories or between categories themselves.
            """
        ))
    end
end

"""
    A → B

Same as `canonicalHom(A, B)`
"""
(→)(A, B) = canonicalHom(A, B)

# =========================================================
# ============= MAPS OF OBJECTS AND MORPHISMS =============
# =========================================================

# How to overload applying `morph` to `arg`, which is named `argname`
function morphismCallHint(morph, argname, arg)
    return overloadHint(nothing,
        ("f", @annotated("any element of $(coloredPrint(category(morph))) \
            represented by that type"),
            "OIC{$(typeof(object(morph))), $(typeof(category(morph)))}"),
        (argname, @annotated("any element of $(coloredPrint(category(arg)))"),
            "OIC{<:Any, $(typeof(category(arg)))}"),
    )
end

"""
    (morph::OIC{<:Any, <:HomLike{DomT, CodT, CatT}})(
        elem::OIC{<:Any, OICAsCat{DomT, CatT}}
    )

Apply `morph` to an element of (the category of elements of) its domain,
giving an element of `@ascat codomain(morph)`.

This generic fallback always throws an [`InterfaceViolation`](@ref);
implementations of morphisms overload it for their own types.
"""
function (morph::OIC{<:Any, <:HomLike{DomT, CodT, CatT}})(
    elem::OIC{<:Any, OICAsCat{DomT, CatT}}
) where DomT where CodT where CatT
    throw(InterfaceViolation(
        @annotated """
        The type
        $TAB$(dtclr(string(typeof(object(morph)))))
        does not define how its objects in $(category(morph)) map the \
        elements of their domain, so the morphism
        $TAB$morph
        cannot be applied to
        $TAB$elem.
        When appropriate, you may define this map by overloading
        $(morphismCallHint(morph, "x", elem))
        """
    ))
end

"""
    (morph::OIC{<:Any, <:HomLike{DomT, CodT, CatT}})(
        elemMorph::OIC{<:Any, <:HomLike{<:Any, <:Any, OICAsCat{DomT, CatT}}}
    )

Apply `morph` to a morphism between elements of its domain (i.e. a morphism in
`@ascat domain(morph)`), giving a morphism in `@ascat codomain(morph)`.

This generic fallback always throws an [`InterfaceViolation`](@ref);
implementations of morphisms overload it for their own types.
"""
function (morph::OIC{<:Any, <:HomLike{DomT, CodT, CatT}})(
    elemMorph::OIC{<:Any, <:HomLike{<:Any, <:Any, OICAsCat{DomT, CatT}}}
) where DomT where CodT where CatT
    throw(InterfaceViolation(
        @annotated """
        The type
        $TAB$(dtclr(string(typeof(object(morph)))))
        does not define how its objects in $(category(morph)) map the \
        morphisms between elements of their domain, so the morphism
        $TAB$morph
        cannot be applied to
        $TAB$elemMorph.
        When appropriate, you may define this map by overloading
        $(morphismCallHint(morph, "g", elemMorph))
        """
    ))
end

# Neither fallback above counts as implementing the map in `@checkCallable`
append!(FALLBACK_SIGNATURES, [
    which(Tuple{OIC{Nothing, Hom{Nothing, Nothing, Category}},
        OIC{Nothing, OICAsCat{Nothing, Category}}}).sig,
    which(Tuple{OIC{Nothing, Hom{Nothing, Nothing, Category}},
        OIC{Nothing, Hom{Nothing, Nothing, OICAsCat{Nothing, Category}}}}).sig,
])

# =========================================================
# ======================= INVERSES ========================
# =========================================================

"""
    inv(f::OIC{<:Any, <:HomLike})

The inverse of a morphism `f` in `Iso(X, Y)`, a morphism in `Iso(Y, X)`.

This generic fallback always throws: an `ArgumentError` when `f` is not in an
`Iso`, since only isomorphisms have inverses, and otherwise an
[`InterfaceViolation`](@ref); implementations of morphisms overload it for
their own types.
"""
function Base.inv(f::OIC{<:Any, <:HomLike})
    H = category(f)

    # only isomorphisms have inverses
    if !(H isa Iso)
        throw(ArgumentError(
            @annotated """
            The morphism
            $TAB$f
            has no inverse, since only morphisms in an $(catclr("Iso")) have \
            one. If it is a bijection, you may construct it in \
            $(Iso(domain(H), codomain(H))) instead.
            """
        ))
    end

    # the type representing `f` must say how to invert it
    throw(InterfaceViolation(
        @annotated """
        The type
        $TAB$(dtclr(typeString(typeof(object(f)))))
        does not define the inverse of its objects in $H, so the morphism
        $TAB$f
        cannot be inverted.
        When appropriate, you may define this by overloading
        $(overloadHint("Base.inv",
            ("f", @annotated("any element of $H represented by that type"),
                "OIC{$(typeString(typeof(object(f)))), $(typeString(typeof(H)))}"),
        ))
        """
    ))
end
