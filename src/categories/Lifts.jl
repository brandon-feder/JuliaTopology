"""
    CatLifts()

Category consisting of forgetful functors which
determine how objects-in-categories can be lifted to
objects-in-"super-categories".
"""
struct CatLifts <: Category
    liftRegistry::Vector{
        ObjectInCategory{F, Hom{D, C, CatCat}} 
            where {F, D<:Category, C<:Category}
    }
end

CatLifts() = CatLifts([])

"""
    Lifts

The global instance of [`CatLifts`](@ref), holding every registered lift.
"""
const Lifts = CatLifts()

"""
    push!(::CatLifts, morphism)

Register a functor (a morphism between objects in `Cat`) as a lift.
"""
function Base.push!(
    lifts::CatLifts, 
    morphism::ObjectInCategory{F, Hom{D, C, CatCat}} 
) where {F, D<:Category, C<:Category}
    push!(lifts.liftRegistry, morphism)
    return lifts
end

"""
    _liftPath(sub, sup) -> Union{Nothing, Vector{Tuple{Any,Any}}}

Plain BFS over the registered lifts.
"""
function _liftPath(sub::Category, sup::Category)
    sub == sup && return Tuple{Any,Any}[]

    visited = Any[sub]
    queue = Any[sub]
    arrivedVia = Tuple{Any,Any,Any}[]  # (node, predecessor, functor used to arrive at node)

    while !isempty(queue)
        current = popfirst!(queue)
        for m in Lifts.liftRegistry
            object(m.category.domain) == current || continue
            target = object(m.category.codomain)
            target in visited && continue

            push!(visited, target)
            push!(arrivedVia, (target, current, object(m)))

            if target == sup
                path = Tuple{Any,Any}[(object(m), target)]
                node = current
                while node != sub
                    idx = findfirst(x -> x[1] == node, arrivedVia)
                    pred, functor = arrivedVia[idx][2], arrivedVia[idx][3]
                    pushfirst!(path, (functor, node))
                    node = pred
                end
                return path
            end

            push!(queue, target)
        end
    end

    return nothing
end

"""
    canLift(sub, sup)

Check whether objects of `sub` can be lifted to `sup` — reflexivity
(`sub == sup`) or reachability through the registered lifts.
"""
canLift(sub::Category, sup::Category) = sub == sup || _liftPath(sub, sup) !== nothing

"""
    lift(oic::ObjectInCategory, sup; force=false)

Convert `oic` into an object of the category `sup` by walking the registered
lift path from `oic.category` to `sup` and, at each hop, calling that hop's
functor on the current `ObjectInCategory`. Throws a descriptive error if `sup`
is unreachable. Returns a fresh `ObjectInCategory(liftedObject, sup)`.

`oic` itself is already valid, so the first hop reuses it. The result of each
functor is re-validated by the `ObjectInCategory` constructor, as is the final
object, which catches functors that produce invalid objects. Pass `force=true`
to skip those checks.
"""
function lift(oic::ObjectInCategory, sup::Category; force::Bool=false)
    path = _liftPath(oic.category, sup)
    path === nothing && error("lift: no registered lift path from $(oic.category) to $sup")

    current = oic
    for (functor, nextCategory) in path
        current = ObjectInCategory(functor(current), nextCategory; force=force)
    end
    return current
end

"""
    Base.getindex(C::Category, oic::ObjectInCategory; force=false)

Syntactic sugar to write `C[oic]` for `lift(oic, C)`; `force` is passed on to
[`lift`](@ref).
"""
Base.getindex(C::Category, oic::ObjectInCategory; force::Bool=false) = lift(oic, C; force=force)
