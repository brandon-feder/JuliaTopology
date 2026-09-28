@testset "FreeCat" begin
    @testset "construction" begin
        @test parallelPairShape().vertices == (:X, :Y)
        @test isempty(emptyShape().vertices)
        @test discreteShape(:A, :B).arrows == NamedTuple()
        @test parallelPairShape() == parallelPairShape()
        @test_throws ArgumentError FreeCat((:A,), (f = :A => :Z,))
        @test_throws ArgumentError FreeCat((:A, :f), (f = :A => :A,))
        @test_throws ArgumentError FreeCat((:A,), (f = :A,))
        @test_throws ArgumentError FreeCat((:A, :A), NamedTuple())
    end

    J = FreeCat((:A, :B, :C), (f = :A => :B, g = :B => :C))

    @testset "objects" begin
        @test J[:A] isa OIC
        @test_throws NotInCategory J[:Z]
        @test_throws NotInCategory J[1]
    end

    @testset "morphisms" begin
        f, g = generator(J, :f), generator(J, :g)
        @test_throws ArgumentError generator(J, :h)
        @test object(compose(g, f)).path == (:f, :g)
        @test category(compose(g, f)) isa Hom
        @test isIso(id(J[:A])) && !isIso(f)
        @test isMono(f) && isEpi(f)
        @test compose(f, id(J[:A])) == f
        @test_throws ArgumentError compose(f, g)
        @test Hom(J[:A], J[:C])[GenericMorphFreeCat((:f, :g))] isa OIC
        @test_throws NotInCategory Hom(J[:A], J[:C])[GenericMorphFreeCat((:g, :f))]
        @test_throws NotInCategory Hom(J[:A], J[:C])[GenericMorphFreeCat((:f,))]
        @test_throws NotInCategory Hom(J[:A], J[:C])[GenericMorphFreeCat((:h,))]
    end

    @testset "firstDifference in FinSet" begin
        A = FinSet[1:3]
        a = ascat(A)
        @test firstDifference(id(A), id(A)) === nothing
        d = firstDifference(Hom(A, A)[x -> a[1]], id(A))
        @test d.path == (a[2],) && d.left == a[1] && d.right == a[2]
    end
end
