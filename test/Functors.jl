@testset "Functors" begin
    A = FinSet[1:3]
    a = @ascat(A)
    f = Hom(A, A)[x -> a[1]]

    @testset "Point" begin
        pt = Point[:pt]
        @test_throws NotInCategory Point[:x]
        @test_throws NotInCategory Point[1]
        @test category(id(pt)) isa Iso
        @test compose(id(pt), id(pt)) == id(pt)
    end

    @testset "FuncIdentity" begin
        I = id(Cat[FinSet])
        @test category(I) isa Iso
        @test I(A) === A
        @test I(f) === f
        @test_throws NotInCategory Hom(Cat[FinSet], Cat[FinCard])[FuncIdentity()]
    end

    @testset "FuncConstant" begin
        D = Hom(Cat[Point], Cat[FinSet])[FuncConstant(A)]
        @test D(Point[:pt]) === A
        @test D(id(Point[:pt])) == id(A)
        @test_throws NotInCategory Hom(Cat[Point], Cat[FinCard])[FuncConstant(A)]
    end

    @testset "morphism fallback" begin
        @test_throws InterfaceViolation canonicalHom(FinSet, FinCard)(f)
    end
end
