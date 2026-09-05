using MAT

using JuliaTopology
using JuliaTopology.Pretty
using LinearAlgebra

# read matrix from ./data/cyclooctane.mat
points = matread("./data/cyclooctane.mat")["pointsCycloOctane"]

# compute distance matrix
n = size(points, 1)
f = (i::Int, j::Int) -> view(points, i, :) * view(point, j, :)'

# store as metric space
metricSpace = @wrap GenericMetricSpace(f, n) MetricSpace

# access info about metric space
println("$INF # points: $(nPoints(metricSpace))")