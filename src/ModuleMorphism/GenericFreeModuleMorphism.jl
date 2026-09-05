struct GenericFreeModuleMorphism
    domain::ObjectInCategory{GenericFreeModule, FreeModule}
    codomain::ObjectInCategory{GenericFreeModule, FreeModule}
    matEntry::FunctionWrapper

    function GenericFreeModuleMorphism(
        domain::ObjectInCategory{GenericFreeModule, FreeModule},
        codomain::ObjectInCategory{GenericFreeModule, FreeModule},
        matEntry::Function
    )
        @assert eltype(domain) == eltype(codomain)
        # TODO: @assert areIsomorphic(ring(domain), ring(codomain))
        matEntry = FunctionWrapper{eltype(domain), Tuple{Int, Int}}(matEntry)
        return new(domain, codomain, matEntry)
    end
end

inCategory(obj::GenericFreeModuleMorphism, ::Type{FreeModuleMorphism}) = true

function domain(
    obj::ObjectInCategory{GenericFreeModuleMorphism, FreeModuleMorphism}
)
    return obj.object.domain
end

function codomain(
    obj::ObjectInCategory{GenericFreeModuleMorphism, FreeModuleMorphism}
)
    return obj.object.codomain
end

function rank(
    obj::ObjectInCategory{GenericFreeModuleMorphism, FreeModuleMorphism}
)
    m, n = dimension(domain(obj)), dimension(codomain(obj))

    M = Nemo.zero_matrix(ring(domain(obj)).object.field, m, n) # TODO: Don't allocate large matrix
    for i in 1:m
        for j in 1:n
            M[i, j] = obj.object.matEntry(i, j)
        end
    end
    return Nemo.rank(M)
end
