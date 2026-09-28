# # Printing and error messages
#
# A tour of how JuliaTopology prints objects, categories and errors. Colors are
# shown only when the output supports them; to run this script yourself in a
# terminal, force them with
# `julia --color=yes --project=. examples/errors.jl`.

using JuliaTopology
using StyledStrings: Face, withfaces
import JuliaTopology: checkInCategory, checkInterface, name
using JuliaTopology: @checkCallable

## Run `thunk` and print the error it throws, or say that none was thrown
function demo(thunk)
    try
        thunk()
        println("(no error)")
    catch e
        showerror(stdout, e)
    end
end
nothing #hide

# ## Compact display
#
# `show(io, x)`, used inside messages and collections, gives one line per value.

S = FinSet[Set([1, 2, 3])]
x = OIC(1, ascat(S); force=true)
f = OIC(:f, Hom(S, S); force=true)   ## a morphism with no behavior defined
g = OIC(:g, Hom(x, x); force=true)   ## a morphism between elements of S

println(S)            ## an object in a category
println(x)            ## an element of ascat(S)
println(f)            ## a morphism in FinSet
println(g)            ## a morphism in ascat(S)
println(FinSet)       ## a category
println(ascat(S))    ## an object regarded as a category
println(Hom(S, S))    ## a Hom category
println([x, x])       ## inside a collection

# ## Tree display
#
# `show(io, MIME"text/plain"(), x)` is what the REPL prints for a single value,
# laying out every layer as a tree.

for v in (S, x, f, g, FinSet, Hom(S, S))
    show(stdout, MIME"text/plain"(), v)
    println("\n")
end

# ## Default maps of a morphism
#
# A morphism which does not define how it maps elements explains which method
# to overload. The call and method lines are highlighted as Julia code.

demo(() -> f(x))

#-

demo(() -> f(g))

# ## Overload hints elsewhere
#
# A minimal category, with no interface check and no canonical morphisms:

struct CatToy <: Category end
name(::CatToy) = "Toy"
Toy = CatToy()
checkInCategory(::Union{Int, String}, ::CatToy) = true
nothing #hide

# No canonical morphism between two objects, or between two categories:

demo(() -> canonicalHom(S, S))

#-

demo(() -> canonicalHom(Toy, FinSet))

# A value the category does not say anything about:

demo(() -> OIC(3.5, Toy))

# `@checkCallable`: here, strings in `Toy` must be callable with an `Int`.

checkInterface(obj::String, cat::CatToy) = @checkCallable obj cat Tuple{Int}
demo(() -> OIC("hello", Toy))

# A type which iterates but has no length is not a finite set:

struct Bag end
Base.iterate(::Bag, state=nothing) = nothing
demo(() -> FinSet[Bag()])

# FinSet's check that iterating over its objects has a known length:

struct Bag2 end
Base.iterate(::Bag2, state=nothing) = nothing
Base.length(::Bag2) = 0
Base.eltype(::Type{Bag2}) = Int
Base.in(::Int, ::Bag2) = false
Base.IteratorSize(::Type{OIC{Bag2, CatFinSet}}) = Base.SizeUnknown()
demo(() -> FinSet[Bag2()])

# ## Plain values
#
# Values not wrapped in a category get their own color.

demo(() -> Hom(S, 3))

#-

demo(() -> FinCard[3.5])

#-

demo(() -> OIC(7, ascat(S)))

# ## How colors are applied
#
# Colors are attached to the text rather than baked in as escape codes, so
# `repr` and `string` give plain text.

println(repr(repr(S)))

# Code snippets in messages are syntax highlighted as Julia:

println(JuliaTopology.codeclr("canonicalHom(A::OIC{<:Any, CatFinSet}, B::CatFinCard)"))

# `@annotated` builds a message which keeps the colors of what it interpolates:

println(JuliaTopology.@annotated "The object $x and the value $(JuliaTopology.valclr(7))")

# Each color is a face, which can be restyled, here only temporarily. To change
# it permanently, set it in `~/.julia/config/faces.toml`, e.g.
#
# ```toml
# [juliatopology]
# object = { foreground = "red" }
# ```

withfaces(:juliatopology_object => Face(foreground=:red, underline=true)) do
    println(S)
end

# Colors can be switched off, and back on, at any time:

JuliaTopology.setColorfulOutput!(false)
println(S)
JuliaTopology.setColorfulOutput!(true)
println(S)
