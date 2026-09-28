# # Shapes, diagrams and cones
#
# This tutorial builds everything from a single free category: its shapes,
# diagrams in it, functor categories and natural transformations between
# diagrams, cones and cocones, and opposites.

using JuliaTopology

# ## Free categories
#
# A free category has the vertices `1:n` as its objects, and its arrows are
# given as `source => target` pairs, arrow `k` being the `k`-th pair. Nothing
# is named: vertices and arrows are only numbered. Here is the free category
# on `1 → 2 → 3` together with a second arrow `1 → 3`:

C = FreeCat(3, (1 => 2, 2 => 3, 1 => 3))
X, Y, Z = C[1], C[2], C[3]
p, q, r = generator(C, 1), generator(C, 2), generator(C, 3)
nothing #hide

# Its morphisms are the paths along the arrows. An arrow prints as
# `source → target`, and a path as its arrows composed right to left:

q ∘ p

# When several arrows are parallel, each is marked with its number, as in the
# two arrows `1 →₁ 2` and `1 →₂ 2` of a parallel pair:

generator(parallelPairShape(), 2)

# A path can also be written as the tuple of its arrows, in the order they are
# followed, and the empty path is the identity:

Hom(X, Z)[(1, 2)] == q ∘ p, Hom(X, X)[()] == id(X)

# A path has to follow the arrows:

try
    Hom(X, Z)[(2, 1)]
catch e
    showerror(stdout, e)
end

# In a free category nothing is equal unless it is the same path, so `r` and
# `q ∘ p` are two different morphisms `X → Z`. `firstDifference` compares
# morphisms; for paths, they differ as a whole or not at all:

agrees(q ∘ p, compose(q, p)), agrees(r, q ∘ p)

# ## Shapes
#
# A shape is a category that diagrams are functors out of. All that
# diagrams, functor categories and cones need to know about a shape `J` is
# `nvertices(J)` and `generators(J)`. Every free category is a shape, and the
# common ones are built in:

parallelPairShape(), cospanShape(), spanShape(), discreteShape(2), emptyShape()

# Any other category becomes a shape by defining those two functions. Here is
# the walking arrow, with two objects and one arrow between them:

struct WalkingArrow <: Category end
JuliaTopology.nvertices(::WalkingArrow) = 2
JuliaTopology.generators(::WalkingArrow) = (1 => 2,)
JuliaTopology.checkInCategory(x, W::WalkingArrow) =
    x in (1, 2) || throw(NotInCategory(x, W, "not a vertex"))
W = WalkingArrow()
vertices(W), generators(W)

# ## Diagrams
#
# A diagram of shape `J` in `C` gives an object for each vertex and a morphism
# for each arrow, both listed in order:

J = parallelPairShape()
D = diagram(J, (X, Z), (r, q ∘ p))

# The usual shapes also have their own constructors, which put the objects in
# the shape's vertex order:

D == parallelPair(r, q ∘ p)

#-

objects(cospan(q, r)), arrows(cospan(q, r))

# A diagram sends vertices to objects and paths of its shape to the composites
# along them:

D(J[2]), D(generator(J, 1))

# Each morphism must go between the objects at the ends of its arrow:

try
    diagram(J, (X, Z), (r, p))
catch e
    showerror(stdout, e)
end

# ## Functor categories and natural transformations
#
# The functors from `J` to `C` form the category `FunctorCat(J, C)`. The
# diagonal functor `Δ: C → [J, C]` sends an object to the constant diagram at
# it:

K = FunctorCat(J, C)
Δ = diagonal(J, C)
objects(object(Δ(Z))), arrows(object(Δ(Z)))

# A natural transformation is written as its tuple of components, one for
# each vertex. Here is one from `parallelPair(r, r)` to the constant diagram at
# `Z`, with components `r` at vertex 1 and `id(Z)` at vertex 2. It is natural
# because `id(Z) ∘ r == r` for both arrows:

η = Hom(K[parallelPair(r, r)], Δ(Z))[(r, id(Z))]
components(η)

# From `D = parallelPair(r, q ∘ p)`, however, the same components are not
# natural, since the square at the second arrow needs `id(Z) ∘ (q ∘ p) == r`:

try
    Hom(K[D], Δ(Z))[(r, id(Z))]
catch e
    showerror(stdout, e)
end

# Naturality is checked in the arrow category of `C`, whose objects are
# morphisms and whose morphisms are commuting squares: the components are its
# objects, and each arrow of `J` must give a square between them. Here the
# square at the second arrow goes from the component `1 → 3` (that is, `r`) to
# the component `id`, and it does not commute.

# The check turns each functor into a [`diagram`](@ref) listing its objects
# and morphisms. A diagram is its own diagram, and a functor out of a free
# category is evaluated on its vertices and generators. So natural
# transformations between any functors out of `C` can be checked, e.g. between
# identity functors:

I = FunctorCat(C, C)[id(Cat[C])]
objects(diagram(id(Cat[C])))

#-

components(id(I))

# ### Natural transformations that cannot be checked
#
# A functor out of another shape, defined only by how it acts, cannot be
# listed in this way. Here is a functor `W → C` picking out `p: X → Y`, which
# says what it does but not how to list it:

struct PickP end
JuliaTopology.checkInCategory(::PickP, ::Hom{WalkingArrow, FreeCat, CatCat}) = true
F = Hom(Cat[W], Cat[C])[PickP()]
M = FunctorCat(W, C)
nothing #hide

# Its natural transformations cannot be checked:

try
    Hom(M[F], M[F])[(id(X), id(Y))]
catch e
    showerror(stdout, e)
end

# If you know one is natural, `force=true` trusts it, and it composes like any
# other:

θ = Hom(M[F], M[F])[(id(X), id(Y)), force=true]
agrees(θ ∘ θ, θ)

# Alternatively, give the functor a diagram, as the error suggests. After that
# its natural transformations are checked, and it gets an identity:

JuliaTopology.diagram(::OIC{PickP, <:Hom{WalkingArrow, <:Any, CatCat}}) =
    diagram(W, (X, Y), (p,))
Hom(M[F], M[F])[(id(X), id(Y))] isa OIC, components(id(M[F]))

# ## Cones and cocones
#
# A cone over a diagram is an apex together with one leg to each vertex's
# object, commuting with the diagram's arrows. It is written as its legs, in
# vertex order, and the apex is read off the first leg. Over `parallelPair(r, r)`,
# the legs `id(X)` and `r` form a cone with apex `X`:

c = Cone(parallelPair(r, r))[id(X), r]
apex(c), legs(c), leg(c, 2)

# Over the cospan `Y → Z ← X` of `q` and `r`, there is no cone with apex `X`
# and legs `p` and `id(X)`: the two paths to `Z`, `q ∘ p` and `r`, differ.

try
    Cone(cospan(q, r))[p, id(X), r]
catch e
    showerror(stdout, e)
end

# The legs of a cone with apex `X` are a natural transformation from the
# constant diagram at `X`, so a cone that does not commute fails as a
# natural transformation does: the square at the first arrow, from the leg
# `1 → 2` to the leg `1 → 3`, does not commute.

# A cone over the empty diagram has no legs to read its apex off, so the apex is
# given explicitly:

apex(Cone(diagram(emptyShape(), C))[X, ()])

# A cocone has legs from each vertex's object into its apex. It is a cone in the
# opposite category, but it is written with the morphisms of `C` itself:

d = Cocone(discrete(X, Y))[q ∘ p, q]
apex(d), legs(d)

# Slices and coslices are cones and cocones over a single object, so they take a
# single leg. A morphism of cones is a morphism between their apexes that
# commutes with the legs, e.g. `p` from `q ∘ p` to `q` over `Z`:

S = Slice(Z)
m = Hom(S[q ∘ p], S[q])[p]
apexMorphism(m)

#-

try
    Hom(S[r], S[q])[p]
catch e
    showerror(stdout, e)
end

# ## Opposites
#
# The opposite of a shape has the same vertices, with each arrow reversed, and
# the opposite of a diagram sends each vertex and arrow to the opposite of its
# image:

generators(op(cospanShape()))

#-

arrows(op(cospan(q, r)))

# Limits and colimits are the terminal cones and initial cocones:
# `limit(D) == terminal(Cone(D))`. A category computes them by defining
# `terminal` for its cones, which free categories do not, so here they throw:

try
    limit(D)
catch e
    showerror(stdout, e)
end
