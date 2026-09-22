struct ToyCatHomA <: Category end
struct ToyObjHomA end
struct ToyObjHomB end
inCategory(object, category::ToyCatHomA) = true

struct ToyCatHomG <: Category end
struct ToyCatHomH <: Category end
struct ToyObjHomC end
struct ToyObjHomD end
inCategory(object, category::ToyCatHomG) = true
inCategory(object, category::ToyCatHomH) = true

struct ToyCatHomD <: Category end
struct ToyObjHomE end
struct ToyObjHomF end
inCategory(object, category::ToyCatHomD) = true

@testset "Hom" begin
    @testset "Hom(domain, codomain) builds a Hom with the right fields" begin
        domainOic = ObjectInCategory(ToyObjHomA(), ToyCatHomA())
        codomainOic = ObjectInCategory(ToyObjHomB(), ToyCatHomA())
        hc = Hom(domainOic, codomainOic)
        @test hc isa Hom
        @test hc.domain == domainOic
        @test hc.codomain == codomainOic
    end

    @testset "Hom requires domain and codomain to share the same category" begin
        domainOic = ObjectInCategory(ToyObjHomC(), ToyCatHomG())
        codomainOic = ObjectInCategory(ToyObjHomD(), ToyCatHomH())
        # The shared `CatT` type parameter between domain/codomain now makes this a
        # dispatch-time MethodError rather than a runtime AssertionError.
        @test_throws MethodError Hom(domainOic, codomainOic)
    end

    @testset "wrapping an arbitrary object in a Hom category" begin
        domainOic = ObjectInCategory(ToyObjHomE(), ToyCatHomD())
        codomainOic = ObjectInCategory(ToyObjHomF(), ToyCatHomD())
        hc = Hom(domainOic, codomainOic)
        @test ObjectInCategory(identity, hc) isa ObjectInCategory
        @test ObjectInCategory(42, hc) isa ObjectInCategory
    end
end
