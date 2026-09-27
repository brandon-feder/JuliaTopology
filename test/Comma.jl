@testset "Comma" begin
    A, B, B2 = FinSet[1:3], FinSet[1:2], FinSet[1:4]
    a, b, b2 = @ascat(A), @ascat(B), @ascat(B2)
    I = id(Cat[FinSet])
    h = Hom(A, B)[x -> b[mod1(object(x), 2)]]
    incl = Mono(B, B2)[y -> b2[object(y)]]
    shift = Hom(B, B2)[y -> b2[object(y) + 1]]

    @testset "construction" begin
        @test Comma(I, I) isa Category
        @test I ↓ I == Comma(I, I)
        @test_throws ArgumentError Comma(I, A)
        @test_throws ArgumentError Comma(I, id(Cat[FinCard]))
    end

    K = I ↓ I   # the arrow category of FinSet
    o1 = K[ObjComma(A, B, h)]
    o2 = K[ObjComma(A, B2, compose(incl, h))]

    @testset "objects" begin
        @test source(o1) === A && target(o1) === B && arrow(o1) === h
        @test_throws NotInCategory K[ObjComma(FinCard[3], B, h)]
        @test_throws NotInCategory K[ObjComma(B, B, h)]     # wrong domain
        @test_throws NotInCategory K[ObjComma(A, B2, h)]    # wrong codomain
        @test_throws NotInCategory K[ObjComma(A, B, A)]     # not a morphism
    end

    @testset "morphisms" begin
        m = Hom(o1, o2)[MorphComma(id(A), incl)]
        @test m isa OIC
        @test_throws NotInCategory Hom(o1, o2)[MorphComma(id(A), shift)]
        @test_throws NotInCategory Hom(o1, o2)[MorphComma(id(B), incl)]
        @test_throws NotInCategory Epi(o1, o2)[MorphComma(id(A), incl)]
        @test_throws NotInCategory Iso(o1, o1)[MorphComma(id(A), Hom(B, B)[y -> y])]
        @test category(id(o1)) isa Iso
        @test category(compose(m, id(o1))) isa Hom
        @test category(compose(id(o1), id(o1))) isa Iso
        @test_throws ArgumentError compose(id(o1), m)
    end

    @testset "slice-like comma" begin
        Δ = Hom(Cat[Point], Cat[FinSet])[FuncConstant(B)]
        S = I ↓ Δ
        s1 = S[ObjComma(A, Point[:pt], h)]
        s2 = S[ObjComma(B, Point[:pt], id(B))]
        @test Hom(s1, s2)[MorphComma(h, id(Point[:pt]))] isa OIC
        @test_throws NotInCategory Hom(s1, s2)[
            MorphComma(Hom(A, B)[x -> b[1]], id(Point[:pt]))]
    end

    @testset "over a category other than FinSet" begin
        KC = Comma(id(Cat[Cat]), id(Cat[Cat]))
        oc = KC[ObjComma(Cat[FinSet], Cat[FinCard], canonicalHom(FinSet, FinCard))]
        m = MorphComma(id(Cat[FinSet]), id(Cat[FinCard]))
        @test_throws NotInCategory Hom(oc, oc)[m]
        @test Hom(oc, oc)[m, force=true] isa OIC
    end
end

@testset "Slice and Coslice" begin
    X, A, B = FinSet[1:2], FinSet[1:3], FinSet[1:4]
    x, a, b = @ascat(X), @ascat(A), @ascat(B)
    h = Mono(A, B)[t -> b[object(t)]]

    @testset "Slice" begin
        S = Slice(X)
        @test S == Slice(X)
        @test S isa Slice
        f = S[Hom(A, X)[t -> x[mod1(object(t), 2)]]]
        g = S[Hom(B, X)[t -> x[mod1(object(t), 2)]]]
        @test source(f) === A
        @test Hom(f, g)[h] isa OIC
        @test_throws NotInCategory Hom(f, g)[Hom(A, B)[t -> b[object(t) + 1]]]
        @test_throws NotInCategory S[id(A)]      # does not land in X
        @test_throws NotInCategory S[A]          # not a morphism

        t = terminal(S)
        @test t == S[id(X)]
        u = canonicalHom(f, t)
        @test object(Hom(f, t)[arrow(f)]) == object(u)   # rechecked
        @test_throws NoCanonicalHomError canonicalHom(f, g)
    end

    @testset "Coslice" begin
        S = Coslice(X)
        @test S isa Coslice
        k = S[Hom(X, A)[t -> a[object(t)]]]
        l = S[Hom(X, B)[t -> b[object(t)]]]
        @test target(k) === A
        @test Hom(k, l)[h] isa OIC
        @test_throws NotInCategory Hom(k, l)[Hom(A, B)[t -> b[1]]]

        i = initial(S)
        @test i == S[id(X)]
        u = canonicalHom(i, l)
        @test object(Hom(i, l)[arrow(l)]) == object(u)   # rechecked
        @test_throws NoCanonicalHomError canonicalHom(k, l)
    end
end
