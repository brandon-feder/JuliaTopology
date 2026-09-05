"""
    struct MetricSpace <: AbstractCategory end

Objects in this category have the following interfaces.

# Required Interface
- `nPoints(obj)::Int` - Number of points in metric space.
- `distance(obj, i::Int, j::Int)::Float64` - Distance between i-th and j-th points.

# Standardized Interface
- `diameter(obj)::Float64` - Diameter of metric space
"""
struct MetricSpace <: AbstractCategory end

# =========================================================
# ================ STANDARDIZED INTERFACE =================
# =========================================================

# function diameter(
#     A::ObjectInCategory{T, MetricSpace}
# ) where T
#     n = nPoints(A)
#     return foldl(max, Map(((x, y),) -> x * y), zip(1:n, 1:n))
# end