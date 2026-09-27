# Writing docs and examples

## Layout

| Section | Source |
|---|---|
| Tutorials | `examples/*.jl`, converted by Literate into `docs/src/tutorials/` |
| Manual | `docs/src/manual/`, one page per concept |
| API Reference | `docs/src/api/`, one `@autodocs` block per group of source files |
| Developer Docs | `docs/src/dev/` |

The navigation is set in `docs/make.jl`.

## Building

```
julia --color=yes --project=docs docs/make.jl
```

`--color=yes` is required for the colors of printed output to appear on the
pages; without it, they build uncolored. The first time, run
`julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'`.

## Tutorials

Each script in `examples/` becomes a tutorial page, whose code Documenter runs
while building and whose output it shows. Scripts listed in `tutorialOrder` in
`docs/make.jl` come first; any others follow alphabetically. A script is
written with [Literate](https://fredrikekre.github.io/Literate.jl/) syntax:

- `# # Title` is the page title, and `# ## Section` a section.
- Other lines starting with `# ` are prose; `## ` is a comment kept in code.
- Each run of code becomes one block, whose output is shown under it; `#-`
  splits a block.
- A block ending in a value displays it in the REPL's tree form; end it with
  `nothing #hide` to show nothing.
- An uncaught error fails the build, so wrap errors being shown in
  `try … catch e; showerror(stdout, e) end`.

The script still runs on its own with
`julia --color=yes --project=. examples/<name>.jl`.

## API Reference

Each page of `docs/src/api/` lists the docstrings of the source files named in
its `Pages` filter. A new source file must be added to one of them; otherwise
the build fails, reporting its docstrings as missing.
