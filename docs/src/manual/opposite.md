```@meta
CurrentModule = JuliaTopology
```

# Opposite categories

`Op(C)`, or `op(C)`, is the opposite category `Cᵒᵖ`: the same objects, with
every morphism reversed. `op` moves objects and morphisms between `C` and
`Op(C)`, and undoes itself:

```julia
C = FreeCat(2, (1 => 2,))
f = generator(C, 1)
op(f)          # a morphism of Op(C) from op(C[2]) to op(C[1])
op(op(f)) === f
```

Everything about `Op(C)` follows from `C` by duality, so nothing about it is
defined twice:

- `compose(op(g), op(f)) == op(compose(f, g))`, `id(op(X)) == op(id(X))`
- `isEpi(op(f)) == isMono(f)`, and the other way around
- `initial(Op(C)) == op(terminal(C))`, and the other way around
- `canonicalHom(op(a), op(b)) == op(canonicalHom(b, a))`
- a limit in `Op(C)` is the opposite of a colimit in `C`

The opposite of a shape has the same vertices with every generator reversed,
and the opposite of a diagram `D: J → C` is `op(D): Jᵒᵖ → Cᵒᵖ`.

## Cocones

A cocone under `D` is exactly a cone over `op(D)`, seen in the opposite
category: `Cocone(D) == Op(Cone(op(D)))`. So cocones, coslices and colimits get
their structure, checks and universal morphisms from those of cones. They are
still built and read with the morphisms of `C` itself — `Cocone(D)[legs]`,
`apex(c)`, `legs(c)`, `Hom(c₁, c₂)[u]`, `apexMorphism(m)` — which convert with
`op` as needed. Only a category's own computations, of a colimit and of the
morphism out of it, are written separately from those of limits.

## Interface Specification Assumptions

- `C` is a category, `X` an object, and `f, g` morphisms of it
- `a, b` are objects of `Op(K)` for a category `K`
- `D` is a diagram
