struct ToyGrpLiA <: Category end
struct ToyMonoidLiA <: Category end
struct ToyFunctorLiA end

struct ToyGrpLiB <: Category end

struct ToyGrpLiC <: Category end
struct ToyMonoidLiC <: Category end
struct ToySemigroupLiC <: Category end
struct ToyFunctorLiC1 end
struct ToyFunctorLiC2 end

struct ToyCatLiD <: Category end
struct ToyCatLiE <: Category end

struct ToyCatLiF <: Category end
struct ToyCatLiG <: Category end
struct ToyFunctorLiF1 end
struct ToyFunctorLiF2 end
struct ToyCatLiH <: Category end

struct ToyGrpLiI <: Category end
struct ToyMonoidLiI <: Category end
struct ToySemigroupLiI <: Category end
struct ToyFunctorLiI1 end
struct ToyFunctorLiI2 end
inCategory(object, category::ToyGrpLiI) = true
inCategory(object, category::ToyMonoidLiI) = true
inCategory(object, category::ToySemigroupLiI) = true
(f::ToyFunctorLiI1)(oic::ObjectInCategory) = object(oic) + 1
(f::ToyFunctorLiI2)(oic::ObjectInCategory) = object(oic) * 10

struct ToyGrpLiJ <: Category end
struct ToyMonoidLiJ <: Category end
struct ToyFunctorLiJ end
inCategory(object, category::ToyGrpLiJ) = true

struct ToyGrpLiK <: Category end
struct ToyCatLiK <: Category end
struct ToyFunctorLiK end
inCategory(object, category::ToyGrpLiK) = true

struct ToyGrpLiL <: Category end
struct ToyMonoidLiL <: Category end
struct ToyFunctorLiL end
inCategory(object, category::ToyGrpLiL) = true

# a lift `functor : sub -> sup`, as an object in the Hom category
liftMorphism(sub, sup, functor) = ObjectInCategory(functor, Hom(Cat[sub], Cat[sup]))

@testset "Lifts" begin
    @testset "push! registers a real, inspectable morphism" begin
        m = liftMorphism(ToyGrpLiA(), ToyMonoidLiA(), ToyFunctorLiA())
        @test push!(Lifts, m) == Lifts

        @test object(m) == ToyFunctorLiA()
        @test m.category isa Hom
        @test object(m.category.domain) == ToyGrpLiA()
        @test object(m.category.codomain) == ToyMonoidLiA()
        @test m.category.domain.category == Cat
        @test m.category.codomain.category == Cat
        @test m in Lifts.liftRegistry
    end

    @testset "push! rejects anything that isn't a morphism between objects of Cat" begin
        n = length(Lifts.liftRegistry)

        # an object in Cat, not a morphism
        notAHom = Cat[ToyGrpLiA()]
        @test_throws MethodError push!(Lifts, notAHom)

        # a morphism, but not between objects of Cat
        wrongCategory = ObjectInCategory(ToyFunctorLiA(), Hom(
            ObjectInCategory(1, ToyGrpLiI()),
            ObjectInCategory(2, ToyGrpLiI()),
        ))
        @test_throws MethodError push!(Lifts, wrongCategory)

        @test length(Lifts.liftRegistry) == n
    end

    @testset "canLift: reflexivity" begin
        @test canLift(ToyGrpLiB(), ToyGrpLiB())
    end

    @testset "canLift: direct and transitive (2-hop) reachability" begin
        push!(Lifts, liftMorphism(ToyGrpLiC(), ToyMonoidLiC(), ToyFunctorLiC1()))
        push!(Lifts, liftMorphism(ToyMonoidLiC(), ToySemigroupLiC(), ToyFunctorLiC2()))

        @test canLift(ToyGrpLiC(), ToyMonoidLiC())
        @test canLift(ToyGrpLiC(), ToySemigroupLiC())
        @test !canLift(ToySemigroupLiC(), ToyGrpLiC())
    end

    @testset "canLift: unrelated categories are not subcategories" begin
        @test !canLift(ToyCatLiD(), ToyCatLiE())
    end

    @testset "canLift: a cycle in the declared graph does not hang" begin
        push!(Lifts, liftMorphism(ToyCatLiF(), ToyCatLiG(), ToyFunctorLiF1()))
        push!(Lifts, liftMorphism(ToyCatLiG(), ToyCatLiF(), ToyFunctorLiF2()))

        @test canLift(ToyCatLiF(), ToyCatLiG())
        @test !canLift(ToyCatLiF(), ToyCatLiH())
    end

    @testset "lift composes the functors along a 2-hop path" begin
        push!(Lifts, liftMorphism(ToyGrpLiI(), ToyMonoidLiI(), ToyFunctorLiI1()))
        push!(Lifts, liftMorphism(ToyMonoidLiI(), ToySemigroupLiI(), ToyFunctorLiI2()))

        oic = ObjectInCategory(5, ToyGrpLiI())
        result = lift(oic, ToySemigroupLiI())

        @test result.category == ToySemigroupLiI()
        @test object(result) == (5 + 1) * 10

        # C[oic] is sugar for lift(oic, C)
        @test ToySemigroupLiI()[oic] == result
        @test object(ToySemigroupLiI()[oic]) == (5 + 1) * 10
        @test ToyGrpLiI()[oic] == oic
    end

    @testset "functors have no default: a non-callable functor throws" begin
        push!(Lifts, liftMorphism(ToyGrpLiJ(), ToyMonoidLiJ(), ToyFunctorLiJ()))

        oic = ObjectInCategory(7, ToyGrpLiJ())
        @test_throws MethodError lift(oic, ToyMonoidLiJ())
    end

    @testset "lift throws a descriptive error when unreachable" begin
        oic = ObjectInCategory(1, ToyGrpLiK())
        @test_throws ErrorException lift(oic, ToyCatLiK())
    end

    @testset "distinguished: an unregistered functor doesn't make lifting succeed" begin
        # Hand-built, real Hom-category morphism-object -- but never passed
        # through push!.
        _unused = liftMorphism(ToyGrpLiL(), ToyMonoidLiL(), ToyFunctorLiL())

        @test !canLift(ToyGrpLiL(), ToyMonoidLiL())
        oic = ObjectInCategory(1, ToyGrpLiL())
        @test_throws ErrorException lift(oic, ToyMonoidLiL())
    end
end
