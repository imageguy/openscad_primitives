// Part of the openscad_primitives library. Assumes OpenSCAD search path
// points to the library modules at plib/*.

// Makes parametrized hinges. Each hinge is a cylinder with a hole in it,
// joined with two blocks to provide attachment. X axis serves as the hinge
// axis and attachment blocks extend in the negative Y and Z directions.
// See examples below.

// Module for building custom support for the hinge, as well as dimension
// convenience functions are also provided, see below.

// Call syntax:

// hinge( len, gap, n_hinges,
//		r_outer=5, r_inner=2,
//		offset=1, max_height=0,
//		fn=100 )
// where:
// len - length of each hinge element
// gap - gap between two hinge elements. Depending on print quality, this
//     should probably be more than length of each element.
// n_hinges - how many hinge elements to make
// r_outer - outer hinge cylinder radius
// r_inner - hinge hole cylinder radius
// offset - how far the attach block extends from the hinge cylinder in Y
//     direction (helps with clearance when the hinge is operating)
//  max_height - trim the bottom of the attachemnts block to be no more than
//  so much below the hinge axis. 0 means no trimming.
// fn - $fn to use when making cylinders.

// If custom supports are desired, support_hinge will build the supports
// under the flat surface of each hinge element.

// call syntax: 
// support_hinge( height, len, gap, n_hinges,
//		r_outer=5, offset=1, max_height=0,
//		plate_w=0.3, plate_gap=3,
//		cross_h=10, cross_gap=15,
//		perf_height=2.5, perf_block=1, perf_gap=3 )
// where height is the height of the hinge axis, len, gap, n_hinges, r_outer,
// offset and max_height are as above and the remaining parameters configure
// the support plates - see plib/support_box.scad for details.

// By Nenad Rijavec.
// Feel free to use and modify as you see fit.

use <plib/support_box.scad>

// convenience function to return the height from the bottom of the
// attachment block to the hinge axis, including trimming.
function hinge_height( r_outer, max_height ) = 
	max_height > 0 && max_height < r_outer*sqrt(2) ?
		max_height : r_outer*sqrt(2) ;

// convenience function to return the length of the hinge.
function hinge_length( len, gap, n_hinges ) = n_hinges*len+(n_hinges-1)*gap ;

// worker to make each element 
module hinge_element( len,
		r_outer=5, r_inner=2,
		offset=1, v_offset=1, max_height=0,
		fn=100 )
{
	sqr= r_outer * sqrt( 2 );
	block_height = hinge_height( r_outer, max_height ) ;
	difference() {
		union() {
			// hinge cylinder
			rotate( [ 0, 90, 0 ] )
			cylinder( r=r_outer, h=len, $fn=fn ) ;
			difference() {
				union() {
					// attach block
					translate([0, -r_outer-offset, -sqr])
					cube([	len,
						r_outer+offset,
						sqr-v_offset ] ) ;
					// support block
					//translate([0,r_outer+offset,-sqr])
					translate( [ 0, 0, -sqr ] )
						rotate( [ 45, 0, 0 ] )
						cube([ len,r_outer,r_outer]);
				}
				if ( block_height < sqr )
					translate( [ -0.1,
						-r_outer-offset-0.1,
						-sqr-0.1 ] )
					cube( [ len+0.2,
						2*r_outer+offset+0.2,
						sqr-block_height+0.1 ] ) ;
			}
		}
		translate( [ -0.1, 0, 0 ] ) rotate([ 0, 90, 0 ])
				cylinder( r=r_inner, h=len+0.2, $fn=fn ) ;
	}
}

module hinge( len, gap, n_hinges,
		r_outer=5, r_inner=2,
		offset=1, max_height=0,
		fn=100 )
{
	block_v_offset = 1 ;
	for ( i = [ 1 : n_hinges ] )
		translate( [ (i-1)*(len+gap), 0, 0 ] )
		hinge_element( len, r_outer, r_inner, offset,
			block_v_offset, max_height, fn ) ;
}

module support_hinge( height, len, gap, n_hinges,
		r_outer=5, offset=1, max_height=0,
		plate_w=0.3, plate_gap=3,
		cross_h=10, cross_gap=15,
		perf_height=2.5, perf_block=1, perf_gap=3 )
{
	block_height = hinge_height( r_outer, max_height ) ;
	nominal_height = hinge_height( r_outer,0 ) ;
	supp_y = r_outer+offset ; //+ nominal_height - block_height ;
	// on QuBD, we used to support slope, but no longer need to do so
	//supp_y = r_outer+offset + nominal_height - block_height ;
	supp_z = height - block_height ;
	for ( i= [1:n_hinges] )
		translate( [ (i-1)*(len+gap), -r_outer-offset, 0 ] ) 
			support_box( len, supp_y, supp_z,
				plate_w, plate_gap,
				cross_h, cross_gap,
				perf_height, perf_block, perf_gap) ;

}


// EXAMPLES

// single hinge with all defaults
translate( [ 0, 20, 0 ] ) color( "red" ) hinge( 10, 0, 1 ) ;

// single hinge with support block trimmed to the height of 5
translate( [ 20, 20, 0 ] ) color( "blue" ) hinge( 10, 0, 1, 5, 2, 1, 5 ) ;

// hinge with two sides in open position, one side with 5 hinges, the
// other with four. Block is trimmed on the bottom to 5.
// Supports are added, 5-hinge with all support parameters modified.

// 5-hinge 
translate( [ 0, 0, 10 ] ) hinge( 9, 11, 5, 5, 2, 1, 5 ) ;
support_hinge( 10, 9, 11, 5, 5, 1, 5, 0.3, 3, 10, 15, 1, 1.5, 4 ) ;
// 4-hinge
translate( [ 10+hinge_length(9,11,4), 0, 10 ] ) rotate( [ 0, 0, 180 ] )
	hinge( 9, 11, 4, 5, 2, 1, 5 ) ;
translate( [ 10+hinge_length(9,11,4), 0, 0 ] ) rotate( [ 0, 0, 180 ] )
	support_hinge( 10, 9, 11, 4, 5, 1, 5 ) ;


// nenad me fecit
