# a shape which is not a `FreeCat`: two objects and one arrow between them
struct WalkingArrow <: Category end
JuliaTopology.nvertices(::WalkingArrow) = 2
JuliaTopology.generators(::WalkingArrow) = (1 => 2,)
JuliaTopology.checkInCategory(x, J::WalkingArrow) =
    x in (1, 2) || throw(NotInCategory(x, J, "not a vertex"))

@testset "Diagrams" begin
    J = parallelPairShape()
    qp = q ∘ p
    D = parallelPair(r, qp)       # two different morphisms X → Z

    @testset "diagrams" begin
        @test D(J[1]) === X && D(J[2]) === Z
        @test D(generator(J, 1)) === r
        @test D(id(J[1])) == id(X)
        @test D == parallelPair(r, qp)
        @test objects(D) == (X, Z) && arrows(D) == (r, qp)
        @test_throws NotInCategory diagram(J, C, (X, Z), (r,))
        @test_throws NotInCategory diagram(J, C, (X, Z, Y), (r, qp))
        @test_throws NotInCategory diagram(J, C, (X, FinCard[2]), (r, qp))
        @test_throws NotInCategory diagram(J, C, (Y, Z), (r, qp))
        @test objects(discrete(X, Y)) == (X, Y)
        @test_throws ArgumentError discrete()
        @test objects(cospan(q, r)) == (Y, X, Z)
        @test objects(span(p, r)) == (X, Y, Z)
    end

    K = FunctorCat(J, C)
    Δ = diagonal(J, C)

    @testset "functor category" begin
        @test_throws NotInCategory K[X]
        @test Δ(X) == Δ(X)
        @test object(Δ(X))(J[2]) === X
        @test category(Δ(p)) isa Hom

        # r and q ∘ p differ, so no transformation from D to Δ(Z) with the
        # identity at 2 is natural, but one from parallelPair(r, r) is
        D′ = parallelPair(r, r)
        η = Hom(K[D′], Δ(Z))[(r, id(Z))]
        @test components(η) == (r, id(Z))
        @test_throws NotInCategory Hom(K[D], Δ(Z))[(r, id(Z))]
        @test_throws NotInCategory Hom(K[D′], Δ(Z))[(r,)]
        @test_throws NotInCategory Hom(K[D′], Δ(Z))[(p, id(Z))]

        @test isIso(id(K[D])) && !isIso(η)
        @test category(compose(Δ(id(Z)), η)) isa Hom
        @test firstDifference(Δ(r), Δ(r)) === nothing
        @test firstDifference(Δ(r), Δ(qp)).path == (1,)
    end

    @testset "functor categories of any categories" begin
        # a functor out of a FreeCat is turned into a diagram to be checked
        L = FunctorCat(C, C)
        I = L[id(Cat[C])]
        @test_throws NotInCategory L[D]                       # not from C
        @test objects(diagram(id(Cat[C]))) == (X, Y, Z)
        @test arrows(diagram(id(Cat[C]))) == (p, q, r)
        @test components(id(I)) == (id(X), id(Y), id(Z))
        @test_throws NotInCategory Hom(I, I)[(id(X), id(Y))]
        @test_throws NotInCategory Hom(I, I)[(id(X), id(Y), id(Y))]

        # out of any other category, a functor which is not a diagram cannot
        # be checked, so natural transformations are trusted with `force`
        W = WalkingArrow()
        F = Hom(Cat[W], Cat[C])[Opaque(), force=true]
        M = FunctorCat(W, C)
        @test_throws InterfaceViolation diagram(F)
        @test_throws InterfaceViolation id(M[F])
        @test_throws NotInCategory Hom(M[F], M[F])[(id(X), id(Y))]
        η = Hom(M[F], M[F])[(id(X), id(Y)), force=true]
        @test components(η) == (id(X), id(Y))
        @test agrees(compose(η, η), η)
    end

    @testset "limits are only computed where defined" begin
        @test_throws InterfaceViolation limit(D)
        @test_throws InterfaceViolation colimit(D)
        @test_throws InterfaceViolation terminal(C)
    end

    @testset "shapes other than FreeCat" begin
        W = WalkingArrow()
        E = diagram(W, (X, Y), (p,))
        @test shape(E) == W && objects(E) == (X, Y) && arrows(E) == (p,) && E(W[2]) === Y
        @test_throws NotInCategory diagram(W, (X, Y), (q,))
        cone = Cone(E)[id(X), p]
        @test apex(cone) === X && leg(cone, 2) === p
        @test arrows(object(diagonal(W, C)(X))) == (id(X),)
        @test_throws InterfaceViolation diagram(FinCard, (X,))
    end
end
