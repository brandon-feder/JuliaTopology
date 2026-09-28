"""
    Op(C)

The opposite category `Cᵒᵖ` of a category `C`: the same objects, with every
morphism reversed. An object `X` of `C` is the object `op(X)` of `Op(C)`, and a
morphism `f: X → Y` of `C` is the morphism `op(f): op(Y) → op(X)` of `Op(C)`;
`op` undoes itself, and `op(Op(C)) == C`.

Everything about `Op(C)` follows from `C` by duality: `compose(g, f)` is
`op(compose(op(f), op(g)))`, epimorphisms and monomorphisms trade places, an
initial object of `Op(C)` is a terminal object of `C`, and so on. A cocone is
a cone in an opposite category: `Cocone(D) == Op(Cone(op(D)))`.

# Standardized Interface
- `op(C)`, `op(X)`, `op(f)` — the opposite of a category, object or morphism
- `compose`, `id`, `firstDifference`, `isEpi`, `isMono`, `isIso`, `inv`,
  `canonicalHom`, `terminal`, `initial` — by duality from `C`
- `nvertices`, `generators` — for a shape `C`, those of `C` with every
  generator reversed
"""
struct Op{CT <: Category} <: Category
    category::CT
end

"""
    GenericMorphOp(f)

The morphism `op(f): op(Y) → op(X)` of an [`Op`](@ref) category, for a
morphism `f: X → Y` of the original category. Build it with `op(f)`.
"""
struct GenericMorphOp
    morphism::OIC
end

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

# the objects of `Op(C)` are those of `C`
checkInCategory(obj, K::Op) = checkInCategory(obj, K.category)
checkInterface(obj, K::Op) = checkInterface(obj, K.category)

function checkInCategory(m::GenericMorphOp, H::Hom{<:Any, <:Any, <:Op})
    f = m.morphism

    # a morphism of `C` the other way around
    if !(f isa OIC && category(f) isa Hom &&
            domain(category(f)) == op(codomain(H)) &&
            codomain(category(f)) == op(domain(H)))
        throw(NotInCategory(m, H,
            @annotated """
            The morphism
            $TAB$(f isa OIC ? f : valclr(f))
            is not a morphism from $(op(codomain(H))) to \
            $(op(domain(H))) of $(category(H).category), so its opposite is \
            not a morphism in $H.
            """
        ))
    end
    return true
end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

"""
    op(C::Category)
    op(X)
    op(f)

The opposite of a category, `Op(C)`, or of one of its objects or morphisms,
moving between `C` and `Op(C)`; `op(op(x)) == x`.
"""
op(C::Category) = Op(C)
op(K::Op) = K.category

op(X::OIC) = OIC(object(X), Op(category(X)); force=true)
op(X::OIC{<:Any, <:Op}) = OIC(object(X), category(X).category; force=true)

function op(f::OIC{<:Any, <:Hom})
    H = category(f)
    return Hom(op(codomain(H)), op(domain(H)))[GenericMorphOp(f), force=true]
end
op(f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}) = object(f).morphism

function compose(
    g::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}},
    f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}
)
    return op(compose(op(f), op(g)))
end

id(X::OIC{<:Any, <:Op}) = op(id(op(X)))

function firstDifference(
    f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}},
    g::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}
)
    return firstDifference(op(f), op(g))
end

isEpi(f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}) = isMono(op(f))
isMono(f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}) = isEpi(op(f))
isIso(f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}) = isIso(op(f))

function Base.inv(f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}; force::Bool=false)
    return op(inv(op(f); force=force))
end

# a morphism from `a` to `b` in `Op(K)` is one from `op(b)` to `op(a)` in `K`
canonicalHom(a::OIC{<:Any, <:Op}, b::OIC{<:Any, <:Op}) = op(canonicalHom(op(b), op(a)))

# an initial object of `Op(K)` is a terminal object of `K`, and vice versa
terminal(K::Op) = op(initial(K.category))
initial(K::Op) = op(terminal(K.category))

# a shape's opposite has the same vertices, with every generator reversed
nvertices(K::Op) = nvertices(K.category)
generators(K::Op) = map(ends -> last(ends) => first(ends), generators(K.category))

# =========================================================
# ======================= PRINTING ========================
# =========================================================

name(K::Op) = "$(name(K.category))ᵒᵖ"

name(f::OIC{GenericMorphOp, <:Hom{<:Any, <:Any, <:Op}}) = "$(shortName(op(f)))ᵒᵖ"
