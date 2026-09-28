using Documenter
using Literate
using JuliaTopology

# Colors in example output (`ansicolor` below) are only kept when this is run
# with `julia --color=yes`; this makes them exact rather than the nearest of
# 256 terminal colors
ENV["COLORTERM"] = "truecolor"

# Turn each script in `examples/` into a tutorial page of `docs/src/tutorials/`,
# whose code Documenter runs while building, showing its output. Scripts in
# `tutorialOrder` come first, then any others alphabetically.
tutorialOrder = ["getting-started.jl", "comma.jl", "limits.jl", "errors.jl"]
examplesDir = joinpath(@__DIR__, "..", "examples")
tutorialsDir = joinpath(@__DIR__, "src", "tutorials")
scripts = filter(endswith(".jl"), readdir(examplesDir))
tutorials = [
    filter(in(scripts), tutorialOrder);
    sort(filter(!in(tutorialOrder), scripts))
]
for file in tutorials
    Literate.markdown(joinpath(examplesDir, file), tutorialsDir;
        documenter=true, credit=false)
end

makedocs(
    sitename = "JuliaTopology.jl",
    modules = [JuliaTopology],
    format = Documenter.HTML(ansicolor=true),
    pages = [
        "Home" => "index.md",
        "Tutorials" => [joinpath("tutorials", replace(file, ".jl" => ".md"))
            for file in tutorials],
        "Manual" => [
            "Objects and categories" => "manual/objects.md",
            "Morphisms" => "manual/morphisms.md",
            "Finite sets" => [
                "The category FinSet" => "manual/finset.md",
                "Elements of a set" => "manual/finset-elements.md",
                "Maps of finite sets" => "manual/finset-morphisms.md",
            ],
            "Comma categories" => "manual/comma.md",
            "Limits and colimits" => "manual/limits.md",
            "Opposite categories" => "manual/opposite.md",
            "Lifts (disabled)" => "manual/lifts.md",
        ],
        "API Reference" => [
            "Core" => "api/core.md",
            "Finite sets" => "api/finite-sets.md",
            "Functors and comma categories" => "api/functors.md",
            "Limits and colimits" => "api/limits.md",
            "Printing and settings" => "api/printing.md",
        ],
        "Developer Docs" => [
            "Design guide" => "dev/design.md",
            "Style guide" => "dev/style.md",
            "Design conventions" => "dev/conventions.md",
            "Writing docs and examples" => "dev/writing-docs.md",
            "Review checklist" => "dev/review-checklist.md",
        ],
    ],
)

deploydocs(
    repo = "github.com/brandon-feder/JuliaTopology.git",
    devbranch = "main",
)
