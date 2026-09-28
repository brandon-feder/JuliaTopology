@testset "Comma" begin
    A, B, B2 = FinSet[1:3], FinSet[1:2], FinSet[1:4]
    a, b, b2 = ascat(A), ascat(B), ascat(B2)
    I = id(Cat[FinSet])
    h = Hom(A, B)[x -> b[mod1(object(x), 2)]]
    incl = Hom(B, B2)[y -> b2[object(y)]]
    shift = Hom(B, B2)[y -> b2[object(y) + 1]]

    @testset "construction" begin
        @test Comma(I, I) isa Category
        @test I ↓ I == Comma(I, I)
        @test_throws ArgumentError Comma(I, A)
        @test_throws ArgumentError Comma(I, id(Cat[FinCard]))
    end

    K = I ↓ I   # the arrow category of FinSet
    o1 = K[GenericComma(A, B, h)]
    o2 = K[GenericComma(A, B2, compose(incl, h))]

    @testset "objects" begin
        @test source(o1) === A && target(o1) === B && arrow(o1) === h
        @test_throws NotInCategory K[GenericComma(FinCard[3], B, h)]
        @test_throws NotInCategory K[GenericComma(B, B, h)]     # wrong domain
        @test_throws NotInCategory K[GenericComma(A, B2, h)]    # wrong codomain
        @test_throws NotInCategory K[GenericComma(A, B, A)]     # not a morphism
    end

    @testset "morphisms" begin
        m = Hom(o1, o2)[GenericMorphComma(id(A), incl)]
        @test m isa OIC
        @test_throws NotInCategory Hom(o1, o2)[GenericMorphComma(id(A), shift)]
        @test_throws NotInCategory Hom(o1, o2)[GenericMorphComma(id(B), incl)]
        @test category(id(o1)) isa Hom
        @test category(compose(m, id(o1))) isa Hom
        @test_throws ArgumentError compose(id(o1), m)
    end

    @testset "slice-like comma" begin
        S = I ↓ constant(B)
        s1 = S[GenericComma(A, Point[:pt], h)]
        s2 = S[GenericComma(B, Point[:pt], id(B))]
        @test Hom(s1, s2)[GenericMorphComma(h, id(Point[:pt]))] isa OIC
        @test_throws NotInCategory Hom(s1, s2)[
            GenericMorphComma(Hom(A, B)[x -> b[1]], id(Point[:pt]))]
    end

    @testset "over a category other than FinSet" begin
        KC = Comma(id(Cat[Cat]), id(Cat[Cat]))
        oc = KC[GenericComma(Cat[FinSet], Cat[FinSet], id(Cat[FinSet]))]
        m = GenericMorphComma(id(Cat[FinSet]), id(Cat[FinSet]))
        @test_throws NotInCategory Hom(oc, oc)[m]
        @test Hom(oc, oc)[m, force=true] isa OIC
    end
end

@testset "Slice and Coslice" begin
    X, A, B = FinSet[1:2], FinSet[1:3], FinSet[1:4]
    x, a, b = ascat(X), ascat(A), ascat(B)
    h = Hom(A, B)[t -> b[object(t)]]

    @testset "Slice" begin
        S = Slice(X)
        @test S == Slice(X) && S isa Cone
        f = S[Hom(A, X)[t -> x[mod1(object(t), 2)]]]
        g = S[Hom(B, X)[t -> x[mod1(object(t), 2)]]]
        @test apex(f) === A
        @test Hom(f, g)[h] isa OIC
        @test_throws NotInCategory Hom(f, g)[Hom(A, B)[t -> b[object(t) + 1]]]
        @test_throws NotInCategory S[id(A)]      # does not land in X
        @test_throws NotInCategory S[A]          # not a morphism
        @test_throws ArgumentError Cone(discrete(A, B))[id(A)]   # two legs

        t = terminal(S)
        @test cardinality(apex(t)) == cardinality(X)
        u = canonicalHom(f, t)
        @test Hom(f, t)[apexMorphism(u)] isa OIC   # rechecked
        @test canonicalHom(S[id(X)], t) isa OIC           # id(X) is terminal too
        @test_throws NoCanonicalHomError canonicalHom(f, g)
    end

    @testset "Coslice" begin
        S = Coslice(X)
        @test S isa Cocone
        k = S[Hom(X, A)[t -> a[object(t)]]]
        l = S[Hom(X, B)[t -> b[object(t)]]]
        @test apex(k) === A
        @test Hom(k, l)[h] isa OIC
        @test_throws NotInCategory Hom(k, l)[Hom(A, B)[t -> b[1]]]

        i = initial(S)
        @test cardinality(apex(i)) == cardinality(X)
        v = canonicalHom(i, l)
        @test Hom(i, l)[apexMorphism(v)] isa OIC   # rechecked
        @test canonicalHom(S[id(X)], l) isa OIC           # id(X) is initial too
    end
end
