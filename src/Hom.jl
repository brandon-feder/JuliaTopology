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
        @assert category(dom) == cat && category(cod) == cat
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
        @assert category(dom) == cat && category(cod) == cat
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
        @assert category(dom) == cat && category(cod) == cat
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
        @assert category(dom) == cat && category(cod) == cat
        return new{DomT, CodT, CatT}(dom, cod, cat)
    end
end

function Iso(
    dom::OIC{DomT, CatT}, cod::OIC{CodT, CatT}
) where DomT where CodT where CatT
    return Iso{DomT, CodT, CatT}(dom, cod, category(dom))
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

# how to print a Hom
function coloredPrint(
    hom::Union{Hom, Epi, Mono, Iso}; depth::Int=0, catdt=false,
)
    # recursively get names of underlying objects/categories
    catname = coloredPrint(category(hom); depth=depth+1, catdt=false)
    domname = coloredPrint(domain(hom); depth=depth+1, objdt=false, cat=false)
    codname = coloredPrint(codomain(hom); depth=depth+1, objdt=false, cat=false)

    strB, strC = catclr(" → "), catclr("]")
    if isa(hom, Hom)
        strA = catclr("Hom[")
    elseif isa(hom, Mono)
        strA = catclr("Mono[")
    elseif isa(hom, Epi)
        strA = catclr("Epi[")
    elseif isa(hom, Iso)
        strA = catclr("Iso[")
    end
    res = strA*domname*strB*codname*" in "*catname*strC

    # add data type if needed
    if catdt
        dtname = dtclr(string(typeof(hom)))
        res *= " :: $dtname"
    end

    return res
end