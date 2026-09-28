@testset "Op" begin
    qp = q ∘ p

    @testset "objects and morphisms" begin
        @test op(C) == Op(C) && op(op(C)) == C
        @test category(op(X)) == Op(C) && op(op(X)) === X
        @test domain(category(op(p))) == op(Y) && codomain(category(op(p))) == op(X)
        @test op(op(p)) === p
        @test_throws NotInCategory Hom(op(X), op(Y))[GenericMorphOp(p)]  # wrong way round
    end

    @testset "structure by duality" begin
        @test agrees(op(p) ∘ op(q), op(qp))
        @test agrees(id(op(X)), op(id(X)))
        @test isMono(op(p)) == isEpi(p) && isEpi(op(p)) == isMono(p)
        @test isIso(op(id(X))) && !isIso(op(p))
        @test agrees(inv(op(id(X))), op(id(X)))
        @test firstDifference(op(r), op(qp)) !== nothing
        @test_throws InterfaceViolation terminal(Op(C))   # the initial object of C
    end

    @testset "shapes and diagrams" begin
        J = cospanShape()
        @test vertices(op(J)) == vertices(J)
        @test generators(op(J)) == (3 => 1, 3 => 2)
        D = cospan(q, r)
        @test op(op(D)) == D
        @test arrows(op(D)) == (op(q), op(r))
    end

    @testset "cocones are opposite cones" begin
        D = discrete(X, Y)
        @test Cocone(D) == Op(Cone(op(D))) && Cocone(D) isa Cocone
        @test diagram(Cocone(D)) == D
        c = Cocone(D)[qp, q]                         # legs into Z
        @test apex(c) === Z && legs(c) == (qp, q) && leg(c, 1) == qp
        @test_throws NotInCategory Cocone(D)[p, q]   # different apexes
        m = Hom(c, c)[id(Z)]
        @test apexMorphism(m) == id(Z)
    end
end
