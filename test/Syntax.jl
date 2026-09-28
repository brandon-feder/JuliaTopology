@testset "Syntax" begin
    A, B, C = FinSet[1:3], FinSet[[:a, :b]], FinSet[1:6]
    a, b, c = ascat(A), ascat(B), ascat(C)

    @testset "ascat" begin
        @test ascat(A) == OICAsCat(A) && oic(ascat(A)) === A
        @test object(ascat(A)[2]) == 2
    end

    @testset "values=true" begin
        f = Hom(A, C)[x -> 2x, values=true]
        @test [object(f(x)) for x in A] == [2, 4, 6]
        @test_throws NotInCategory Hom(A, C)[x -> 7x, values=true]
        g = Hom(A, B)[[1 => :a, 2 => :b, 3 => :a], values=true]
        @test g(a[2]) == b[:b]
        @test_throws NotInCategory Hom(A, B)[[1 => :z], values=true]
        @test_throws ArgumentError Hom(A, B)[[1 => :a, 2], values=true]
    end

    @testset "∘ and agrees" begin
        f = Hom(A, A)[x -> a[1]]
        @test agrees(f ∘ id(A), f) && !agrees(f, id(A))
        J = FreeCat((:X, :Y, :Z), (p = :X => :Y, q = :Y => :Z))
        @test object(generator(J, :q) ∘ generator(J, :p)).path == (:p, :q)
    end

    @testset "Hom between categories" begin
        @test Hom(FinSet, FinCard) == Hom(Cat[FinSet], Cat[FinCard])
        @test Hom(FinSet, FinSet)[FuncIdentity()] == id(Cat[FinSet])
    end

    @testset "diagrams" begin
        f = Hom(A, B)[x -> b[:a]]
        D = diagram(parallelPairShape(); X = A, Y = B, f = f, g = f)
        @test D == diagram(parallelPairShape(), FinSet; X = A, Y = B, f = f, g = f)
        @test D(:X) === A && D(:f) === f
        @test_throws ArgumentError D(:z)
        @test_throws ArgumentError diagram(emptyShape())
        @test shape(D) == parallelPairShape()
        @test diagram(Cone(D)) == D && diagram(Cocone(D)) == D
    end

    @testset "data in brackets" begin
        J = FreeCat((:X, :Y, :Z), (p = :X => :Y, q = :Y => :Z))
        @test Hom(J[:X], J[:Z])[(:p, :q)] == Hom(J[:X], J[:Z])[GenericMorphFreeCat((:p, :q))]
        @test Hom(J[:X], J[:X])[()] == id(J[:X])

        D = diagram(parallelPairShape(); X = A, Y = A, f = id(A), g = id(A))
        K = FunctorCat(parallelPairShape(), FinSet)
        @test Hom(K[D], K[D])[(X = id(A), Y = id(A))] == id(K[D])

        I = id(Cat[FinSet])
        h = Hom(A, B)[x -> b[:a]]
        o = (I ↓ I)[(A, B, h)]
        @test o == (I ↓ I)[GenericComma(A, B, h)]
        @test Hom(o, o)[(id(A), id(B))] == id(o)
    end

    @testset "componentwise isomorphisms" begin
        σ = Hom(A, A)[x -> mod1(x + 1, 3), values=true]
        D = diagram(parallelPairShape(); X = A, Y = A, f = id(A), g = id(A))
        K = FunctorCat(parallelPairShape(), FinSet)
        η = Hom(K[D], K[D])[(X = σ, Y = σ)]
        @test isIso(η) && isMono(η) && isEpi(η)
        @test agrees(compose(inv(η), η), id(K[D]))
        k = Hom(A, A)[x -> a[1]]
        @test_throws ArgumentError inv(Hom(K[D], K[D])[(X = k, Y = k)])

        S = Slice(A)
        f, g = S[id(A)], S[σ]
        m = Hom(f, g)[inv(σ)]
        @test isIso(m) && agrees(apexMorphism(inv(m)), σ)
        @test inv(id(Point[:pt])) == id(Point[:pt])
    end

    @testset "× and ⊔" begin
        @test cardinality(A × B) == 6
        @test cardinality(A ⊔ B) == 5
    end
end
