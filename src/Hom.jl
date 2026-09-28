# =========================================================
# ================ DIFFERENT KINDS OF HOMS ================
# =========================================================

"""
    Hom(X, Y)

The category of morphisms from `X` to `Y`, two objects of the same category,
which it tracks alongside them. A morphism from `X` to `Y` is any object of
`Hom(X, Y)`. Whether a morphism is an epimorphism, monomorphism or isomorphism
is a property of it, see [`isEpi`](@ref), [`isMono`](@ref) and
[`isIso`](@ref).
"""
struct Hom{DomT, CodT, CatT} <: Category
    domain::OIC{DomT, CatT}
    codomain::OIC{CodT, CatT}
    category::CatT

    function Hom{DomT, CodT, CatT}(
        dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
    ) where DomT where CodT where CatT
        homCategoriesAgree(dom, cod, cat) ||
            throw(homArgsError(dom, cod, cat))
        return new{DomT, CodT, CatT}(dom, cod, cat)
    end
end

# =========================================================
# ================== MALFORMED HOMS =======================
# =========================================================

# `Hom(dom, cod)` is between objects of one category, `Hom(dom, cod, cat)`
# additionally names it. Anything else is reported by `homArgsError`, worded
# according to what is actually wrong with the arguments.
function Hom(dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}) where DomT where CodT where CatT
    return Hom{DomT, CodT, CatT}(dom, cod, category(dom))
end

function Hom(
    dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}, cat::CatT
) where DomT where CodT where CatT
    return Hom{DomT, CodT, CatT}(dom, cod, cat)
end

# between categories, i.e. objects of `Cat`
Hom(A::Category, B::Category) = Hom(Cat[A], Cat[B])

Hom(objA, objB) = throw(homArgsError(objA, objB))
Hom(objA, objB, cat) = throw(homArgsError(objA, objB, cat))

# Whether both `dom` and `cod` belong to `cat`
homCategoriesAgree(dom, cod, cat) = category(dom) == cat && category(cod) == cat

# The error explaining why `Hom(objA, objB)`, or `Hom(objA, objB, cat)`,
# cannot be built
function homArgsError(objA, objB, cats...)
    kind = catclr("Hom")
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
            is not. You may wrap it in a category first, e.g. $(codeclr("C[x]")).
            """
        )
    elseif !(objB isa ObjectInCategory)
        return ArgumentError(
            @annotated """
            The codomain of a $kind must be an ObjectInCategory. However,
            $TAB$(valclr(objB))
            is not. You may wrap it in a category first, e.g. $(codeclr("C[x]")).
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
    isEpi(f)

Whether the morphism `f` is an epimorphism. Each implementation of morphisms
overloads it for its own, e.g. a map of finite cardinals is one when it is
surjective.
"""
function isEpi(f::OIC{<:Any, <:Hom})
    H = category(f)
    throw(InterfaceViolation(
        @annotated """
        Whether a morphism is an epimorphism must be defined for each category, but \
        $(category(H)) does not define it for morphisms represented by \
        values of type $(dtclr(typeString(typeof(object(f))))), such as
        $TAB$f.
        When appropriate, you may define it by overloading
        $(overloadHint("isEpi",
            ("f", @annotated("any morphism of $(category(H)) represented by \
                values of type $(dtclr(typeString(typeof(object(f)))))"),
                "OIC{$(typeString(typeof(object(f)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(category(H))))}}"),
        ))
        """
    ))
end

"""
    isMono(f)

Whether the morphism `f` is a monomorphism. Each implementation of morphisms
overloads it for its own, e.g. a map of finite cardinals is one when it is
injective.
"""
function isMono(f::OIC{<:Any, <:Hom})
    H = category(f)
    throw(InterfaceViolation(
        @annotated """
        Whether a morphism is a monomorphism must be defined for each category, but \
        $(category(H)) does not define it for morphisms represented by \
        values of type $(dtclr(typeString(typeof(object(f))))), such as
        $TAB$f.
        When appropriate, you may define it by overloading
        $(overloadHint("isMono",
            ("f", @annotated("any morphism of $(category(H)) represented by \
                values of type $(dtclr(typeString(typeof(object(f)))))"),
                "OIC{$(typeString(typeof(object(f)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(category(H))))}}"),
        ))
        """
    ))
end

"""
    isIso(f)

Whether the morphism `f` is an isomorphism. Each implementation of morphisms
overloads it for its own, e.g. a map of finite cardinals is one when it is
bijective.
"""
function isIso(f::OIC{<:Any, <:Hom})
    H = category(f)
    throw(InterfaceViolation(
        @annotated """
        Whether a morphism is an isomorphism must be defined for each category, but \
        $(category(H)) does not define it for morphisms represented by \
        values of type $(dtclr(typeString(typeof(object(f))))), such as
        $TAB$f.
        When appropriate, you may define it by overloading
        $(overloadHint("isIso",
            ("f", @annotated("any morphism of $(category(H)) represented by \
                values of type $(dtclr(typeString(typeof(object(f)))))"),
                "OIC{$(typeString(typeof(object(f)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(category(H))))}}"),
        ))
        """
    ))
end

"""
    compose(g, f)

The composite `g ∘ f` of morphisms `f: X → Y` and `g: Y → Z` of one category,
applying `f` first. Each implementation of morphisms overloads it for its own.
"""
function compose(g::OIC{<:Any, <:Hom}, f::OIC{<:Any, <:Hom})
    C = category(category(f))
    Tg, Tf = typeString(typeof(object(g))), typeString(typeof(object(f)))
    types = Tg == Tf ? dtclr(Tg) : @annotated("$(dtclr(Tg)) and $(dtclr(Tf))")
    throw(InterfaceViolation(
        @annotated """
        Composition of morphisms must be defined for each category, but $C does \
        not define it for morphisms represented by values of type \
        $types, such as
        $TAB$g
        and
        $TAB$f.
        When appropriate, you may define it by overloading
        $(overloadHint("compose",
            ("g", @annotated("any morphism of $C represented by values of \
                type $(dtclr(typeString(typeof(object(g)))))"),
                "OIC{$(typeString(typeof(object(g)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(C)))}}"),
            ("f", @annotated("any morphism of $C represented by values of \
                type $(dtclr(typeString(typeof(object(f)))))"),
                "OIC{$(typeString(typeof(object(f)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(C)))}}"),
        ))
        """
    ))
end

"""
    firstDifference(f, g)

Compare morphisms `f` and `g` with the same domain and codomain: `nothing` when
they agree, and otherwise the first place they differ, as
`(path, left, right)`: `f` gives `left` and `g` gives `right` at the element
`last(path)`, reached through the components named by the rest of `path`. For
morphisms without elements to compare at, `path` is empty and `left` and
`right` are `f` and `g` themselves. Each implementation of morphisms
overloads it for its own.
"""
function firstDifference(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom})
    C = category(category(g))
    Tf, Tg = typeString(typeof(object(f))), typeString(typeof(object(g)))
    types = Tf == Tg ? dtclr(Tf) : @annotated("$(dtclr(Tf)) and $(dtclr(Tg))")
    throw(InterfaceViolation(
        @annotated """
        Comparison of morphisms must be defined for each category, but $C does \
        not define it for morphisms represented by values of type \
        $types, such as
        $TAB$f
        and
        $TAB$g.
        When appropriate, you may define it by overloading
        $(overloadHint("firstDifference",
            ("f", @annotated("any morphism of $C represented by values of \
                type $(dtclr(typeString(typeof(object(f)))))"),
                "OIC{$(typeString(typeof(object(f)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(C)))}}"),
            ("g", @annotated("any morphism of $C represented by values of \
                type $(dtclr(typeString(typeof(object(g)))))"),
                "OIC{$(typeString(typeof(object(g)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(C)))}}"),
        ))
        """
    ))
end

"""
    g ∘ f

The composite `compose(g, f)`, applying `f` first.
"""
Base.:∘(g::OIC{<:Any, <:Hom}, f::OIC{<:Any, <:Hom}) = compose(g, f)

"""
    agrees(f, g)

Whether the morphisms `f` and `g` agree, i.e. `firstDifference(f, g)` finds no
difference. Unlike `f == g`, which is identity, this compares what they do.
"""
agrees(f::OIC{<:Any, <:Hom}, g::OIC{<:Any, <:Hom}) = firstDifference(f, g) === nothing

"""
    id(X)

The identity morphism of the object `X`, in `Hom(X, X)`. Each category
overloads it for its own objects.
"""
function id(X::OIC)
    throw(InterfaceViolation(
        @annotated """
        Identity morphisms must be defined for each category, but \
        $(category(X)) does not define them for objects represented by \
        values of type $(dtclr(typeString(typeof(object(X))))), such as
        $TAB$X.
        When appropriate, you may define them by overloading
        $(overloadHint("id",
            ("X", @annotated("any object of $(category(X)) represented by \
                values of type $(dtclr(typeString(typeof(object(X)))))"),
                "OIC{$(typeString(typeof(object(X)))), \
                $(typeString(typeof(category(X))))}"),
        ))
        """
    ))
end

"""
    function domain(hom::AbstractHom)

Get the domain.
"""
function domain(hom::Hom)
    return hom.domain
end

"""
    function codomain(hom::AbstractHom)

Get the codomain.
"""
function codomain(hom::Hom)
    return hom.codomain
end

"""
    function category(hom::AbstractHom)

Retrieve the category that `hom`'s domain and codomain live in.
"""
function category(hom::Hom)
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
of `Hom(A, B)`; for two categories, a
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
    (morph::OIC{<:Any, <:Hom{DomT, CodT, CatT}})(
        elem::OIC{<:Any, OICAsCat{DomT, CatT}}
    )

Apply `morph` to an element of (the category of elements of) its domain,
giving an element of `ascat(codomain(morph))`.

This generic fallback always throws an [`InterfaceViolation`](@ref);
implementations of morphisms overload it for their own types.
"""
function (morph::OIC{<:Any, <:Hom{DomT, CodT, CatT}})(
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
    (morph::OIC{<:Any, <:Hom{DomT, CodT, CatT}})(
        elemMorph::OIC{<:Any, <:Hom{<:Any, <:Any, OICAsCat{DomT, CatT}}}
    )

Apply `morph` to a morphism between elements of its domain (i.e. a morphism in
`ascat(domain(morph))`), giving a morphism in `ascat(codomain(morph))`.

This generic fallback always throws an [`InterfaceViolation`](@ref);
implementations of morphisms overload it for their own types.
"""
function (morph::OIC{<:Any, <:Hom{DomT, CodT, CatT}})(
    elemMorph::OIC{<:Any, <:Hom{<:Any, <:Any, OICAsCat{DomT, CatT}}}
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
    inv(f::OIC{<:Any, <:Hom}; force=false)

The inverse of an isomorphism `f: X → Y`, a morphism in `Hom(Y, X)`. With
`force=true`, `f` is trusted to be an isomorphism rather than checked.

This generic fallback always throws an [`InterfaceViolation`](@ref);
implementations of morphisms overload it for their own types.
"""
function Base.inv(f::OIC{<:Any, <:Hom}; force::Bool=false)
    H = category(f)
    throw(InterfaceViolation(
        @annotated """
        Inverses of morphisms must be defined for each category, but \
        $(category(H)) does not define them for morphisms represented by \
        values of type $(dtclr(typeString(typeof(object(f))))), such as
        $TAB$f.
        When appropriate, you may define them by overloading
        $(overloadHint("Base.inv",
            ("f", @annotated("any morphism of $(category(H)) represented by \
                values of type $(dtclr(typeString(typeof(object(f)))))"),
                "OIC{$(typeString(typeof(object(f)))), <:Hom{<:Any, <:Any, \
                $(typeString(typeof(category(H))))}}"),
        ))
        and accepting the keyword `force`.
        """
    ))
end

# The fallbacks for `compose`, `firstDifference`, `id` and the predicates only
# throw, so they do not count as an implementation, e.g. for the checks of
# comma categories and natural transformations
let morph = OIC{Nothing, Hom{Nothing, Nothing, Category}}
    append!(FALLBACK_SIGNATURES, [
        which(Tuple{typeof(compose), morph, morph}).sig,
        which(Tuple{typeof(firstDifference), morph, morph}).sig,
        which(Tuple{typeof(id), OIC{Nothing, Category}}).sig,
        which(Tuple{typeof(isEpi), morph}).sig,
        which(Tuple{typeof(isMono), morph}).sig,
        which(Tuple{typeof(isIso), morph}).sig,
        which(Tuple{typeof(inv), morph}).sig,
    ])
end

