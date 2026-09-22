OBJECT_CRAYON = Crayon()
CATEGORY_CRAYON = Crayon()
DATATYPE_CRAYON = Crayon()

# set colors if `COLORFUL == true`
if COLORFUL
    OBJECT_CRAYON = Crayon(foreground=(64, 99, 216), bold=true)
    CATEGORY_CRAYON = Crayon(foreground=(149, 88, 178), bold=true)
    DATATYPE_CRAYON = Crayon(foreground=(56, 152, 38), bold=true, italics=true)
end

objclr(x) = OBJECT_CRAYON*x
catclr(x) = CATEGORY_CRAYON*x
dtclr(x) = DATATYPE_CRAYON*x

"""
    name(oic::OIC)::String

Returns a string which is what oic should be called. By
default this just overloads to calling `repr` on the underlying
object.
"""
function name(oic::OIC)::String
    return repr(object(oic))
end

"""
    name(oic::Category)::String

Returns a string which is what the category should be called. By
default returns `string(nameof(typeof(cat)))`
"""
function name(cat::Category)::String
    return string(nameof(typeof(cat)))
end

function Base.print(io::IO, oic::OIC)
    print(io, coloredPrint(oic))
end

function Base.print(io::IO, cat::Category)
    print(io, coloredPrint(cat))
end

function Base.show(io::IO, oic::OIC)
    Base.print(io, oic)
end

function Base.show(io::IO, cat::Category)
    Base.print(io, cat)
end