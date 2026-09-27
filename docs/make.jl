using Documenter
using Literate
using JuliaTopology

# Colors in example output (`ansicolor` below) are only kept when this is run
# with `julia --color=yes`; this makes them exact rather than the nearest of
# 256 terminal colors
ENV["COLORTERM"] = "truecolor"

# Turn each script in `examples/` into a page of `docs/src/examples/`, whose
# code Documenter runs while building, showing its output
examplesDir = joinpath(@__DIR__, "..", "examples")
generatedDir = joinpath(@__DIR__, "src", "examples")
examples = sort(filter(endswith(".jl"), readdir(examplesDir)))
for file in examples
    Literate.markdown(joinpath(examplesDir, file), generatedDir;
        documenter=true, credit=false)
end

makedocs(
    sitename = "JuliaTopology.jl",
    modules = [JuliaTopology],
    format = Documenter.HTML(ansicolor=true),
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
        "Categories" => "category.md",
        "Homs Between Categories" => "hom.md",
        "Lifts Between Categories" => "lifts.md",
        "The category FinSet" => "finset-category.md",
        "Finite Sets as Categories" => "finset-elements.md",
        "Morphisms of FinSet and FinCard" => "finset-morphisms.md",
        "Comma Categories" => "comma.md",
        "Examples" => [joinpath("examples", replace(file, ".jl" => ".md"))
            for file in examples],
        "API Reference" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/brandon-feder/JuliaTopology.git",
    devbranch = "main",
)
