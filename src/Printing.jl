TAB = "    "

# =========================================================
# ======================== COLORS =========================
# =========================================================

# The faces (named styles) used to color output. They can be customized like
# any other face, e.g. in `~/.julia/config/faces.toml`:
#     [juliatopology]
#     object = { foreground = "blue" }
const FACES = [
    :juliatopology_object => Face(foreground=0x4063d8, weight=:bold),
    :juliatopology_category => Face(foreground=0x9558b2),
    :juliatopology_datatype => Face(foreground=0x389826, slant=:italic),
    :juliatopology_function => Face(weight=:bold),
    :juliatopology_value => Face(foreground=0xd18616),
    :juliatopology_tree => Face(foreground=0x808080),
]

# Faces of highlighted Julia code which are replaced by our own, so that e.g.
# types in code look like the datatypes elsewhere in the output. Julia's
# defaults leave these faces uncolored.
const CODE_FACES = Dict(
    :julia_type => :juliatopology_datatype,
    :julia_funcall => :juliatopology_function,
    :julia_funcdef => :juliatopology_function,
)

function __init__()
    foreach(addface!, FACES)
end

# `x` as a string in the face `face`, or plainly when `COLORFUL` is off.
# Whether color is actually shown is up to the `IO` it is printed to.
function styled(x, face::Symbol)
    str = string(x)
    COLORFUL || return str
    return AnnotatedString(str, [(1:ncodeunits(str), :face, face)])
end

objclr(x) = styled(x, :juliatopology_object)
catclr(x) = styled(x, :juliatopology_category)
dtclr(x) = styled(x, :juliatopology_datatype)
treeclr(x) = styled(x, :juliatopology_tree)

"""
    valclr(x)

`repr(x)` colored as a plain Julia value, i.e. one not wrapped in any
category. Use it when interpolating such values into messages.
"""
valclr(x) = styled(repr(x), :juliatopology_value)

"""
    codeclr(code::AbstractString)

`code` syntax highlighted as Julia code. Use it for code snippets in messages,
e.g. a method to overload.
"""
function codeclr(code::AbstractString)
    COLORFUL || return String(code)
    hl = highlight(code)
    return AnnotatedString(String(hl), [
        (a.region, a.label, get(CODE_FACES, a.value, a.value))
        for a in annotations(hl)
    ])
end

annotatedArg(x::Union{OIC, Category}) = coloredPrint(x)

"""
    name(oic::OIC)::String

Returns a string which is what an instance of `ObjectInCategory` should
be called. By default this is the compact `repr` of the underlying object.
Overload it for objects whose `repr` is long or unclear; in the compact
display it is cut short after [`MAX_NAME_LENGTH`](@ref) characters anyway.
"""
function name(oic::OIC)::String
    return repr(object(oic); context=:compact => true)
end

# `name(oic)` cut short to `MAX_NAME_LENGTH` characters, for the compact display
function shortName(oic::OIC)
    str = name(oic)
    length(str) <= MAX_NAME_LENGTH && return str
    return first(str, MAX_NAME_LENGTH - 1)*"…"
end

"""
    name(cat::Category)::String

Returns a string which is what the category should be called. By
default returns `string(nameof(typeof(cat)))`
"""
function name(cat::Category)::String
    return string(nameof(typeof(cat)))
end

"""
    overloadHint(fname, args::NTuple{3, AbstractString}...)

The end of a message telling the user which method to overload. Each argument
is `(argname, description, type)`: `description` says in English which values
the method applies to (e.g. "an element of Hom(X, Y)"), and `type` is its
exact type in the method's signature. `fname` is the function's name, or
`nothing` when the first argument is itself the thing being called.
"""
function overloadHint(fname, args::NTuple{3, AbstractString}...)
    argnames = [a[1] for a in args]
    typed = ["$(a[1])::$(a[3])" for a in args]
    call, sig = if fname === nothing
        "$(argnames[1])($(join(argnames[2:end], ", ")))",
        "($(typed[1]))($(join(typed[2:end], ", ")))"
    else
        "$fname($(join(argnames, ", ")))", "$fname($(join(typed, ", ")))"
    end
    wheres = join((@annotated("$TAB$(a[1]) is $(a[2])") for a in args), ",\n")
    return @annotated """
        $TAB$(codeclr(call))
        where
        $wheres,
        that is, the method
        $TAB$(codeclr(sig))"""
end

"""
    typeString(T)::String

`string(T)`, writing `ObjectInCategory` by its alias `OIC` as messages do.
"""
typeString(T) = replace(string(T), "ObjectInCategory{" => "OIC{")

# The categories an argument of a method required by `cat` is likely to belong
# to: `cat` itself and, for morphisms, their domain and codomain as categories
relatedCategories(cat) = Any[cat]
relatedCategories(cat::Hom) = Any[cat, OICAsCat(domain(cat)),
    OICAsCat(codomain(cat)), category(cat)]

# English description of an argument of type `T` in a required method of
# `cat`, for `overloadHint`
function describeArgType(T, cat)
    U = Base.unwrap_unionall(T)
    if U isa DataType && U.name.wrapper === ObjectInCategory
        objT, catT = U.parameters
        for C in relatedCategories(cat)
            typeof(C) == catT || continue
            noun = C isa OICAsCat ? "element" : "object"
            objT isa TypeVar && return @annotated("any $noun of $C")
            return @annotated("an $noun of $C represented by values of type \
                $(dtclr(typeString(objT)))")
        end
    end
    return T == Any ? "any value" :
        @annotated("any value of type $(dtclr(typeString(T)))")
end

# `show(io, x)` is the compact, single line form used inside messages and
# collections; `show(io, MIME"text/plain"(), x)` is what the REPL displays
# for a single value, and lays out every layer as a tree.
Base.show(io::IO, oic::OIC) = print(io, coloredPrint(oic))
Base.show(io::IO, cat::Category) = print(io, coloredPrint(cat))

function Base.show(io::IO, ::MIME"text/plain", x::Union{OIC, Category})
    print(io, coloredTree(x))
end

# =========================================================
# ==================== COMPACT DISPLAY ====================
# =========================================================

"""
    coloredPrint(x::Union{OIC, Category})::String

The compact, single line display of `x`: an object as `name ∈ category`, and a
category by its name alone. Julia datatypes are omitted, any category nested
inside another is shortened to the names of its objects, e.g. `f ∈ Hom(X, Y)`,
and each name is cut short after [`MAX_NAME_LENGTH`](@ref) characters.
"""
function coloredPrint end

coloredPrint(cat::Category) = catclr(name(cat))

coloredPrint(oic::OIC) = objclr(shortName(oic))*" ∈ "*coloredPrint(category(oic))

coloredPrint(cat::OICAsCat) = catclr("ascat(")*objclr(shortName(oic(cat)))*catclr(")")

name(H::Hom) = "Hom($(shortName(domain(H))), $(shortName(codomain(H))))"

function coloredPrint(hom::Hom)
    return catclr("Hom(")*objclr(shortName(domain(hom)))*catclr(", ")*
        objclr(shortName(codomain(hom)))*catclr(")")
end

# =========================================================
# ===================== TREE DISPLAY ======================
# =========================================================

"""
    coloredTree(x::Union{OIC, Category})::String

The full, multi-line display of `x`: every object with its Julia datatype,
and below it, the category it lives in, recursively. Each child is labeled by
its relation to its parent (`∈`, `of`, `domain`, ...).
"""
function coloredTree(x)
    lines = AbstractString[]
    treeLines!(lines, x, "", "")
    return join(lines, "\n")
end

# The label of a node and its `(relation, child)` pairs. `withcat` is whether
# an object should list its category as a child, which a `Hom` omits for its
# domain and codomain since it lists their shared category itself.
function treeNode(oic::OIC; withcat=true)
    label = objclr(name(oic))*" :: "*dtclr(string(typeof(object(oic))))
    return label, withcat ? ["∈" => category(oic)] : Pair{String, Any}[]
end

function treeNode(cat::Category; withcat=true)
    return catclr(name(cat))*" :: "*dtclr(string(typeof(cat))), Pair{String, Any}[]
end

function treeNode(cat::OICAsCat; withcat=true)
    return coloredPrint(cat), ["of" => oic(cat)]
end

function treeNode(hom::Hom; withcat=true)
    return coloredPrint(hom), [
        "domain" => (domain(hom), false),
        "codomain" => (codomain(hom), false),
        "in" => category(hom),
    ]
end

# Append to `lines` the tree rooted at `x`. `head` prefixes the line of `x`
# itself, and `indent` the lines of its descendants.
function treeLines!(lines, x, head, indent)
    node, withcat = x isa Tuple ? x : (x, true)
    label, children = treeNode(node; withcat=withcat)
    push!(lines, head*label)
    width = maximum((length(first(c)) for c in children); init=0)
    for (i, (relation, child)) in enumerate(children)
        isLast = i == length(children)
        branch = treeclr(isLast ? "└─ " : "├─ ")*treeclr(rpad(relation, width))*" "
        treeLines!(lines, child, indent*branch,
            indent*treeclr(isLast ? "   " : "│  "))
    end
end
