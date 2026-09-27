@testset "MorphFinSet" begin
    A, B, C = FinSet[1:3], FinSet[[:a, :b, :c]], FinSet[1:6]
    a, b, c = @ascat(A), @ascat(B), @ascat(C)

    @testset "H[f::Function]" begin
        f = Hom(A, C)[x -> c[2 * object(x)]]
        @test [object(f(x)) for x in A] == [2, 4, 6]
        @test object(f) in Mono(A, C)
        @test_throws NotInCategory Hom(A, C)[x -> a[object(x)]]
        @test_throws NotInCategory Hom(A, C)[x -> object(x)]
        @test_throws NotInCategory Epi(A, C)[x -> c[object(x)]]
        @test Hom(A, C)[x -> object(x), force=true] isa OIC
    end

    @testset "id" begin
        @test all(id(A)(x) == x for x in A)
        @test category(id(A)) isa Iso
        @test id(A) == id(A)
    end

    @testset "compose" begin
        f = Iso(A, B)[[a[1] => b[:b], a[2] => b[:c], a[3] => b[:a]]]
        g = inv(f)
        @test all((g ∘ f)(x) == x for x in A)
        @test compose(g, f) isa OIC{<:Any, <:Iso}

        m = Mono(A, C)[x -> c[object(x)]]
        e = Epi(C, A)[x -> a[mod1(object(x), 3)]]
        h = Hom(A, A)[x -> a[1]]
        @test category(compose(m, g)) isa Mono     # Mono ∘ Iso
        @test category(compose(e, m)) isa Hom      # Epi ∘ Mono
        @test category(compose(f, e)) isa Epi      # Iso ∘ Epi
        @test category(compose(h, g)) isa Hom
        @test [object((e ∘ m)(x)) for x in A] == [1, 2, 3]

        @test_throws ArgumentError compose(f, f)
    end
end
