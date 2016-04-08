// Part of the openscad_primitives library

// An operator that takes a cube and fillets the required edges with a given
// radius. Edges to fillet can be selected in groups or singly.
// Edges are grouped into bottom plane, top plane and vertical edges. Edges
// in each plane are ordered clockwise, with the top and bottom first edge in
// X dimension and the vertical edge at origin. Run this module to get four
// cubes, each with one low, high and vertical edge filleted, in clockwise
// order (cyan examples).

// Call syntax: 
// fillet_cube( dims, r, do, fn ) { }
// where
// dims is 3 vector giving dimensions of the cube
// r is the fillet radius
// do is the edge selector.
// fn is fillet resolution, passed down via $fn as cylinter/sphere are called
// in the code. Default is 360.
// Note that a scope follows the call. Fillets are applied to the first child
// in the scope.

// Note that the module fillets edges of a hypothetical cube, but there is
// no actual requrement that a cube be present in the scope. To actually
// fillet a cube, make sure it is in the scope with the same dimensions.

// Both r and do can be global, per group (top,bottom,vertical), or per
// edge. Global value is a number, per group values are length 3 vectors,
// while individual values are 3x4 matrices. If "do" is omitted, all edges
// are filleted.

// Examples using cube [20,30,40] and fillet radius 4:
// fillet_cube( [20,30,40], 4 ) fillets all edges
// fillet_cube( [20,30,40], 4, 0 ) fillets no edges
// fillet_cube( [20,30,40], 4, 0,0,0 ) fillets no edges
// fillet_cube( [20,30,40], 4, 0,0,1 ) fillets vertical edges only
// fillet_cube( [20,30,40], 4, [[1,0,0,0], [1,0,0,0], [1,0,0,0]] ) fillets
//   the X axis edge on the top and bottom plane and the origin verical edge
// Example where each edge group has its own radius:
// fillet_cube( [20,30,40], [ 2, 4, 6 ] ) 
// low edges have radius 2, edges have radius 4, vertical edges radius 6
// Example where each group has its own radius:
// fillet_cube( [40,60,80], [[2,4,6,8], [10,12,14,16], [18,20,22,24]] )

// There is no syntax checking. Any selector value not 1 is treated as 0.

// By Nenad Rijavec.
// Feel free to use and modify as you see fit.

// single fillet
module fillet_worker( dim, r, fn )
{
	difference() {
		translate([-0.1,-0.1,-0.1])
		cube( [ dim + 0.2, r + 0.2, r + 0.2 ] ) ;
		translate( [ 0, r, r ] ) rotate([0,90,0])
			cylinder( h=dim, r=r, $fn=fn ) ;
	}
}

// handle a single corner. Assumes corner is at origin, cube is in the first
// quadrant. Corner is smoothed if all three fillets have the same radius.
module corner_worker( rx, ry, rz, dox, doy, doz, fn )
{
	if ( rx == ry && rx == rz && dox==1 && doy==1 && doz==1 ) {
		difference() {
			cube( [ rx, rx, rx ] ) ;
			translate( [ rx, rx, rx ] )
			sphere( rx, $fn=fn ) ;
		}
	}
}

// worker to assemble fillets, needs to be diff'ed with the cube
module assemble_fillets_worker( dims, r, do, fn )
{
	union() {
		if ( do[0][0] == 1 )
			translate( [0,0,0])
			rotate([ 0, 0, 0])
			fillet_worker( dims[0], r[0][0], fn ) ;
		if ( do[0][1] == 1 )
			translate( [0,dims[1],0])
			rotate([ 0, 0, -90])
				fillet_worker( dims[1], r[0][1], fn ) ;
		if ( do[0][2] == 1 )
			translate( [dims[0],dims[1],0])
			rotate([ 0, 0, -180])
				fillet_worker( dims[0], r[0][2], fn ) ;
		if ( do[0][3] == 1 ) 
			translate([dims[0], 0, 0])
			rotate([ 0, 0, 90])
				fillet_worker( dims[1], r[0][3], fn ) ;
		if ( do[1][0] == 1 )
			translate( [0,0,dims[2]])
			rotate([ -90, 0, 0])
			fillet_worker( dims[0], r[1][0], fn ) ;
		if ( do[1][1] == 1 )
			translate( [0,dims[1],dims[2]])
			rotate([ -90, 0, -90])
				fillet_worker( dims[1], r[1][1], fn ) ;
		if ( do[1][2] == 1 )
			translate( [dims[0],dims[1],dims[2]])
			rotate([ -90, 0, -180])
				fillet_worker( dims[0], r[1][2], fn ) ;
		if ( do[1][3] == 1 ) 
			translate([dims[0], 0, dims[2]])
			rotate([ -90, 0, 90])
				fillet_worker( dims[1], r[1][3], fn ) ;
		if ( do[2][0] == 1 ) difference() {
			rotate([ 0, -90, -90])
				fillet_worker( dims[2], r[2][0], fn ) ;
		}
		if ( do[2][1] == 1 ) difference() {
			translate([0,dims[1],0])
			rotate([ 0, -90, 180])
				fillet_worker( dims[2], r[2][1], fn ) ;
		}
		if ( do[2][2] == 1 ) difference() {
			translate([dims[0],dims[1],0])
			rotate([ 0, -90,  90])
				fillet_worker( dims[2], r[2][2], fn ) ;
		}
		if ( do[2][3] == 1 ) difference() {
			translate([dims[0],0,0])
			rotate([ 0, -90,  0])
				fillet_worker( dims[2], r[2][3], fn ) ;
		}
		corner_worker( r[0][0], r[0][1], r[2][0],
			      do[0][0],do[0][1],do[2][0], fn ) ;
		translate( [ 0, dims[1], 0 ] )
		rotate( [ 0, 0, -90 ] )
		corner_worker( r[0][1], r[0][2], r[2][1],
			      do[0][1],do[0][2],do[2][1], fn ) ;
		translate( [ dims[0], dims[1], 0 ] )
		rotate( [ 0, 0, 180 ] )
		corner_worker( r[0][2], r[0][3], r[2][2],
			      do[0][2],do[0][3],do[2][2], fn ) ;
		translate( [ dims[0], 0, 0 ] )
		rotate( [ 0, 0, 90 ] )
		corner_worker( r[0][3], r[0][0], r[2][3],
			      do[0][3],do[0][0],do[2][3], fn ) ;
		translate( [0, 0, dims[2] ] )
		rotate( [ 90, 90, 90 ] )
		corner_worker( r[1][0], r[1][1], r[2][0],
			      do[1][0],do[1][1],do[2][0], fn ) ;
		translate( [ 0, dims[1], dims[2] ] )
		rotate( [ 90, 90, 0 ] )
		corner_worker( r[1][1], r[1][2], r[2][1],
			      do[1][1],do[1][2],do[2][1], fn ) ;
		translate( [ dims[0], dims[1], dims[2] ] )
		rotate( [ 90, 90, 270 ] )
		corner_worker( r[1][2], r[1][3], r[2][2],
			      do[1][2],do[1][3],do[2][2], fn ) ;
		translate( [ dims[0], 0, dims[2] ] )
		rotate( [ 90, 90, 180 ] )
		corner_worker( r[1][3], r[1][0], r[2][3],
			      do[1][3],do[1][0],do[2][3], fn ) ;
	}
}

// worker
module fillet_cube_worker( dims, r, do, fn ) 
{
	difference() {
		children( 0 ) ;
		assemble_fillets_worker( dims, r, do, fn ) ;
	}
}

function parse_3( val ) = len(concat(val))==1 ?
		concat( val,val,val) : val ;

function parse_4( val ) = len(concat(val))==1 ?
		concat( val,val,val,val) : val ;

module parse_phase_1( dims, r, do, fn )
{
	fillet_cube_worker( dims,
		[ parse_4(r[0]), parse_4(r[1]), parse_4(r[2]) ],
		[ parse_4(do[0]), parse_4(do[1]), parse_4(do[2]) ], fn )
		children(0) ;

}
module fillet_cube( dims, r, do=1, fn=360 )
{
	parse_phase_1( dims, parse_3(r), parse_3(do), fn )children(0) ;
}

// most general call, only the corner at origin is smoothed, low res
color( "red" ) fillet_cube( [ 20, 30, 40 ], [[4,4,6,8], [2,4,6,8],[4,5,6,8]], 1, 20 ) 
	cube( [20,30,40] ) ;
// all radii are the same, all corners are smoothed, higher resolution
color( "green" )
translate( [ 30, 0, 0 ] )
fillet_cube( [ 20, 30, 40 ], 4, 1, 50 ) 
	cube( [20,30,40] ) ;
// only edges at xyz axes are filleted, fine resolution default used
color( "blue" )
translate( [ 60, 0, 0 ] )
fillet_cube( [ 20, 30, 40 ], 4, [[1,1,0,0],[0,0,0,0], [1,0,0,0]] ) 
	cube( [20,30,40] ) ;
// fillet applied to an arbitrary scope
// note how the fillet applies at origin, after any coordinate
// transformation in the scope.
color( "magenta" )
translate( [ 10, -20, 0 ] )
fillet_cube( [ 40, 40, 20 ], 4, [[0,0,0,0],[1,1,0,0], [1,0,0,0]], 10 ) {
translate( [ 0, 0, 10 ] )
cylinder( r=10, h=10 ) ;
}
// edge selection samples
color( "cyan" ) {
	translate( [ 0, 70, 0 ] )
	fillet_cube( [ 20, 30, 40 ], 4, [[1,0,0,0],[1,0,0,0], [1,0,0,0]] ) 
		cube( [20,30,40] ) ;
	translate( [ 30, 70, 0 ] )
	fillet_cube( [ 20, 30, 40 ], 4, [[0,1,0,0],[0,1,0,0], [0,1,0,0]] ) 
		cube( [20,30,40] ) ;
	translate( [ 60, 70, 0 ] )
	fillet_cube( [ 20, 30, 40 ], 4, [[0,0,1,0],[0,0,1,0], [0,0,1,0]] ) 
		cube( [20,30,40] ) ;
	translate( [ 90, 70, 0 ] )
	fillet_cube( [ 20, 30, 40 ], 4, [[0,0,0,1],[0,0,0,1], [0,0,0,1]] ) 
		cube( [20,30,40] ) ;
}



//nenad me fecit
