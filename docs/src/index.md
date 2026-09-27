## Design Guide

The following is not meant to be mathematically rigorous or without
contradictions. It is only a guide for making design decisions. The details
of this guide are constantly changing and in development as this package
distills itself in my mind.

1. Structure comes from morphisms from canonical forms.
    * By canonical form, we refer to a unique representative from an isomorphism
        class in each category with a well understood structure and easy-to-compute-with 
        presentation.
    * It is not that object do/do not belong to a category in an objective sense.
        Rather, *any* object can belong to *any* category. That is not to say
        it is useful to wrap an object in a particular category if there is not 
        an obvious morphism from well-understood representative object
        in that category. This motivates the pervasive use of `canonicalForm()`
        which maps a generic object to a pair consisting of a canonical
        form -- a unique representative object from each isomorphism
        class -- and a morphism from that representative to the generic object. Thus,
        when we say an object belongs in a category, we mean that there is an obvious
        map to some canonical form in that category. If there is not an obvious morphism,
        then a warning may be thrown, but not an error.
    * Canonical forms themselves are what provide a tangible interface for a category. For
        example, every object in the category finite of groups has a well-defined order.
        Lets say I have an object `ℤ₂₄` in the category of groups which represents the unique
        cyclic group of order 24. I would like the function `order(ℤ₂₄)` to be overloaded and return 
        $24$. Lets say I have a new object `X` and an isomorphism $ℤ₂₄ → X$ returned by `canonicalForm()`.
        Then while `order(X)` need not be overloaded, we can still extract the order of `X` by instead
        calling `order(ℤ₂₄)`. 
        
        In practice, this is useful for allowing many different implementations
        of the same object to be comparable in a standardized way. For example, if I want to store 
        a matrix as a data-type `SparseMatrixCSC` or simply as `Matrix`, and they both have an isomorphism
        from the same canonical form, then I can consider them the same matrix (within context of the category they
        are regarded as belonging to)
    * This is inspired by the Yoneda embedding: The structure of a "reasonable category" comes from morphisms between
        objects in that category, not the object themselves.

3. Traits are forgetful functors from sub-categories
    * Lets say we have an object-in-category `ObjectInCategory(ℤ₂, Grp)`
        and we want assert that ℤ₂ is abelian. This should be implemented
        by wrapping `ℤ₂` as `ObjectInCategory(ℤ₂, AbGrp)`, and providing a forgetful
        functor `AbGrp`. This allows avoiding
        more than a single mechanisms for tracking behaviors of an object. This
        can also be seen as an extension of point 1.

4. Morphisms are object in the Hom-category
    * Lets say we have two objects-in-category `ObjectInCategory(A, SomeCat)`
        and `ObjectInCategory(B, SomeCat)`. In representing morphisms between
        these two objects, we do not provide a wrapper like `MorphismInCategory(Morph, A, B, SomeCat)` 
        because a morphism between two objects should be considered an object
        in the category `ObjectInCategory(Morph, Hom(SomeCat, A, B))`

5. Throw descriptive errors before implementing default behavior

6. Avoid hidden sideeffects; Use non-trivial macros sparingly.

## ToDo

* How should we deal with traits such that we naturally get sub-categories in 
    a Julian way? A `TraitSubcategory()` object?

* How should inheritance between categories be tracked? A graph of 
    forgetful functors?

* Allow for @dispatch to be called without declaring `... = Dispatch()`
    first. This is so that we can dispatch functions based on value
    more similarly to how julia dispatches based on type.

* Can we make `Dispatch()` have no runtime overhead when the predicate
    is trivially true?