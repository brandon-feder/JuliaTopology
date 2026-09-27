# # Comma categories
#
# A tour of comma categories, slices and coslices over FinSet. To run this
# script yourself, use `julia --color=yes --project=. examples/comma.jl`.

using JuliaTopology

X, A, B = FinSet[1:2], FinSet[1:3], FinSet[1:4]
x, a, b = @ascat(X), @ascat(A), @ascat(B)
nothing #hide

# ## The arrow category
#
# `Id ↓ Id` is the arrow category of FinSet: its objects are maps, and its
# morphisms are commuting squares.

I = id(Cat[FinSet])
K = I ↓ I

#-

h = Hom(A, X)[t -> x[mod1(object(t), 2)]]
println(K[ObjComma(A, X, h)])

# ## Slices
#
# The slice over `X` has the maps into `X` as its objects.

S = Slice(X)
f = S[h]
g = S[Hom(B, X)[t -> x[mod1(object(t), 2)]]]
println(f, "\n", g)

# A morphism of the slice is a map `A → B` making the triangle commute:

println(Hom(f, g)[Mono(A, B)[t -> b[object(t)]]])

# A map which does not commute is rejected:

try
    Hom(f, g)[Hom(A, B)[t -> b[object(t) + 1]]]
catch e
    showerror(stdout, e)
end

# `id(X)` is the terminal object, and `f` is its own unique morphism into it:

println(canonicalHom(f, terminal(S)))

# ## Coslices
#
# Dually, the coslice under `X` has the maps out of `X` as its objects, and
# `id(X)` is its initial object.

C = Coslice(X)
k = C[Hom(X, A)[t -> a[object(t)]]]
println(canonicalHom(initial(C), k))
