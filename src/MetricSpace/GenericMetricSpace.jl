"""
    GenericMetricSpace

The generic object for the category `MetricSpace`. Stores
a function giving the distance between pair of integers,
as well as the total number of points.

# Members
- `distance` - A function that accepts two integers indexing
a pair of points in the space, and returns their distance.
- `nPoints::Int` - Number of points in the space
"""
struct GenericMetricSpace
    distance::FunctionWrapper{Float64, Tuple{Int, Int}}
    nPoints::Int
end

inCategory(obj::GenericMetricSpace, ::Type{MetricSpace}) = true

# =========================================================
# ================== REQUIRED INTERFACE ===================
# =========================================================

function nPoints(
    A::ObjectInCategory{GenericMetricSpace, MetricSpace}
)
    return A.object.nPoints
end

function distance(
    A::ObjectInCategory{GenericMetricSpace, MetricSpace},
    i::Int, j::Int
)
    return A.object.distance(i, j)
end