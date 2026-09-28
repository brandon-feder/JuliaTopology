@testset "Universal constructions" begin
    A, B, C = FinSet[1:3], FinSet[[:a, :b]], FinSet[[:even, :odd]]
    a, b, c = ascat(A), ascat(B), ascat(C)
    parity = Hom(A, C)[x -> iseven(x) ? :even : :odd, values=true]
    allOdd = Hom(A, C)[x -> :odd, values=true]
    D = parallelPair(parity, allOdd)

    @testset "natural transformations in the arrow category" begin
        J, K = parallelPairShape(), FunctorCat(parallelPairShape(), FinSet)
        D₂ = parallelPair(parity, parity)
        η = Hom(K[D₂], diagonal(J, FinSet)(C))[(X = parity, Y = id(C))]
        @test components(η) == (X = parity, Y = id(C))
        E = object(η).diagram
        @test category(E) == Hom(Cat[J], Cat[arrowCategory(FinSet)])
        @test arrow(E(:X)) === parity
    end

    @testset "limits are terminal cones" begin
        L = limit(D)
        @test cardinality(apex(L)) == cardinality(apex(terminal(Cone(D))))
        @test cardinality(apex(universalArrow(Cone(D)))) == 2   # the odd numbers
        @test_throws InterfaceViolation terminal(Cone(diagram(emptyShape(), Cat)))
    end

    @testset "the elements of a limit are the cones from a point" begin
        L = limit(D)
        @test length(pointCones(D)) == cardinality(apex(L))
        T = terminal(FinSet)
        for p in apex(L)
            # the cone from the point picking out `p`, and its factorization
            cone = Cone(D)[T, map(globalElement, object(p))]
            u = canonicalHom(cone, L)
            @test element(apexMorphism(u)) == p
        end
    end

    @testset "colimits are components of the category of elements" begin
        E = ∫(D)
        @test E[(vertex = :X, element = a[1])] isa OIC
        @test_throws NotInCategory E[(vertex = :X, element = c[:odd])]
        @test cardinality(objectSet(E)) == cardinality(A) + cardinality(C)
        @test objectSet(E) == objectSet(∫(D))

        q = componentMap(E)
        @test isEpi(q) && cardinality(π₀(E)) == cardinality(apex(colimit(D))) == 1
        S = objectSet(E)
        o(j, x) = ascat(S)[(vertex = j, element = x)]
        @test q(o(:X, a[1])) == q(o(:Y, c[:odd]))              # identified
        F = fiber(q, q(o(:X, a[1])))
        @test cardinality(apex(F)) == cardinality(S)
        @test isMono(leg(F, :A))                              # a subobject of S
        f = Hom(A, C)[x -> iseven(x) ? :even : :odd, values=true]
        @test Set(object(object(p).A) for p in apex(fiber(f, c[:odd]))) == Set([1, 3])

        # a coproduct identifies nothing
        E₂ = ∫(discrete(A, C))
        @test cardinality(π₀(E₂)) == cardinality(A) + cardinality(C)
    end

    @testset "functors carry cones" begin
        L = limit(D)
        image_ = mapCone(id(Cat[FinSet]), L)
        @test apex(image_) === apex(L)
        Q = colimit(D)
        @test apex(mapCone(id(Cat[FinSet]), Q)) === apex(Q)
    end

    @testset "hom-sets" begin
        H = homSet(A, B)
        @test cardinality(H) == 8
        @test length(unique(Tuple(object(object(f)(x)) for x in A) for f in H)) == 8
        f = Hom(A, B)[x -> :a, values=true]
        @test f in object(H) && !(id(A) in object(H))

        ev = evaluation(A, B)
        p = first(apex(product(H, A)))
        @test ev(p) == object(object(p).X1)(object(p).X2)

        h = curry(Hom(C × A, B)[q -> ascat(B)[object(object(q).X2) == 1 ? :a : :b]], C, A)
        @test object(h(c[:odd]))(a[1]) == ascat(B)[:a]
        @test agrees(uncurry(h, A), Hom(C × A, B)[q -> ascat(B)[object(object(q).X2) == 1 ? :a : :b]])

        # unique maps are the only element of their hom-set
        @test cardinality(homSet(A, terminal(FinSet))) == 1
        @test cardinality(homSet(initial(FinSet), A)) == 1
        @test canonicalHom(A, terminal(FinSet)) in object(homSet(A, terminal(FinSet)))
    end

    @testset "representable functors" begin
        F, G = homFrom(A), homTo(A)
        @test F(B) == homSet(A, B) && G(op(B)) == homSet(B, A)
        k = Hom(B, C)[y -> y == :a ? :odd : :even, values=true]
        Fk = F(k)
        f = first(F(B))                       # an element of homSet(A, B)
        @test agrees(object(Fk(f)), compose(k, object(f)))
        g = first(homSet(C, A))
        Gk = G(op(k))
        @test agrees(object(Gk(g)), compose(object(g), k))
    end

    @testset "image factorization" begin
        f = Hom(A, B)[x -> :a, values=true]
        I = image(f)
        @test cardinality(I) == 1
        e, m = imageFactorization(parity)
        @test isEpi(e) && isMono(m) && agrees(m ∘ e, parity)
    end

    @testset "cocone commutativity" begin
        X = FinSet[[:x, :y]]
        @test_throws NotInCategory Cocone(D)[(
            X = Hom(A, X)[t -> iseven(t) ? :x : :y, values=true],
            Y = Hom(C, X)[t -> :y, values=true])]
    end
end
