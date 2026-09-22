"""
    Cat()

The category of all categories.
"""
struct CatCat <: Category end
Cat = CatCat()

# declare all other categories as objects
inCategory(::Category, ::CatCat) = true
checkInterface(::Category, ::CatCat) = true

# set the name of the category
name(::CatCat) = "Cat"

# set the name of objects
name(oic::OIC{T, CatCat}) where T = name(object(oic))
