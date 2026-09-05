# Guide

Julia suits this design well: duck typing lets `inCategory` check "is this shaped like a metric space" instead of forcing objects into a fixed type hierarchy, and JIT specialization means each generic function still compiles down to code as fast as a hand-written C++ method per concrete type — a combination neither Python (duck typing, no JIT specialization) nor C++ (specialization, but nominal typing) offers together.

## Structure of Types

First-class entities in this library are *objects*. Each object belongs to one or more *categories*. Categories are specified by tags which inherit the abstract type `AbstractCategory`. A particular object of type `SomeObject` which belongs to a category `SomeCategory` should overload
```julia
inCategory(obj::SomeObject, ::Type{SomeCategory}) = true
```

Every object in a category has as *required interface* and a *standardized interface*. The required interface specifies what needs to be overloaded for that category, and the standardized interface, which includes the required interface, specifies what functions act the same for all objects in that category. Functions which are in the standard interface but not the required interface have a default implementation. In general, the standardized interface *does not* specify mutating functions.

While objects may belong to multiple categories, in order to avoid multiple-dispatch ambiguity, most functions in the library expect objects to be wrapped in a `ObjectInCategory` object.

To each category there is a unique *generic object*, and every object within a category should specify how to be converted to a generic object by overloading
```julia
Base.convert(::Type{SomeGenericObject}, obj)
```
Furthermore, the conversion should be "natural" in that for any function `standardizedFunction` in the standardized interface, the behavior of the object should be the same regardless of whether the object was made generic before or after being passed to `standardizedFunction`. Loosely speaking, the following should succeed:
```julia
X = standardizedFunction(
    convert(GenericObject, a),
    convert(GenericObject, b),
    ...
)
Y = convert(GenericObject,
    standardizedFunction(
        a, b, ...
    )
)
@assert X == Y
```
Another way of understanding the generic objects in each category is as a reference implementation of the required interface that also serves as a fallback for when further specialized functions are left undefined.

!!! note "Example"
    In `./src/MetricSpace/MetricSpace.jl` is described what function need to be overloaded, and the behavior of those function, to be regarded as a metric space.
    ```julia
    nPoints(metricSpace)::Int
    distance(metricSpace, i::Int, j::Int)::RT
    ```
    The generic object for the category of metric spaces is `GenericMetricSpace` defined in `./src/MetricSpace/GenericMetricSpace.jl`, which is regarded as an object in the category of metric spaces. For any other object `x` in this category, `Base.convert` should be overloaded
    ```julia
    Base.convert(::Type{GenericMetricSpace}, x)
    ```

In addition to the functions which are required to be overloaded, to every category is associated *standardized functions* which can be defined for arbitrary objects in that category using only the required overloaded functions — the naturality condition above is what makes these well-defined regardless of when conversion to the generic object happens.

The reason for singling out the generic object in each category is that they can serve as a fallback when specialized implementations are not defined.
