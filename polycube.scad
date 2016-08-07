// Part of the openscad_primtives library.

// Uses polyhedron to make a 6 face, 8 vertex solid. The solid is like a
// cube, except that each vertex can be moved to a different position, as
// long as 4 points describing each face remain on the same plane.
// 
// Call syntax:
// polycube( P )
// where P is a 2x2x2 array, where first dimension is along X, second along
// Y and third along Z. Element "0" in each dimension is the smaller on its
// edge, while "1" is larger on the edge.

// The only thing polycube really does is automate face construction, so
// there is no need to figure out clockwise vertex order for each face.

// The following array makes an unit cube and shows indices.

// P = [
// [
// [ [ 0, 0, 0 ], [ 0, 0, 1 ] ],
// [ [ 0, 1, 0 ], [ 0, 1, 1 ] ]
// ],
// [
// [ [ 1, 0, 0 ], [ 1, 0, 1 ] ],
// [ [ 1, 1, 0 ], [ 1, 1, 1 ] ]
// ] ] ;
 
// By Nenad Rijavec
 
// Feel free to use, modify and share as you see fit.


module polycube( P )
{
	vertices = [
		P[0][0][0],	// 0 - left near bottom
		P[0][1][0],	// 1 - left far bottom
		P[0][0][1],	// 2 - left near top
		P[0][1][1],	// 3 - left far top
		P[1][0][0],	// 4 - right near bottom
		P[1][1][0],	// 5 - right far bottom
		P[1][0][1],	// 6 - right near top
		P[1][1][1]	// 7 - right far top
	] ;
	poly_faces = [
		[ 1, 3, 2, 0 ], // left face
		[ 4, 6, 7, 5 ], // right face
		[ 4, 5, 1, 0 ],	// bottom face
		[ 2, 3, 7, 6 ],	// top face
		[ 0, 2, 6, 4 ], // near face
		[ 5, 7, 3, 1 ]	// far face
	] ;
	polyhedron( vertices, poly_faces ) ;
}

// examples

// unit cube to show indices
P = [
[
[ [ 0, 0, 0 ], [ 0, 0, 1 ] ],
[ [ 0, 1, 0 ], [ 0, 1, 1 ] ]
],
[
[ [ 1, 0, 0 ], [ 1, 0, 1 ] ],
[ [ 1, 1, 0 ], [ 1, 1, 1 ] ]
] ] ;

polycube( P ) ;

// shrunk left and top sides
Q = [
[
[ [ 1, 1, 1 ], [ 1, 1, 2 ] ],
[ [ 1, 2, 1 ], [ 1, 2, 2 ] ]
],
[
[ [ 3, 0, 0 ], [ 2, 0.5, 3 ] ],
[ [ 3, 3, 0 ], [ 2, 2.5, 3 ] ]
] ] ;
color( "red" ) 
translate( [ 2, 0, 0 ] ) polycube( Q ) ;
