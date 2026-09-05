using Documenter
using JuliaTopology

makedocs(
    sitename = "JuliaTopology.jl",
    modules = [JuliaTopology, JuliaTopology.Pretty, JuliaTopology.Presets],
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Examples" => "examples.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/brandon-feder/JuliaTopology.git",
    devbranch = "main",
)
