@testset "Diagrams" begin
    A, B = FinSet[1:3], FinSet[1:2]
    a, b = @ascat(A), @ascat(B)
    f = Hom(A, B)[x -> b[mod1(object(x), 2)]]
    g = Hom(A, B)[x -> b[1]]
    J = parallelPairShape()
    D = parallelPair(f, g)

    @testset "diagrams" begin
        @test D(J[:X]) === A && D(J[:Y]) === B
        @test D(generator(J, :f)) === f
        @test D(id(J[:X])) == id(A)
        @test D == parallelPair(f, g)
        @test_throws NotInCategory diagram(J, FinSet; X=A, Y=B, f=f)
        @test_throws ArgumentError diagram(J, FinSet; X=A, Y=B, f=f, g=g, h=f)
        @test_throws NotInCategory diagram(J, FinSet; X=A, Y=FinCard[2], f=f, g=g)
        @test_throws NotInCategory diagram(J, FinSet; X=B, Y=B, f=f, g=g)
        @test object(discrete(A, B)).objects == (X1 = A, X2 = B)
        @test object(discrete(; P=A, Q=B)).objects == (P = A, Q = B)
        @test_throws ArgumentError discrete(A; P=B)
        @test object(cospan(f, id(B))).objects == (A = A, B = B, C = B)
        @test object(span(f, g)).objects == (C = A, A = B, B = B)
    end

    K = FunctorCat(J, FinSet)
    DK = K[D]
    Δ = diagonal(J, FinSet)

    @testset "functor category" begin
        @test_throws NotInCategory K[A]
        @test Δ(A) == Δ(A)
        @test object(Δ(A))(J[:Y]) === A
        @test category(Δ(f)) isa Hom
        @test category(id(DK)) isa Iso

        η = Hom(DK, Δ(B))[MorphNat((X = Hom(A, B)[x -> b[1]], Y = Hom(B, B)[y -> b[1]]))]
        @test η isa OIC
        @test_throws NotInCategory Hom(DK, Δ(B))[MorphNat((X = f, Y = id(B)))]
        @test_throws NotInCategory Hom(DK, Δ(B))[MorphNat((X = f,))]
        @test_throws NotInCategory Hom(DK, Δ(B))[MorphNat((X = id(A), Y = id(B)))]
        c = Hom(A, A)[x -> a[1]]
        @test_throws NotInCategory Iso(Δ(A), Δ(A))[MorphNat((X = c, Y = c))]
        @test category(compose(Δ(id(B)), η)) isa Hom
        @test firstDifference(Δ(id(A)), Δ(id(A))) === nothing
        @test firstDifference(Δ(c), Δ(id(A))).at == (:X, a[2])
    end
end
