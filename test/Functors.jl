# a functor defining how it maps objects, but nothing else
struct ObjectsOnly end
JuliaTopology.checkInCategory(::ObjectsOnly, ::Hom{CatFinSet, CatFinSet, CatCat}) = true
(::OIC{ObjectsOnly, <:Hom{CatFinSet, CatFinSet, CatCat}})(X::OIC{<:Any, CatFinSet}) = X

# a morphism of FinCard defining nothing
struct Opaque end
JuliaTopology.checkInCategory(::Opaque, ::Hom{Int, Int, CatFinCard}) = true

@testset "Functors" begin
    A = FinSet[1:3]
    a = ascat(A)
    f = Hom(A, A)[x -> a[1]]

    @testset "Point" begin
        pt = Point[:pt]
        @test_throws NotInCategory Point[:x]
        @test_throws NotInCategory Point[1]
        @test isIso(id(pt))
        @test compose(id(pt), id(pt)) == id(pt)
    end

    @testset "FuncIdentity" begin
        I = id(Cat[FinSet])
        @test category(I) isa Hom
        @test I(A) === A
        @test I(f) === f
        @test_throws NotInCategory Hom(Cat[FinSet], Cat[FinCard])[FuncIdentity()]
    end

    @testset "constant" begin
        D = constant(A)
        @test D(Point[:pt]) === A
        @test D(id(Point[:pt])) == id(A)
        @test D == constant(A)
    end

    @testset "morphism fallback" begin
        @test_throws InterfaceViolation Hom(Cat[FinSet], Cat[FinSet])[ObjectsOnly()](f)
    end

    @testset "fallbacks for undefined operations" begin
        F = Hom(Cat[FinSet], Cat[FinSet])[ObjectsOnly()]   # Cat defines none of these
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
        F = Hom(Cat[FinSet], Cat[FinSet])[ObjectsOnly()]
        G = F ∘ F
        @test object(G) isa FuncCompose && G(A) === A
        @test id(Cat[FinSet]) ∘ F === F && F ∘ id(Cat[FinSet]) === F
        @test_throws ArgumentError F ∘ id(Cat[FinCard])

        # a diagram followed by a functor is a diagram
        D = constant(A)
        @test (id(Cat[FinSet]) ∘ D) === D
        @test constant(A) ∘ toPoint(parallelPairShape()) ==
            object(diagonal(parallelPairShape(), FinSet)(A))
    end
end

