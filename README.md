# openscad_primitives
Primitives library for openSCAD. This code is shared under "The Unlicence" licence, meaning you are welcome to use, modify, sell, incorporate into product or whatever strikes your fancy. There is, however, no warranty.

Modules in this library are things I found useful and could not find elsewhere in quite the right form. Each module has a comment at the top and test calls at the bottom, so employ "use" instead of "include".

Calls are generally flexible, with a simple call if you want to accept the defaults, but with options to configure the behavior in some detail. See comments in each file for usage.

Library contents are as follows:

- fillet_cube: An operator that fillets one or more edges of a cube. Edges can be configured all together, in groups (bottom edges, top edges and vertical edges), or singly. Each edge can have a different fillet radius. There is no requirement that the first child in the scope is actually a cube, so this module can be used to fillet edges on other shapes.

- support_box: Makes a set of plates to support an overhang. All plates go across the shorter dimension but, if the plates are high enough, cross plates are added to stiffen the structure. Plates are perforated at the top by default for easier removal. If the object to be supported does not have a flat bottoma and perforations are desired, use the operator perf_support_surface in this file, instead of support_box.
