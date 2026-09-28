@testset "Syntax" begin
    qp = q ∘ p

    @testset "ascat" begin
        @test ascat(X) == OICAsCat(X) && oic(ascat(X)) === X
    end

    @testset "∘ and agrees" begin
        @test agrees(q ∘ p, compose(q, p)) && !agrees(r, q ∘ p)
        @test agrees(p ∘ id(X), p)
    end

    @testset "Hom between categories" begin
        @test Hom(C, FinCard) == Hom(Cat[C], Cat[FinCard])
        @test Hom(C, C)[FuncIdentity()] == id(Cat[C])
    end

    @testset "diagrams" begin
        D = diagram(parallelPairShape(), (X, Z), (r, qp))
        @test D == diagram(parallelPairShape(), C, (X, Z), (r, qp))
        @test D == parallelPair(r, qp)
        @test_throws ArgumentError diagram(emptyShape(), ())
        @test shape(D) == parallelPairShape()
        @test diagram(Cone(D)) == D && diagram(Cocone(D)) == D
    end

    @testset "data in brackets" begin
        @test Hom(X, Z)[(1, 2)] == Hom(X, Z)[GenericMorphFreeCat((1, 2))]
        @test Hom(X, X)[()] == id(X)

        D = parallelPair(id(X), id(X))
        K = FunctorCat(parallelPairShape(), C)
        @test agrees(Hom(K[D], K[D])[(id(X), id(X))], id(K[D]))

        I = id(Cat[C])
        o = (I ↓ I)[(X, Y, p)]
        @test o == (I ↓ I)[GenericComma(X, Y, p)]
        @test Hom(o, o)[(id(X), id(Y))] == id(o)
    end

    @testset "componentwise isomorphisms" begin
        D = parallelPair(qp, qp)
        K = FunctorCat(parallelPairShape(), C)
        @test isIso(id(K[D])) && agrees(inv(id(K[D])), id(K[D]))
        η = Hom(K[D], K[parallelPair(qp, qp)])[(id(X), id(Z))]
        @test isIso(η)
        Δ = diagonal(parallelPairShape(), C)
        @test_throws ArgumentError inv(Hom(K[parallelPair(r, r)], Δ(Z))[(r, id(Z))])
        @test inv(id(Point[1])) == id(Point[1])
    end
end
