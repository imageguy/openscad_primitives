# openscad_primitives
Primitives library for openSCAD. This code is shared under "The Unlicence" licence, meaning you are welcome to use, modify, sell, incorporate into product or whatever strikes your fancy. There is, however, no warranty.

Modules in this library are things I found useful and could not find elsewhere in quite the right form. Each module has a comment at the top and test calls at the bottom, so employ "use" instead of "include".

Calls are generally flexible, with a simple call if you want to accept the defaults, but with options to configure the behavior in some detail. See comments in each file for usage.

Library contents are as follows:

- fillet_cube: An operator that fillets one or more edges of a cube. Edges can be configured all together, in groups (bottom edges, top edges and vertical edges), or singly. Each edge can have a different fillet radius. There is no requirement that the first child in the scope is actually a cube, so this module can be used to fillet edges on other shapes.

- support_box: Makes a set of plates to support an overhang. All plates go across the shorter dimension but, if the plates are high enough, cross plates are added to stiffen the structure. Plates are perforated at the top by default for easier removal. If the object to be supported does not have a flat bottom and perforations are desired, use the operator perf_support_surface in this file, instead of support_box.
- hinge: Makes a hinge with specified number of elements. Also includes utility function to construct support plates if necessary. Default hinge values (5 outer radius, 2 inner radius) are suitable for a medium box and sturdy when printed in ABS with decent print quality.
- clasp: A clasp that can be used to close a smallish box. Bottom part should be built on the box body, top part on the box lid. Clasp itself is built separately and attached via 12 gauge wire axle.
- cylinder_wedge: An operator that trims a given object to a wedge.
- nut_holes: sundry hexagons that can be used to punch out holes for various nut sizes. Currently only has M3, M4 and M5.
- polycube: automates building polyhedron from vertices, assuming the solid is "cube-like": 6 faces, 8 vertices, each face has 4 vertices. Vertices are specified in a 2x2x2 array in a hopefully intuitive fashion.
