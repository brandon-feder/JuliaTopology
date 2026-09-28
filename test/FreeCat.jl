@testset "FreeCat" begin
    @testset "construction" begin
        @test vertices(parallelPairShape()) == 1:2
        @test generators(parallelPairShape()) == (1 => 2, 1 => 2)
        @test isempty(vertices(emptyShape()))
        @test isempty(generators(discreteShape(2)))
        @test parallelPairShape() == parallelPairShape()
        @test FreeCat(2, [1 => 2]) == FreeCat(2, (1 => 2,))
        @test_throws ArgumentError FreeCat(1, (1 => 3,))
        @test_throws ArgumentError FreeCat(1, (1,))
        @test_throws ArgumentError FreeCat(-1)
    end

    J = FreeCat(3, (1 => 2, 2 => 3))

    @testset "objects" begin
        @test J[1] isa OIC
        @test_throws NotInCategory J[4]
        @test_throws NotInCategory J[:A]
    end

    @testset "morphisms" begin
        f, g = generator(J, 1), generator(J, 2)
        @test_throws ArgumentError generator(J, 3)
        @test object(compose(g, f)).path == (1, 2)
        @test category(compose(g, f)) isa Hom
        @test isIso(id(J[1])) && !isIso(f)
        @test isMono(f) && isEpi(f)
        @test compose(f, id(J[1])) == f
        @test_throws ArgumentError compose(f, g)
        @test Hom(J[1], J[3])[GenericMorphFreeCat((1, 2))] isa OIC
        @test_throws NotInCategory Hom(J[1], J[3])[GenericMorphFreeCat((2, 1))]
        @test_throws NotInCategory Hom(J[1], J[3])[GenericMorphFreeCat((1,))]
        @test_throws NotInCategory Hom(J[1], J[3])[GenericMorphFreeCat((3,))]
    end

    @testset "firstDifference of paths" begin
        @test firstDifference(q ∘ p, q ∘ p) === nothing
        d = firstDifference(r, q ∘ p)
        @test d.path == () && d.left === r && agrees(d.right, q ∘ p) === true
        @test agrees(q ∘ p, compose(q, p)) && !agrees(r, q ∘ p)
    end
end
