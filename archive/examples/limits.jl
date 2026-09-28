# # Limits and colimits
#
# Limits and colimits of finite diagrams of finite sets. To run this script
# yourself, use `julia --color=yes --project=. examples/limits.jl`.

using JuliaTopology

A, B, C = FinSet[1:4], FinSet[[:a, :b]], FinSet[[:even, :odd]]
a, b, c = ascat(A), ascat(B), ascat(C)
parity = Hom(A, C)[x -> iseven(x) ? :even : :odd, values=true]
nothing #hide

# ## Diagrams
#
# A diagram is a functor from the free category on a finite graph. Common
# shapes have shortcuts: here, the parallel pair `parity, allOdd: A ⇉ C`.

allOdd = Hom(A, C)[x -> c[:odd]]
D = parallelPair(parity, allOdd)

# ## Products
#
# A limit is a cone: an apex with a leg to each set of the diagram. The product
# of `A` and `B` has the pairs as its elements, and the projections as legs.

P = product(A, B)
apex(P)

# `A × B` is the same set, for when only the set is wanted:

cardinality(A × B)

#-

p = first(apex(P))

#-

leg(P, :X1)(p)

# ## Equalizers and pullbacks
#
# The equalizer of `parity` and `allOdd` has one element for each odd number.

E = equalizer(parity, allOdd)
collect(apex(E))

# The pullback of `parity` and a map `B → C` pairs up elements with the same
# image:

side = Hom(B, C)[y -> c[y == b[:a] ? :even : :odd]]
PB = pullback(parity, side)
collect(apex(PB))

# ## The universal property
#
# Any other cone over the same diagram factors uniquely through the limit, by
# `canonicalHom`:

X = FinSet[[:x, :y]]
x = ascat(X)
cone = Cone(discrete(A, B))[
    (X1 = Hom(X, A)[t -> a[1]], X2 = Hom(X, B)[t -> t == x[:x] ? b[:a] : b[:b]])]
canonicalHom(cone, P)

# A cone that does not commute with its diagram is rejected:

try
    Cone(D)[(X = Hom(X, A)[t -> a[2]], Y = Hom(X, C)[t -> c[:odd]])]
catch e
    showerror(stdout, e)
end

# ## Colimits
#
# A colimit is a cocone, whose apex is a set of equivalence classes, each shown
# by a representative. The coequalizer of `parity` and `allOdd` identifies
# `:even` with `:odd`, leaving one class:

Q = coequalizer(parity, allOdd)
collect(apex(Q))

# The coproduct is the disjoint union, and the pushout glues along a common
# domain:

collect(apex(coproduct(A, B)))

#-

glue = Hom(B, A)[y -> a[1]]
PO = pushout(glue, Hom(B, C)[y -> c[:odd]])
collect(apex(PO))

# ## Terminal and initial sets
#
# These are the limit and colimit of the empty diagram:

(terminal(FinSet), initial(FinSet))

#-

canonicalHom(A, terminal(FinSet))
