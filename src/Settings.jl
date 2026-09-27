"""
    COLORFUL = true

Whether `Base.show` and `Base.print` output
should be colorful.
"""
COLORFUL::Bool = true

"""
    function setColorfulOutput!(enable::Bool)

Whether or not to enable colorful text output.
"""
function setColorfulOutput!(enable::Bool)
    global COLORFUL = enable
end

"""
    MAX_NAME_LENGTH = 60

The most characters of a name shown in the compact display of an object; longer
names are cut short with `…`. The tree display always shows the full name.
"""
MAX_NAME_LENGTH::Int = 60

"""
    function setMaxNameLength!(n::Int)

Set [`MAX_NAME_LENGTH`](@ref).
"""
function setMaxNameLength!(n::Int)
    global MAX_NAME_LENGTH = n
end

"""
    MAX_SET_MAP_PAIRS_SHOWN = 3

The most pairs of a map of finite sets listed in its name, e.g.
`{1 ↦ :a, 2 ↦ :b, 3 ↦ :c, …}`, and the most elements listed in its error
messages.
"""
MAX_SET_MAP_PAIRS_SHOWN::Int = 3

"""
    function setMaxSetMapPairsShown!(n::Int)

Set [`MAX_SET_MAP_PAIRS_SHOWN`](@ref).
"""
function setMaxSetMapPairsShown!(n::Int)
    global MAX_SET_MAP_PAIRS_SHOWN = n
end
