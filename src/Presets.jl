"""
Preset `GenericAbstractSimplicialComplex` triangulations of a few standard
surfaces, for testing and demonstration. Not exported from `JuliaTopology` --
access via `using JuliaTopology.Presets`.
"""
module Presets
    using ..JuliaTopology

    ASC = AbstractSimplicialComplex
    GenericASC = GenericAbstractSimplicialComplex

    sphereSimplices = [
        (1,), (2,), (3,), (4,),
        (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4),
        (1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4)
    ]

    torusSimplices = [
        (1,), (2,), (3,), (4,), (5,), (6,), (7,),
        (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
        (2, 3), (2, 4), (2, 5), (2, 6), (2, 7),
        (3, 4), (3, 5), (3, 6), (3, 7),
        (4, 5), (4, 6), (4, 7),
        (5, 6), (5, 7),
        (6, 7),
        (1, 2, 4), (1, 2, 6), (1, 3, 4), (1, 3, 7), (1, 5, 6), (1, 5, 7),
        (2, 3, 5), (2, 3, 7), (2, 4, 5), (2, 6, 7),
        (3, 4, 6), (3, 5, 6),
        (4, 5, 7), (4, 6, 7)
    ]

    kleinBottleSimplices = [
        (1,), (2,), (3,), (4,), (5,), (6,), (7,), (8,), (9,),
        (1, 2), (1, 3), (1, 4), (1, 6), (1, 7), (1, 8),
        (2, 3), (2, 4), (2, 5), (2, 8), (2, 9),
        (3, 4), (3, 5), (3, 6), (3, 9),
        (4, 5), (4, 7), (4, 9),
        (5, 6), (5, 7), (5, 8),
        (6, 7), (6, 8), (6, 9),
        (7, 8), (7, 9),
        (8, 9),
        (1, 2, 4), (1, 2, 8), (1, 3, 4), (1, 3, 6), (1, 6, 7), (1, 7, 8),
        (2, 3, 5), (2, 3, 9), (2, 4, 5), (2, 8, 9),
        (3, 4, 9), (3, 5, 6),
        (4, 5, 7), (4, 7, 9),
        (5, 6, 8), (5, 7, 8),
        (6, 7, 9), (6, 8, 9)
    ]

    realProjectivePlaneSimplices = [
        (1,), (2,), (3,), (4,), (5,), (6,),
        (1, 2), (1, 3), (1, 4), (1, 5), (1, 6),
        (2, 3), (2, 4), (2, 5), (2, 6),
        (3, 4), (3, 5), (3, 6),
        (4, 5), (4, 6),
        (5, 6),
        (1, 2, 3), (1, 2, 6), (1, 3, 4), (1, 4, 5), (1, 5, 6),
        (2, 3, 5), (2, 4, 5), (2, 4, 6),
        (3, 4, 6), (3, 5, 6)
    ]

    sphere = @wrap GenericASC(sphereSimplices) ASC
    torus = @wrap GenericASC(torusSimplices) ASC
    kleinBottle = @wrap GenericASC(kleinBottleSimplices) ASC
    realProjectivePlane = @wrap GenericASC(realProjectivePlaneSimplices) ASC

    export sphere, torus, kleinBottle, realProjectivePlane
end
