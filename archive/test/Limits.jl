@testset "Limits and colimits" begin
    A, B, C = FinSet[1:3], FinSet[[:a, :b]], FinSet[1:2]
    a, b, c = ascat(A), ascat(B), ascat(C)
    f = Hom(A, C)[x -> c[mod1(object(x), 2)]]
    g = Hom(A, C)[x -> c[1]]
    h = Hom(B, C)[y -> c[1]]
    X = FinSet[[:x, :y]]
    x = ascat(X)

    @testset "cones" begin
        D = parallelPair(f, g)
        K = Cone(D)
        @test K isa Cone && K == Cone(D)
        cone = K[(X = Hom(X, A)[t -> a[1]], Y = Hom(X, C)[t -> c[1]])]
        @test apex(cone) === X && leg(cone, :X)(x[:x]) == a[1]
        @test_throws NotInCategory K[(X = Hom(X, A)[t -> a[2]], Y = Hom(X, C)[t -> c[1]])]
        @test_throws NotInCategory K[(X = Hom(X, C)[t -> c[1]], Y = Hom(X, C)[t -> c[1]])]
        @test_throws ArgumentError Cone(diagram(emptyShape(), FinSet))[NamedTuple()]
        @test Cone(diagram(emptyShape(), FinSet))[X, NamedTuple()] isa OIC

        # morphisms of cones
        other = K[(X = Hom(A, A)[t -> t == a[2] ? a[3] : t], Y = Hom(A, C)[t -> c[1]])]
        @test Hom(cone, other)[Hom(X, A)[t -> a[1]]] isa OIC
        @test_throws NotInCategory Hom(cone, other)[Hom(X, A)[t -> a[2]]]

        cocone = Cocone(D)[(X = Hom(A, X)[t -> x[:x]], Y = Hom(C, X)[t -> x[:x]])]
        @test apex(cocone) === X
        @test_throws NotInCategory Cocone(D)[(X = Hom(A, C)[t -> c[1]], Y = id(C))]
    end

    @testset "limits" begin
        P = product(A, B)
        @test cardinality(apex(P)) == 6
        @test Set(object(p) for p in apex(P)) ==
            Set((X1 = s, X2 = t) for s in A for t in B)
        @test object(product(; P = A, Q = B) |> apex |> first) |> keys == (:P, :Q)

        E = equalizer(f, g)
        @test Set(object(p).X for p in apex(E)) == Set(s for s in A if f(s) == g(s))

        PB = pullback(f, h)
        @test cardinality(apex(PB)) ==
            count(f(s) == h(t) for s in A for t in B)

        @test cardinality(terminal(FinSet)) == 1

        # each limit is a cone, and the universal arrow is a morphism of cones
        for (L, D) in ((P, discrete(A, B)), (E, parallelPair(f, g)), (PB, cospan(f, h)))
            @test Cone(D)[apex(L), legs(L)] isa OIC
        end
        cone = Cone(discrete(A, B))[
            (X1 = Hom(X, A)[t -> a[1]], X2 = Hom(X, B)[t -> t == x[:x] ? b[:a] : b[:b]])]
        u = canonicalHom(cone, P)
        @test Hom(cone, P)[apexMorphism(u)] isa OIC
        @test_throws NoCanonicalHomError canonicalHom(P, cone)

        # any cone which is a limit is accepted, however it was built
        odd = FinSet[[1, 3]]
        inclusion = Hom(odd, A)[t -> a[object(t)]]
        handmade = Cone(parallelPair(f, g))[(X = inclusion, Y = compose(f, inclusion))]
        @test Hom(E, handmade)[apexMorphism(canonicalHom(E, handmade))] isa OIC
        @test Hom(handmade, E)[apexMorphism(canonicalHom(handmade, E))] isa OIC

        # into the terminal set
        @test canonicalHom(A, terminal(FinSet)) isa OIC
        @test canonicalHom(A, FinSet[[:only]]) isa OIC    # any one-element set
        @test_throws NoCanonicalHomError canonicalHom(A, apex(P))
    end

    @testset "colimits" begin
        S = coproduct(A, B)
        @test cardinality(apex(S)) == 5
        @test Cocone(discrete(A, B))[apex(S), legs(S)] isa OIC

        Q = coequalizer(f, g)
        @test cardinality(apex(Q)) == 1
        @test length(unique(leg(Q, :Y)(y) for y in C)) == 1

        PO = pushout(Hom(C, A)[y -> a[object(y)]], Hom(C, B)[y -> b[:a]])
        @test cardinality(apex(PO)) == 3

        for (L, D) in ((S, discrete(A, B)), (Q, parallelPair(f, g)))
            @test Cocone(D)[apex(L), legs(L)] isa OIC
        end
        cocone = Cocone(parallelPair(f, g))[
            (X = Hom(A, X)[t -> x[:x]], Y = Hom(C, X)[t -> x[:x]])]
        v = canonicalHom(Q, cocone)
        @test Hom(Q, cocone)[apexMorphism(v)] isa OIC
        # a one-element cocone is also a colimit here, so this is unique
        @test canonicalHom(cocone, Q) isa OIC
        # but a point cannot be sent consistently into the disjoint union
        point = Cocone(discrete(A, B))[
            (X1 = Hom(A, X)[t -> x[:x]], X2 = Hom(B, X)[t -> x[:x]])]
        @test_throws NoCanonicalHomError canonicalHom(point, S)

        @test cardinality(initial(FinSet)) == 0
        @test canonicalHom(initial(FinSet), A) isa OIC
        @test canonicalHom(initial(FinSet), terminal(FinSet)) isa OIC
    end

    @testset "global elements" begin
        f = Hom(A, C)[t -> c[mod1(object(t), 2)]]
        p = globalElement(a[3])
        @test element(p) == a[3]
        @test domain(category(p)) == terminal(FinSet)
        @test firstDifference(f(p), globalElement(f(a[3]))) === nothing
        @test element(f(p)) == f(a[3])
        @test_throws ArgumentError element(f)
    end
end
