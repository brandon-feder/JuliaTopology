# Clanker Checks

These are directions that should be read by
a clanker before merging into the main branch.

I want you to check that this repository is of the highest
quality before merging. Please do the following in order. Flag
to the user any concerns. You may suggest, but do not immediately
implement fixes, even to minor issues.

1. Read `guide.md` and `style.md` in `./docs/src`.
2. Make sure all categories and their implementations agree with `guide.md`.
3. Flag which functions, both exported and not, do not adhere to `style.md`.
4. Make sure every `checkInCategory()`/`checkInterface()` is exercised for
    each implementation of a category in the unit tests.
5. Every category with more than one implementation should contain unit
    tests making sure the output of every function in both the required and
    standardized interfaces is identical across implementations.
6. There should be no export statement for undefined functions,
    variables, or types. In particular, a name that only appears inside a
    docstring's example code (e.g. a ```` ```julia ```` fence) does not count
    as defined — check that every exported name has a real, non-docstring
    definition somewhere in `src/`.
7. All functions, variables, and types should be exported once.
    The `export` statement in which they appear should be below
    the file they are defined in. If a function is overloaded
    in several different files, it should be defined but not declared
    once. If that function is in the required interface of a category,
    it should be defined but not declared in the file which that category
    is described in.
8. All files in which a category is defined should be divided into sections
    such as "Required Interface," "Standardized Interface," etc., per the
    "File Organization" section of `style.md`.
9. Every category should overload `name(cat)` for itself (and, if its own
    printed name needs it, `name(oic)` for its objects) — per the "Printing"
    section of `style.md`. Neither should need to overload `Base.show`
    directly; flag it if one does.
10. All exported functions should appear in the documentation, meaning each
    has a docstring that Documenter's `@autodocs` in `api.md` will actually
    render — not just a mention inside another docstring's prose. See the
    "Docstrings" section of `style.md`.
11. Every `.jl` file under `src/` should be reachable via `include` from
    `JuliaTopology.jl`. Flag any file that is never `include`d, and any
    `include`d file that is empty or does not compile.
12. For every category, the bullets under its docstring's
    `# Required Interface` heading should match exactly what that
    category's `checkInterface` asserts — flag any required
    function that is documented but not checked, or checked but not
    documented. Membership rules enforced by `checkInCategory` are a separate
    thing (see `checkInCategory`'s own docstring/interface) and should not be
    listed here.
13. Any constructor or conversion that re-validates an already-known-valid
    object should accept a `force::Bool=false` keyword to skip that, per the
    "The `force` Flag" section of `style.md` — flag any that don't.
14. `docs/src/*.md` must build cleanly with `julia --project=docs
    docs/make.jl`: every `@ref` must resolve and every exported name must
    have a docstring reachable from `@autodocs` in `api.md`. Flag any build
    error or warning.
15. All documentation — docstrings and files under `docs/src/` alike — should
    stay terse and minimal, matching the style already in the repository
    (see e.g. `CatFinSet`'s docstring or `finset-category.md`): short
    declarative bullets over prose, one small example rather than several,
    no restating what a signature already says. Flag any documentation that
    is verbose, redundant with a docstring already covering the same ground,
    or written in a noticeably different voice than the rest of the docs.
