using Documenter
using JuliaTopology

makedocs(
    sitename = "JuliaTopology.jl",
    modules = [JuliaTopology, JuliaTopology.Pretty, JuliaTopology.Presets],
    remotes = nothing, # no GitHub remote yet
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Examples" => "examples.md",
        "API Reference" => "api.md",
    ],
)
