# a functor defining how it maps objects, but nothing else
struct ObjectsOnly end
JuliaTopology.checkInCategory(::ObjectsOnly, ::Hom{FreeCat, FreeCat, CatCat}) = true
(::OIC{ObjectsOnly, <:Hom{FreeCat, FreeCat, CatCat}})(A::OIC{Int, FreeCat}) = A

# a morphism of FinCard defining nothing
struct Opaque end
JuliaTopology.checkInCategory(::Opaque, ::Hom{Int, Int, CatFinCard}) = true

@testset "Functors" begin
    @testset "Point" begin
        pt = Point[1]
        @test_throws NotInCategory Point[2]
        @test_throws NotInCategory Point[:pt]
        @test isIso(id(pt))
        @test compose(id(pt), id(pt)) == id(pt)
    end

    @testset "FuncIdentity" begin
        I = id(Cat[C])
        @test category(I) isa Hom
        @test I(X) === X
        @test I(p) === p
        @test_throws NotInCategory Hom(Cat[C], Cat[FinCard])[FuncIdentity()]
    end

    @testset "constant" begin
        D = constant(X)
        @test D(Point[1]) === X
        @test D(id(Point[1])) == id(X)
        @test D == constant(X)
    end

    @testset "fallbacks for undefined operations" begin
        F = Hom(Cat[C], Cat[C])[ObjectsOnly()]
        @test_throws InterfaceViolation F(p)                 # no action on morphisms
        o = Hom(FinCard[1], FinCard[1])[Opaque()]
        @test_throws InterfaceViolation compose(o, o)
        @test_throws InterfaceViolation firstDifference(F, F)
        @test_throws InterfaceViolation isEpi(F)
        @test_throws InterfaceViolation isMono(F)
        @test_throws InterfaceViolation isIso(F)
        @test_throws InterfaceViolation inv(F)
        @test_throws InterfaceViolation id(FinCard[3])
    end

    @testset "composition in Cat" begin
        F = Hom(Cat[C], Cat[C])[ObjectsOnly()]
        G = F ∘ F
        @test object(G) isa FuncCompose && G(X) === X
        @test id(Cat[C]) ∘ F === F && F ∘ id(Cat[C]) === F
        @test_throws ArgumentError F ∘ id(Cat[FinCard])

        # a diagram followed by a functor is a diagram
        D = constant(X)
        @test (id(Cat[C]) ∘ D) === D
        @test constant(X) ∘ toPoint(parallelPairShape()) ==
            object(diagonal(parallelPairShape(), C)(X))
    end
end
