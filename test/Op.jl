@testset "Op" begin
    A, B = FinSet[1:3], FinSet[[:a, :b]]
    a, b = ascat(A), ascat(B)
    f = Hom(A, B)[x -> isodd(x) ? :a : :b, values=true]
    s = Hom(A, A)[x -> mod1(x + 1, 3), values=true]

    @testset "objects and morphisms" begin
        @test op(FinSet) == Op(FinSet) && op(op(FinSet)) == FinSet
        @test category(op(A)) == Op(FinSet) && op(op(A)) === A
        @test domain(category(op(f))) == op(B) && codomain(category(op(f))) == op(A)
        @test op(op(f)) === f
        @test_throws NotInCategory Hom(op(A), op(B))[GenericMorphOp(f)]  # wrong way round
    end

    @testset "structure by duality" begin
        g = Hom(B, A)[y -> y == :a ? 1 : 2, values=true]
        @test agrees(op(f) ∘ op(g), op(g ∘ f))
        @test agrees(id(op(A)), op(id(A)))
        @test isMono(op(f)) == isEpi(f) && isEpi(op(f)) == isMono(f)
        @test isIso(op(s)) && agrees(inv(op(s)), op(inv(s)))
        @test firstDifference(op(s), op(id(A))) !== nothing
    end

    @testset "terminal and initial" begin
        @test cardinality(op(terminal(Op(FinSet)))) == 0     # the empty set
        @test cardinality(op(initial(Op(FinSet)))) == 1      # the one-point set
        @test canonicalHom(op(A), terminal(Op(FinSet))) isa OIC
        @test_throws NoCanonicalHomError canonicalHom(op(A), op(B))
    end

    @testset "shapes and diagrams" begin
        J = cospanShape()
        @test vertices(op(J)) == vertices(J)
        @test generators(op(J)) == (f = :C => :A, g = :C => :B)
        h = Hom(B, B)[y -> y, values=true]
        D = cospan(f, h)
        @test op(op(D)) == D
        @test op(D)(:f) == op(f)
    end

    @testset "cocones are opposite cones" begin
        D = parallelPair(f, Hom(A, B)[x -> :a, values=true])
        @test Cocone(D) == Op(Cone(op(D))) && Cocone(D) isa Cocone
        @test diagram(Cocone(D)) == D
        Q = colimit(D)
        # each computation builds a new colimit, so compare what they hold
        @test cardinality(apex(initial(Cocone(D)))) == cardinality(apex(Q))
        @test cardinality(op(apex(limit(op(D))))) == cardinality(apex(Q))
        X = FinSet[[:x]]
        c = Cocone(D)[(X = Hom(A, X)[t -> :x, values=true], Y = Hom(B, X)[t -> :x, values=true])]
        u = canonicalHom(Q, c)
        @test Hom(Q, c)[apexMorphism(u)] isa OIC
    end
end
