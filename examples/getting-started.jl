# # Getting started
#
# A first look at objects, elements and morphisms, using finite sets. To run
# this script yourself, use
# `julia --color=yes --project=. examples/getting-started.jl`.

using JuliaTopology

# ## Objects
#
# Any Julia value can be paired with the category it belongs to. `FinSet[x]`
# makes `x` an object of the category of finite sets, checking that it is one.

A, B = FinSet[1:3], FinSet[[:a, :b]]

# ## Elements
#
# The elements of a finite set form a category of their own, `@ascat A`, and
# `a[x]` is the element `x` of `A`.

a, b = @ascat(A), @ascat(B)
a[2]

#-

(2 in a, 7 in a)

# ## Morphisms
#
# A morphism from `A` to `B` is an object of the category `Hom(A, B)`. It can
# be given by its pairs of elements,

f = Hom(A, B)[[a[1] => b[:a], a[2] => b[:b], a[3] => b[:a]]]

# or by a function on elements, and is applied like one:

g = Hom(B, A)[y -> a[object(y) == :a ? 1 : 2]]
f(a[2])

# `Epi`, `Mono` and `Iso` are the surjective, injective and bijective maps:

(object(f) in Epi(A, B), object(f) in Mono(A, B))

# Morphisms compose, and isomorphisms have inverses:

g ∘ f

#-

s = Iso(A, A)[x -> a[mod1(object(x) + 1, 3)]]
inv(s)

# A map which is not in the category it is built in is rejected, with an
# explanation:

try
    Iso(A, B)[[a[1] => b[:a], a[2] => b[:b], a[3] => b[:a]]]
catch e
    showerror(stdout, e)
end

# ## Printing
#
# Values print on one line inside messages and collections, and as a tree of
# every layer, with their Julia types, in the REPL:

f
