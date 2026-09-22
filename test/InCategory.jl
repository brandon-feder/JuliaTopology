import JuliaTopology: checkInCategory

struct ToyCatInC <: Category end
struct ToyCatInD <: Category end
inCategory(x::Int, ::ToyCatInC) = x > 0
inCategory(x::Int, ::ToyCatInD) = x > 0
checkInCategory(x::Int, c::ToyCatInD) =
    x > 0 || throw(NotInCategory(x, c, "$x is not positive"))

@testset "checkInCategory" begin
    # default: plain assertion
    @test checkInCategory(1, ToyCatInC()) === true
    @test_throws AssertionError checkInCategory(-1, ToyCatInC())

    # overload: informative exception
    @test checkInCategory(1, ToyCatInD()) === true
    err = try checkInCategory(-1, ToyCatInD()) catch e e end
    @test err isa NotInCategory
    @test occursin("-1 is not positive", sprint(showerror, err))

    # the OIC constructor goes through checkInCategory
    @test_throws NotInCategory ObjectInCategory(-1, ToyCatInD())

    # FinSet tuple elements
    X = FinSet[[:a, :b, :c]]
    @test (2, :b) in (@ascat X)
    @test !((5, :b) in (@ascat X))
    @test_throws NotInCategory (@ascat X)[(5, :b)]
    @test_throws NotInCategory (@ascat X)[(2, :c)]
end

@testset "checkInterface errors" begin
    import JuliaTopology: checkInterface

    # missing methods are named in the message
    struct NoSetMethods end
    err = try checkInterface(NoSetMethods(), FinSet) catch e e end
    @test err isa InterfaceViolation
    @test occursin("cardinality", sprint(showerror, err))

    # GenericMorphFinSet
    A = FinSet[[1, 2, 3]]
    B = FinSet[[:a, :b]]
    H = Hom(A, B)
    a, b = collect(A), collect(B)   # elements as OICs
    good = GenericMorphFinSet(A, B, Dict(a[1] => b[1], a[2] => b[2], a[3] => b[1]))
    @test checkInterface(good, H) === true

    partial = GenericMorphFinSet(A, B, Dict(a[1] => b[1], a[2] => b[2]))
    err = try checkInterface(partial, H) catch e e end
    @test err isa InterfaceViolation
    @test occursin("missing (3, 3)", sprint(showerror, err))

    stray = (@ascat B)[(1, :a)]
    err = try checkInterface(GenericMorphFinSet(A, B,
        Dict(a[1] => b[1], a[2] => b[2], a[3] => b[1], stray => b[1])), H) catch e e end
    @test err isa InterfaceViolation
    @test occursin("not in the domain", sprint(showerror, err))

    outside = (@ascat FinSet[[:z]])[(1, :z)]
    err = try checkInterface(GenericMorphFinSet(A, B,
        Dict(a[1] => b[1], a[2] => b[2], a[3] => outside)), H) catch e e end
    @test err isa InterfaceViolation
    @test occursin("outside the codomain", sprint(showerror, err))
end

@testset "ObjectInCategory force flag" begin
    # invalid object is rejected by default, accepted with force=true
    @test_throws NotInCategory ObjectInCategory(-1, ToyCatInD())
    o = ObjectInCategory(-1, ToyCatInD(); force=true)
    @test o isa ObjectInCategory
    @test object(o) == -1

    # the interface check is skipped too: no warning from the fallback
    @test_logs ObjectInCategory(1, ToyCatInC(); force=true)
    @test_logs (:warn, r"checkInterface\(\) not overloaded") ObjectInCategory(1, ToyCatInC())

    # explicit-parameter constructor accepts it as well
    @test ObjectInCategory{Int, ToyCatInD}(-1, ToyCatInD(); force=true) isa ObjectInCategory
end

@testset "getindex force flag" begin
    @test_throws NotInCategory ToyCatInD()[-1]
    o = ToyCatInD()[-1, force=true]
    @test o isa ObjectInCategory && object(o) == -1
    @test ToyCatInD()[1, force=false] == ObjectInCategory(1, ToyCatInD())

    # FinSet element access needs no check, and yields valid elements
    X = FinSet[[:a, :b, :c]]
    @test object(X[2]) == (2, :b)
    @test_throws BoundsError X[4]
end

struct ToyCatLfA <: Category end
struct ToyCatLfB <: Category end
struct ToyFunctorLf end
inCategory(x::Int, ::ToyCatLfA) = true
inCategory(x::Int, ::ToyCatLfB) = x > 0
(::ToyFunctorLf)(oic::ObjectInCategory) = -object(oic)   # lands outside ToyCatLfB

@testset "lift force flag" begin
    push!(Lifts, ObjectInCategory(ToyFunctorLf(),
        Hom(Cat[ToyCatLfA()], Cat[ToyCatLfB()]); force=true))
    oic = ObjectInCategory(5, ToyCatLfA())

    @test_throws AssertionError lift(oic, ToyCatLfB())
    @test_throws AssertionError ToyCatLfB()[oic]
    @test object(lift(oic, ToyCatLfB(); force=true)) == -5
    @test object(ToyCatLfB()[oic, force=true]) == -5
end

@testset "Hom(D, C)[dict] builds a set map" begin
    D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b]]
    H = Hom(D, C)
    f = H[Dict(D[i] => C[mod1(i, 2)] for i in 1:cardinality(D))]
    @test f isa ObjectInCategory
    @test category(f) == H
    @test object(f) isa GenericMorphFinSet
    @test f(D[3]) == C[1]

    # same as spelling out GenericMorphFinSet
    dict = Dict(D[i] => C[mod1(i, 2)] for i in 1:cardinality(D))
    @test object(f).dict == object(H[GenericMorphFinSet(D, C, dict)]).dict

    # the map is still validated, unless forced
    @test_throws InterfaceViolation H[Dict(D[1] => C[1])]
    @test H[Dict(D[1] => C[1]), force=true] isa ObjectInCategory
end

@testset "Hom, Epi, Mono, Iso set maps" begin
    D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b]]
    E = FinSet[[:x, :y, :z]]
    inj = Dict(C[1] => E[1], C[2] => E[2])                       # C -> E, injective
    surj = Dict(D[1] => C[1], D[2] => C[2], D[3] => C[1])        # D -> C, surjective
    bij = Dict(D[i] => E[i] for i in 1:3)                        # D -> E, bijective

    for (kind, ok, dom, cod) in ((Hom, inj, C, E), (Mono, inj, C, E),
                                 (Epi, surj, D, C), (Iso, bij, D, E))
        H = kind(dom, cod)
        f = H[ok]
        @test category(f) == H
        @test object(f) isa GenericMorphFinSet
    end

    # the callable interface works on every kind
    @test Iso(D, E)[bij](D[2]) == E[2]

    # each kind rejects maps that lack its property
    @test_throws NotInCategory Mono(D, C)[surj]   # collapses 1 and 3
    @test_throws NotInCategory Epi(C, E)[inj]     # misses :z
    @test_throws NotInCategory Iso(D, C)[surj]    # not injective
    @test_throws NotInCategory Iso(C, E)[inj]     # not surjective
    err = try Mono(D, C)[surj] catch e e end
    @test occursin("not injective", sprint(showerror, err))
    @test Mono(D, C)[surj, force=true] isa ObjectInCategory

    # inCategory agrees with checkInCategory
    m = GenericMorphFinSet(D, C, surj)
    @test !(m in Mono(D, C))
    @test m in Epi(D, C)
    @test m in Hom(D, C)
end

@testset "Hom(D, C)[pairs] uses plain elements" begin
    D, C = FinSet[[10, 20, 30]], FinSet[[:a, :b]]
    H = Hom(D, C)
    f = H[[10 => :a, 20 => :b, 30 => :a]]
    @test category(f) == H
    @test f(D[2]) == C[2]
    @test object(f).dict == Dict(D[1] => C[1], D[2] => C[2], D[3] => C[1])

    # a generator-style expression, and every kind of Hom
    D5, C6 = FinSet[collect(1:5)], FinSet[collect(2:6)]
    g = Iso(D5, C6)[[i => i + 1 for i in 1:5]]
    @test g(D5[5]) == C6[5]
    @test Epi(D, C)[[10 => :a, 20 => :b, 30 => :a]] isa ObjectInCategory
    @test Mono(C, D)[[:a => 10, :b => 20]] isa ObjectInCategory

    # elements may be given as element objects too
    @test H[[D[1] => :a, 20 => C[2], 30 => :a]] isa ObjectInCategory

    # bad input
    err = try H[[10 => :a, 99 => :b]] catch e e end
    @test err isa ArgumentError && occursin("99", err.msg) && occursin("domain", err.msg)
    err = try H[[10 => :q]] catch e e end
    @test err isa ArgumentError && occursin(":q", err.msg) && occursin("codomain", err.msg)
    @test_throws ArgumentError H[[10 => :a, 10 => :b, 20 => :a, 30 => :a]]

    # still validated against the kind of Hom, unless forced
    @test_throws InterfaceViolation H[[10 => :a]]
    @test_throws NotInCategory Mono(D, C)[[10 => :a, 20 => :b, 30 => :a]]
    @test H[[10 => :a], force=true] isa ObjectInCategory
end

@testset "FinSet of AbstractSet" begin
    S = FinSet[Set([:a, :b, :c])]
    @test cardinality(S) == 3
    els = collect(S)
    @test length(els) == 3
    @test [object(e)[1] for e in els] == [1, 2, 3]
    @test Set(object(e)[2] for e in els) == Set([:a, :b, :c])
    # indexing agrees with iteration
    @test all(S[i] == els[i] for i in 1:3)
    @test_throws BoundsError S[4]
    @test_throws BoundsError S[0]

    # element objects are validated
    @test (@ascat S)[object(els[2])] == els[2]
    @test_throws NotInCategory (@ascat S)[(9, :a)]
    @test_throws NotInCategory (@ascat S)[(1, :zzz)]

    # maps between sets, using plain values
    T = FinSet[Set([1, 2])]
    f = Iso(S, S)[[:a => :b, :b => :c, :c => :a]]
    @test object(f).dict[first(els)] isa ObjectInCategory
    g = Epi(S, T)[[:a => 1, :b => 2, :c => 1]]
    @test g isa ObjectInCategory
    @test_throws NotInCategory Mono(S, T)[[:a => 1, :b => 2, :c => 1]]
end

@testset "repeated values are ambiguous in pair maps" begin
    D, C = FinSet[[1, 1, 2]], FinSet[[:a, :b]]
    H = Hom(D, C)
    err = try H[[1 => :a, 2 => :b]] catch e e end
    @test err isa ArgumentError && occursin("more than once", err.msg)

    # unaffected when the repeated value is not used, or given as elements
    @test H[[2 => :b, D[1] => :a, D[2] => :a]] isa ObjectInCategory

    # plain values still work for ranges, whose elements are plain values
    R, C2 = FinSet[1:3], FinSet[[:a, :b]]
    @test Hom(R, C2)[[1 => :a, 2 => :b, 3 => :a]] isa ObjectInCategory
end

@testset "eltype and UnitRange sets" begin
    D = FinSet[[1, 2]]
    @test eltype(D) == Tuple{Int, Int}
    @test eltype(FinSet[Set([:a])]) == Tuple{Int, Symbol}
    @test eltype(FinSet[1:3]) == Int
    # collect still yields the element objects
    @test collect(D) == [D[1], D[2]]
    @test length(collect(FinSet[Set([:a, :b])])) == 2

    # the interface check requires a real eltype method
    struct NoEltype end
    err = try checkInterface(NoEltype(), FinSet) catch e e end
    @test err isa InterfaceViolation

    # range elements are plain values
    R = FinSet[1:3]
    @test (2 in (@ascat R))
    @test !(5 in (@ascat R))
    @test object((@ascat R)[2]) == 2
    err = try (@ascat R)[5] catch e e end
    @test err isa NotInCategory && occursin("5", sprint(showerror, err))
    @test object(R[3]) == 3
end

@testset "dict maps are checked like pair maps" begin
    D, C = FinSet[[10, 20]], FinSet[[:a, :b]]
    H = Hom(D, C)
    # plain values work in a dict, as in a vector of pairs
    f = H[Dict(10 => :a, 20 => :b)]
    @test f(D[1]) == C[1]
    @test f == H[Dict(D[1] => C[1], D[2] => C[2])]
    # and unknown elements are reported the same way
    err = try H[Dict(99 => :a, 20 => :b)] catch e e end
    @test err isa ArgumentError && occursin("99", err.msg)
    @test_throws ArgumentError H[Dict(10 => :nope, 20 => :b)]
    @test_throws InterfaceViolation H[Dict(10 => :a)]
end

@testset "function-built maps" begin
    D, C = FinSet[[1, 2, 3]], FinSet[[:a, :b, :c]]
    # the function takes and returns element objects
    f = Hom(D, C)[x -> C[object(x)[1]]]
    @test category(f) == Hom(D, C)
    @test all(f(D[i]) == C[i] for i in 1:3)
    @test Iso(D, C)[x -> C[object(x)[1]]] isa ObjectInCategory

    # ranges have plain values as elements
    R, T = FinSet[1:5], FinSet[6:10]
    g = Iso(R, T)[x -> T[object(x)]]
    @test all(g(R[i]) == T[i] for i in 1:5)

    # sets of any element type
    S = FinSet[Set([:p, :q])]
    @test Hom(S, D)[s -> D[object(s)[1]]] isa ObjectInCategory

    # plain values are not accepted
    err = try Hom(D, C)[x -> :a] catch e e end
    @test err isa ArgumentError && occursin("ObjectInCategory", err.msg)
    @test_throws ArgumentError Hom(R, T)[x -> object(x) + 5]

    # the result is checked: injectivity, and elements of the wrong set
    @test_throws NotInCategory Mono(D, C)[x -> C[1]]
    @test_throws InterfaceViolation Hom(D, C)[x -> D[1]]
    @test Hom(D, C)[x -> D[1], force=true] isa ObjectInCategory
end

@testset "== and hash for set maps" begin
    D, C = FinSet[[1, 2]], FinSet[[:a, :b]]
    H = Hom(D, C)
    f = H[[1 => :a, 2 => :b]]
    g = H[Dict(D[2] => C[2], D[1] => C[1])]
    @test f == g && hash(f) == hash(g)
    @test isequal(f, g)
    @test object(f) == object(g) && hash(object(f)) == hash(object(g))
    @test f != H[[1 => :b, 2 => :a]]
    # different kinds of Hom are different objects
    @test Iso(D, C)[[1 => :a, 2 => :b]] != f
    @test length(unique([f, g])) == 1
    @test Dict(f => 1)[g] == 1
end

@testset "compose, id, inv" begin
    A, B, C = FinSet[[1, 2, 3]], FinSet[[:a, :b, :c]], FinSet[["x", "y", "z"]]
    f = Iso(A, B)[[1 => :b, 2 => :c, 3 => :a]]
    g = Iso(B, C)[[:a => "x", :b => "y", :c => "z"]]

    gf = compose(g, f)              # apply f first
    @test gf == g ∘ f
    @test gf(A[1]) == C[2] && gf(A[2]) == C[3] && gf(A[3]) == C[1]
    @test category(gf) isa Iso
    @test category(gf) == Iso(A, C)

    # identities and inverses
    @test id(A) ∘ id(A) == id(A)
    @test category(id(A)) == Iso(A, A)
    @test gf ∘ id(A) == gf && id(C) ∘ gf == gf
    @test inv(f) ∘ f == id(A)
    @test f ∘ inv(f) == id(B)
    @test category(inv(f)) == Iso(B, A)
    @test inv(inv(f)) == f
    @test_throws MethodError inv(Hom(A, B)[[1 => :a, 2 => :a, 3 => :b]])

    # the kind of the composite is the most specific both guarantee
    S, T = FinSet[[1, 2]], FinSet[[:a, :b, :c]]
    m = Mono(S, T)[[1 => :a, 2 => :b]]          # S -> T injective
    e = Epi(T, S)[[:a => 1, :b => 2, :c => 1]]  # T -> S surjective
    @test category(m ∘ e) isa Hom               # T -> T, neither
    # the kind comes from the kinds composed, not from inspecting the values:
    # Epi ∘ Mono guarantees neither, though this composite is the identity
    @test category(e ∘ m) isa Hom
    @test category(compose(id(T), m)) isa Mono  # Iso ∘ Mono
    @test category(compose(e, id(T))) isa Epi   # Epi ∘ Iso
    @test object(e ∘ m) == object(id(S))
    @test e ∘ m != id(S)                        # same map, different kind

    # composability is checked
    @test_throws ArgumentError f ∘ g
    @test_throws ArgumentError compose(m, m)
end

@testset "value, index, findElement" begin
    D = FinSet[[10, 20, 10, 30]]
    for i in 1:4
        e = D[i]
        @test index(e) == i
        @test value(e) == object(e)[2]
    end
    @test value(D[1]) == 10 && value(D[3]) == 10   # same value, distinct elements
    @test findElement(D, 20) == D[2]
    @test_throws ArgumentError findElement(D, 10)  # ambiguous
    @test_throws ArgumentError findElement(D, 99)

    S = FinSet[Set([:a, :b])]
    e = S[1]
    @test D[index(D[2])] == D[2]
    @test value(e) in (:a, :b)
    @test findElement(S, value(e)) == e

    R = FinSet[6:10]
    e2 = R[3]
    @test value(e2) == 8 && index(e2) == 3
    @test R[index(e2)] == e2
    @test findElement(R, 8) == e2
    @test_throws ArgumentError findElement(R, 20)

    # used together: build a map without spelling out object(x)
    C = FinSet[[:x, :y, :z, :w]]
    f = Hom(D, C)[x -> C[index(x)]]
    @test f(D[2]) == C[2]
end
