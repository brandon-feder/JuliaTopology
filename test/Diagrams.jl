# a shape which is not a `FreeCat`: two objects and one arrow between them
struct WalkingArrow <: Category end
JuliaTopology.vertices(::WalkingArrow) = (:A, :B)
JuliaTopology.generators(::WalkingArrow) = (f = :A => :B,)
JuliaTopology.checkInCategory(x, J::WalkingArrow) =
    x in (:A, :B) || throw(NotInCategory(x, J, "not a vertex"))

@testset "Diagrams" begin
    A, B = FinSet[1:3], FinSet[1:2]
    a, b = ascat(A), ascat(B)
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
        @test category(id(DK)) isa Hom

        η = Hom(DK, Δ(B))[(X = Hom(A, B)[x -> b[1]], Y = Hom(B, B)[y -> b[1]])]
        @test η isa OIC
        @test_throws NotInCategory Hom(DK, Δ(B))[(X = f, Y = id(B))]
        @test_throws NotInCategory Hom(DK, Δ(B))[(X = f,)]
        @test_throws NotInCategory Hom(DK, Δ(B))[(X = id(A), Y = id(B))]
        c = Hom(A, A)[x -> a[1]]
        @test category(compose(Δ(id(B)), η)) isa Hom
        @test firstDifference(Δ(id(A)), Δ(id(A))) === nothing
        @test firstDifference(Δ(c), Δ(id(A))).path == (:X, a[2])
    end

    @testset "shapes other than FreeCat" begin
        W = WalkingArrow()
        X, Y = FinSet[1:3], FinSet[[:a, :b]]
        y = ascat(Y)
        h = Hom(X, Y)[t -> y[:a]]
        D = diagram(W; A = X, B = Y, f = h)
        @test shape(D) == W && D(:A) === X && D(:f) === h && D(W[:B]) === Y
        @test_throws NotInCategory diagram(W; A = X, B = Y, f = id(X))

        # a limit of an arrow is its domain, and a colimit its codomain
        @test cardinality(apex(limit(D))) == cardinality(X)
        @test cardinality(apex(colimit(D))) == cardinality(Y)
        L, cone = limit(D), Cone(D)[(A = id(X), B = h)]
        @test Hom(cone, L)[apexMorphism(canonicalHom(cone, L))] isa OIC

        K = FunctorCat(W, FinSet)
        Δ = diagonal(W, FinSet)
        @test object(Δ(X))(:f) == id(X)
        @test_throws NotInCategory Hom(K[D], Δ(Y))[(A = h, B = Hom(Y, Y)[t -> y[:b]])]

        # a category which does not list its objects is not a shape
        @test_throws InterfaceViolation diagram(FinCard; A = X)
    end
end
