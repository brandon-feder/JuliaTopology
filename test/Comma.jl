@testset "Comma" begin
    I = id(Cat[C])
    qp = q ∘ p

    @testset "construction" begin
        @test Comma(I, I) isa Category
        @test I ↓ I == Comma(I, I)
        @test_throws ArgumentError Comma(I, X)
        @test_throws ArgumentError Comma(I, id(Cat[FinCard]))
    end

    K = I ↓ I   # the arrow category of C
    o1 = K[(X, Y, p)]
    o2 = K[(X, Z, qp)]

    @testset "objects" begin
        @test source(o1) === X && target(o1) === Y && arrow(o1) === p
        @test_throws NotInCategory K[(FinCard[3], Y, p)]
        @test_throws NotInCategory K[(Y, Y, p)]       # wrong domain
        @test_throws NotInCategory K[(X, Z, p)]       # wrong codomain
        @test_throws NotInCategory K[(X, Y, X)]       # not a morphism
        @test_throws NotInCategory K[X]               # not an object of K
    end

    @testset "morphisms" begin
        m = Hom(o1, o2)[(id(X), q)]                  # q ∘ p == (q ∘ p) ∘ id
        @test m isa OIC
        @test_throws NotInCategory Hom(K[(X, Y, p)], K[(X, Z, r)])[(id(X), q)]
        @test_throws NotInCategory Hom(o1, o2)[(id(Y), q)]
        @test category(id(o1)) isa Hom && isIso(id(o1))
        @test category(compose(m, id(o1))) isa Hom
        @test_throws ArgumentError compose(id(o1), m)
        @test agrees(object(inv(id(o1))).sourceMorph, id(X))
    end

    @testset "slice-like comma" begin
        S = I ↓ constant(Z)
        s1 = S[(X, Point[1], qp)]
        s2 = S[(Y, Point[1], q)]
        @test Hom(s1, s2)[(p, id(Point[1]))] isa OIC
        @test_throws NotInCategory Hom(S[(X, Point[1], r)], s2)[(p, id(Point[1]))]
    end

    @testset "over Cat" begin
        KC = Comma(id(Cat[Cat]), id(Cat[Cat]))
        oc = KC[(Cat[C], Cat[C], id(Cat[C]))]
        m = GenericMorphComma(id(Cat[C]), id(Cat[C]))
        @test_throws NotInCategory Hom(oc, oc)[m]
        @test Hom(oc, oc)[m, force=true] isa OIC
    end
end

@testset "Slice and Coslice" begin
    qp = q ∘ p

    @testset "Slice" begin
        S = Slice(Z)
        @test S == Slice(Z) && S isa Cone
        f, g = S[qp], S[q]
        @test apex(f) === X
        @test apexMorphism(Hom(f, g)[p]) === p         # q ∘ p == q ∘ p
        @test_throws NotInCategory Hom(S[r], g)[p]     # q ∘ p != r
        @test_throws NotInCategory S[p]                # does not land in Z
        @test_throws NotInCategory S[X]                # not a morphism
        @test_throws NotInCategory Cone(discrete(X, Y))[id(X)]   # two vertices
        @test_throws InterfaceViolation terminal(S)    # not computed for C
    end

    @testset "Coslice" begin
        S = Coslice(X)
        @test S isa Cocone
        k, l = S[p], S[qp]
        @test apex(k) === Y
        @test apexMorphism(Hom(k, l)[q]) === q
        @test_throws NotInCategory Hom(k, S[r])[q]
        @test_throws InterfaceViolation initial(S)
    end
end
