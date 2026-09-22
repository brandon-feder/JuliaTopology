"""
    struct CatFinCard

The category of finite cardinals; The skeleton of FinSet.
The objects in this category are integers. New objects
should not be associated with this, and so no required interface
is provided.

# Standardized Interface
- `cardinality(OIC{Int, CatFinCard})::Int` - The cardinality
"""
struct CatFinCard <: Category end
FinCard = CatFinCard()

JuliaTopology.inCategory(::Int, ::CatFinCard) = true
JuliaTopology.checkInterface(::Int, ::CatFinCard) = true

JuliaTopology.cardinality(card::OIC{Int, CatFinCard}) = object(card)

JuliaTopology.areIsomorphic(
    cardA::OIC{Int, CatFinCard}, 
    cardB::OIC{Int, CatFinCard}
) = (cardinality(cardA) == cardinality(cardB))

(≅)(
    cardA::OIC{Int, CatFinCard}, 
    cardB::OIC{Int, CatFinCard}
) = areIsomorphic(cardA, cardB)
JuliaTopology.name(::CatFinCard) = "FinCard"