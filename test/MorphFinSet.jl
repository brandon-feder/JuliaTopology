@testset "MorphFinSet" begin
    A, B, C = FinSet[1:3], FinSet[[:a, :b, :c]], FinSet[1:6]
    a, b, c = ascat(A), ascat(B), ascat(C)

    @testset "H[f::Function]" begin
        f = Hom(A, C)[x -> c[2 * object(x)]]
        @test [object(f(x)) for x in A] == [2, 4, 6]
        @test_throws NotInCategory Hom(A, C)[x -> a[object(x)]]
        @test_throws NotInCategory Hom(A, C)[x -> object(x)]
        @test Hom(A, C)[x -> object(x), force=true] isa OIC
    end

    @testset "isMono, isEpi, isIso" begin
        f = Hom(A, C)[x -> c[2 * object(x)]]
        @test isMono(f) && !isEpi(f) && !isIso(f)
        e = Hom(C, A)[x -> a[mod1(object(x), 3)]]
        @test !isMono(e) && isEpi(e)
        @test isIso(id(A))
    end

    @testset "id" begin
        @test all(id(A)(x) == x for x in A)
        @test id(A) == id(A)
    end

    @testset "compose and inv" begin
        f = Hom(A, B)[[a[1] => b[:b], a[2] => b[:c], a[3] => b[:a]]]
        g = inv(f)
        @test all((g ∘ f)(x) == x for x in A)
        @test all(compose(f, g)(y) == y for y in B)
        @test isIso(g ∘ f)
        @test inv(f; force=true)(b[:b]) == a[1]

        e = Hom(C, A)[x -> a[mod1(object(x), 3)]]
        m = Hom(A, C)[x -> c[object(x)]]
        @test [object((e ∘ m)(x)) for x in A] == [1, 2, 3]
        @test_throws ArgumentError inv(m)          # not a bijection
        @test_throws ArgumentError compose(f, f)   # endpoints do not match
    end
end
