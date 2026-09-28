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
# The elements of a finite set form a category of their own, `ascat(A)`, and
# `a[x]` is the element `x` of `A`.

a, b = ascat(A), ascat(B)
a[2]

#-

(2 in a, 7 in a)

# ## Morphisms
#
# A morphism from `A` to `B` is an object of the category `Hom(A, B)`. It can
# be given by its pairs of elements,

f = Hom(A, B)[[a[1] => b[:a], a[2] => b[:b], a[3] => b[:a]]]

# or by a function on elements, and is applied like one. With `values=true`,
# the pairs or function are written on plain values instead:

g = Hom(B, A)[y -> y == :a ? 1 : 2, values=true]
f(a[2])

# Whether a map is injective, surjective or bijective is a property of it:

(isMono(f), isEpi(f), isIso(f))

# Morphisms compose, and bijections have inverses:

g ∘ f

#-

s = Hom(A, A)[x -> mod1(x + 1, 3), values=true]
inv(s)

# A map which is not well defined is rejected, with an explanation:

try
    Hom(A, B)[[a[1] => b[:a], a[2] => b[:b]]]
catch e
    showerror(stdout, e)
end

# ## Printing
#
# Values print on one line inside messages and collections, and as a tree of
# every layer, with their Julia types, in the REPL:

f
