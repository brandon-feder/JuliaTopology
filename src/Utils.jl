"""
    struct InterfaceViolation <: Exception

Thrown by [`checkInterface`](@ref) when `object` does not satisfy the interface
required by `category`. `reason` explains which requirement failed.
"""
struct InterfaceViolation <: Exception
    object
    category
    reason::String
end

# Summarize a collection of set elements in an error message
function listElements(elems; limit::Int=3)
    shown = join((repr(object(e)) for e in first(collect(elems), limit)), ", ")
    n = length(elems)
    return n > limit ? "$shown, ... ($n in total)" : shown
end