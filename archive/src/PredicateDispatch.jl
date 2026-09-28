# """
#     DispatchRule

# Stores the argument types, predicate, and a function to be called.
# """
# struct DispatchRule
#     argtypes::Tuple{Vararg{Type}}
#     predicate::Union{Nothing,Function}
#     impl::Function
# end

# """
#     Dispatcher

# A callable, predicate-based dispatch table.
# """
# struct Dispatcher
#     name::Symbol
#     rules::Vector{DispatchRule}
# end
# Dispatcher(name::Symbol) = Dispatcher(name, DispatchRule[])

# """
#     registerDispatch(d::Dispatcher, argtypes::Tuple, predicate::Function, 
#         impl::Function)
#     registerDispatch(d::Dispatcher, argtypes::Tuple, impl::Function)

# Register a dispatch rule on `d`. With a `predicate`, `d` calling `args...`
# invokes `impl(args...)` when the runtime types of `args` match `argtypes`
# AND `predicate(args...) === true`.

# The 3-argument form registers an **unconditional** rule: it matches purely
# by `argtypes`, exactly like ordinary Julia multiple dispatch, with no
# predicate call at all.

# Registering an identical `(argtypes, predicate)` pair again replaces the 
# existing rule with a warning.
# """
# function registerDispatch(d::Dispatcher, argtypes::Tuple, predicate::Union{Nothing,Function}, impl::Function)
#     for t in argtypes
#         t isa Type || throw(ArgumentError(
#             "registerDispatch on dispatcher $(repr(d.name)): each element of argtypes must be a Type, got $(repr(t))"))
#     end

#     rule = DispatchRule(argtypes, predicate, impl)

#     idx = findfirst(r -> r.argtypes == argtypes && r.predicate === predicate, d.rules)
#     if idx !== nothing
#         @warn "replacing rule for dispatcher $(string(d.name)) with argtypes $(argtypes) and identical predicate"

#         d.rules[idx] = rule
#     else
#         push!(d.rules, rule)
#     end

#     return d
# end

# registerDispatch(d::Dispatcher, argtypes::Tuple, impl::Function) =
#     registerDispatch(d, argtypes, nothing, impl)

# _atLeastAsSpecific(t1::Tuple, t2::Tuple) =
#     length(t1) == length(t2) && all(a <: b for (a, b) in zip(t1, t2))

# _strictlyMoreSpecific(t1::Tuple, t2::Tuple) =
#     _atLeastAsSpecific(t1, t2) && !_atLeastAsSpecific(t2, t1)

# function (d::Dispatcher)(args...)
#     matches = DispatchRule[]
#     for rule in d.rules
#         length(rule.argtypes) == length(args) || continue
#         all(isa(a, t) for (a, t) in zip(args, rule.argtypes)) || continue

#         if rule.predicate === nothing
#             push!(matches, rule)
#             continue
#         end

#         pred_result = try
#             rule.predicate(args...)
#         catch e
#             rethrow(ErrorException(
#                 "registerDispatch predicate for dispatcher $(repr(d.name)) with argtypes $(rule.argtypes) " *
#                 "threw an error while testing args $(args): $e"))
#         end
#         pred_result === true || continue

#         push!(matches, rule)
#     end

#     isempty(matches) && throw(NoDispatchMatchError(d.name, args))
#     length(matches) == 1 && return matches[1].impl(args...)

#     maximal = filter(matches) do r
#         !any(o -> o !== r && _strictlyMoreSpecific(o.argtypes, r.argtypes), matches)
#     end
#     length(maximal) == 1 && return maximal[1].impl(args...)
#     throw(AmbiguousDispatchError(d.name, args, maximal))
# end

# """
#     _dispatchTypeExpr(mod::Module, typeExpr) -> (resolvedExpr, freeVars::Vector{Symbol})

# Walks a type annotation AST (e.g. `:(ObjectInCategory{Int, CatT})`), treating any bare
# symbol that ISN'T already a real type in `mod` as a free type variable rather than an
# undefined reference. Returns the same shape of expression back, plus the list of symbols
# that turned out to be free (in first-appearance order, not yet deduplicated).
# """
# function _dispatchTypeExpr(mod::Module, typeExpr)
#     if typeExpr isa Symbol
#         if isdefined(mod, typeExpr) && getfield(mod, typeExpr) isa Type
#             return typeExpr, Symbol[]
#         else
#             return typeExpr, Symbol[typeExpr]
#         end
#     elseif Meta.isexpr(typeExpr, :curly)
#         base = typeExpr.args[1]
#         freeVars = Symbol[]
#         params = Any[]
#         for p in typeExpr.args[2:end]
#             pExpr, pFree = _dispatchTypeExpr(mod, p)
#             push!(params, pExpr)
#             append!(freeVars, pFree)
#         end
#         return Expr(:curly, base, params...), freeVars
#     else
#         return typeExpr, Symbol[]
#     end
# end

# """
#     @dispatch f(a::T, b::S) if predicateExpr
#         implExpr
#     end

# Sugar for `registerDispatch`. `f` must already be bound to a [`Dispatcher`](@ref).
# Expands to `registerDispatch(f, (T, S), (a, b) -> predicateExpr, (a, b) -> implExpr)`.
# Untyped arguments (e.g. plain `a`) default to argtype `Any`.

# When `predicateExpr` is the literal `true`, no predicate closure is built at
# all. This expands to the unconditional 3-argument `registerDispatch(f, (T, S), (a, b) -> implExpr)`
# instead, matching purely by argument type with zero predicate-call overhead.

# A parametric type annotation, e.g. `oic::ObjectInCategory{ObjT, CatT}`, registers the
# real parametric type, not just the base type. Each parameter symbol is checked against
# the calling module: if it's already a real type (like `Int`), it's used concretely; if
# not (like `ObjT`/`CatT` above), it's treated as a free type variable via an implicit
# `where` clause. So `oic::ObjectInCategory{Int, CatT}` registers as
# `ObjectInCategory{Int, CatT} where CatT` — genuinely more specific than bare
# `ObjectInCategory` — while `oic::ObjectInCategory{ObjT, CatT}` registers as
# `ObjectInCategory{ObjT, CatT} where {ObjT, CatT}`, which is exactly the bare type. Julia's
# own `<:` then drives specificity resolution between rules the same way it already does
# for non-parametric types.
# """
# macro dispatch(sig, guarded)
#     Meta.isexpr(sig, :call) ||
#         error("@dispatch: expected a call-form signature like `f(a::T, b::S)`, got: $sig")
#     Meta.isexpr(guarded, :if) ||
#         error("@dispatch: expected `if COND ... end` as the second form, got: $guarded")
#     length(guarded.args) == 2 ||
#         error("@dispatch: `else`/`elseif` are not supported.")
#     cond, body = guarded.args

#     fname = sig.args[1]
#     fname isa Symbol ||
#         error("@dispatch: dispatcher name must be a plain identifier bound to an existing " *
#               "Dispatcher (type-parameterized signatures like `f{T}(...)` are not supported), got: $fname")

#     rawargs = sig.args[2:end]
#     if !isempty(rawargs) && Meta.isexpr(rawargs[1], :parameters)
#         error("@dispatch: keyword arguments are not supported in dispatch signatures, got: $sig")
#     end

#     argnames = Symbol[]
#     argtypes = Any[]
#     for a in rawargs
#         if a isa Symbol
#             push!(argnames, a)
#             push!(argtypes, :Any)
#         elseif Meta.isexpr(a, :(::)) && length(a.args) == 2
#             push!(argnames, a.args[1]::Symbol)
#             typeExpr = a.args[2]
#             resolvedType, freeVars = _dispatchTypeExpr(__module__, typeExpr)
#             freeVars = unique(freeVars)
#             push!(argtypes, isempty(freeVars) ? resolvedType : Expr(:where, resolvedType, freeVars...))
#         else
#             error("@dispatch: unsupported argument form `$a` in signature $sig. Only " *
#                 "`name` or `name::Type` are supported (no splats, keyword args, defaults, or " *
#                 "anonymous `::Type` args, since a name is required to build the predicate/impl).")
#         end
#     end

#     impl = Expr(:->, Expr(:tuple, argnames...), body)
#     argtypes_tuple = Expr(:tuple, argtypes...)

#     call = if cond === true
#         Expr(:call, GlobalRef(@__MODULE__, :registerDispatch), fname, argtypes_tuple, impl)
#     else
#         predicate = Expr(:->, Expr(:tuple, argnames...), cond)
#         Expr(:call, GlobalRef(@__MODULE__, :registerDispatch), fname, argtypes_tuple, predicate, impl)
#     end

#     return esc(call)
# end

# """
#     NoDispatchMatchError(dispatcher_name, args)

# Thrown when calling a [`Dispatcher`](@ref) and no registered rule matches
# the given arguments.
# """
# struct NoDispatchMatchError <: Exception
#     dispatcher_name::Symbol
#     args::Tuple
# end

# function Base.showerror(io::IO, e::NoDispatchMatchError)
#     print(io, "NoDispatchMatchError: no matching dispatch rule for dispatcher ", repr(e.dispatcher_name),
#           " with arguments ", _describe_args(e.args))
# end

# """
#     AmbiguousDispatchError(dispatcher_name, args, matches)

# Thrown when calling a [`Dispatcher`](@ref) and more than one registered rule
# matches the given arguments.
# """
# struct AmbiguousDispatchError <: Exception
#     dispatcher_name::Symbol
#     args::Tuple
#     matches::Vector{DispatchRule}
# end

# function Base.showerror(io::IO, e::AmbiguousDispatchError)
#     println(io, "AmbiguousDispatchError: ", length(e.matches),
#             " matching dispatch rules for dispatcher ", repr(e.dispatcher_name),
#             " with arguments ", _describe_args(e.args), ":")
#     for (i, rule) in enumerate(e.matches)
#         println(io, "  [$i] argtypes=", rule.argtypes, ", predicate=", rule.predicate)
#     end
# end

# _describe_args(args::Tuple) = "(" * join(("$(repr(a))::$(typeof(a))" for a in args), ", ") * ")"
