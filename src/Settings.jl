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
