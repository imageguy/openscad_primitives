// Part of the openscad_primtives library.

// Makes a clasp that can be used to close a smallish box. It has three
// modules:
// 
// clasp_receiver -  makes the attach plate that the clasp hooks onto
// and is usually put on the bottom part of the box.

// clasp_top - housing for the clasp axle, usually placed on the box top

// clasp - the actual clasp.

// The clasp is built along the X axis with the center at the origin. The
// clasp is oriented assuming the box is open on the top.
// Translate the object to the appropriate position on your object.
// If the optional supp_h parameter is specified, the support plates will be
// built.

// Call syntax:
// clasp_receiver( clasp_w, belt_height, clasp_depth=9, supp_h = 0 )
// clasp_top( clasp_w, belt_height, clasp_depth=9, supp_h = 0 )
// clasp

// where
// clasp_w - width of the clasp space, guard plates are extra
// belt_height - the height of the vertical wall each part of the clasp
// attaches to, needed if the clasp is mounted on a belt that protrudes from
// the box.
// clasp_depth - how much the clasp guartd plates extend into the box below
// the belt. Need to be increased if the belt protrudes so much or the box
// wall slopes so much that the side guard plates are not fully attached to
// the wall
// supp_h - if specified and > 0, assume that the top of the clasp is this
// high above the XY plane and build the support structures.

// By Nenad Rijavec
// Feel free to use, share or modify as you see fit.

use <plib/support_box.scad>
use <plib/cylinder_wedge.scad>

module left_guard( clasp_w, belt_height, clasp_depth, clasp_h )
{
	intersection() {
		translate([-clasp_w/2-3, 33, 0])
			rotate( [ 0, 90, 0 ] ) cylinder( 3, r=40, $fn=360) ;
		union() {
			translate([-clasp_w/2-3, -7, -belt_height-2])
			cube( [ 3, 7, belt_height+2 ] ) ;
			translate([-clasp_w/2-3, -7, -clasp_h - 2])
			cube( [ 3, clasp_depth, clasp_h-belt_height ] ) ;
		}
	}
}

module right_guard( clasp_w, belt_height, clasp_depth, clasp_h )
{
	intersection() {
		translate([clasp_w/2, 33, 0])
			rotate( [ 0, 90, 0 ] ) cylinder( 3, r=40, $fn=360) ;
		union() {
			translate([clasp_w/2, -7, -belt_height-2])
			cube( [ 3, 7, belt_height+2 ] ) ;
			translate([clasp_w/2, -7, -clasp_h - 2])
			cube( [ 3, clasp_depth, clasp_h-belt_height ] ) ;
		}
	}
}

module clasp_top( clasp_w, belt_height, clasp_depth=9, supp_h = 0 )
{
	clasp_h = 12 ;
	
	difference() { // has hole for the axle
		union() {
	
			// guards
			left_guard(clasp_w, belt_height, clasp_depth, clasp_h);
			right_guard(clasp_w, belt_height, clasp_depth, clasp_h);
		}
		translate([-clasp_w/2-5, -3.0, -clasp_h+1])
		rotate( [ 0, 90, 0 ] ) cylinder( clasp_w+20, d=2.5, $fn=360) ;
	}
	// support, if desired
	if ( supp_h > 0 ) {
		translate([-clasp_w/2-3.5, -4, -supp_h ] )
			support_box( 3.9, 4, supp_h-clasp_h-2,
				0.3, 3, 10, 15, 0, 0, 0, 0 ) ;
		translate([clasp_w/2-0.5, -4, -supp_h ] )
			support_box( 3.9, 4, supp_h-clasp_h-2,
				0.3, 3, 10, 15, 0, 0, 0, 0 ) ;
		translate([-clasp_w/2-5, -5, -supp_h ] )
			cube( [ clasp_w+10, 6, 0.3 ] ) ;
	}
}
module clasp_receiver( clasp_w, belt_height, clasp_depth=9, supp_h = 0 )
{
	clasp_h = 12 ;
	
	// clasp receiver plate
	// notch behind so the clasp has something to grab
	translate( [-clasp_w/2, -4, -clasp_h] )
	difference() {
		cube( [ clasp_w, 3.5, clasp_h ] ) ;
		translate( [ 0, 1, 0 ] )
		rotate( [ -65, 0, 0 ] )
			cube( [ clasp_w, 4, 4 ] ) ;
	}
	
	// guards
	left_guard( clasp_w, belt_height, clasp_depth, clasp_h ) ;
	right_guard( clasp_w, belt_height, clasp_depth, clasp_h ) ;

	// support, if desired
	if ( supp_h > 0 ) {
		translate([-clasp_w/2+1, -4, -supp_h ] )
			support_box( clasp_w-2, 4, supp_h-clasp_h,
				0.3, 8, 10, 15, 0, 0, 0, 0 ) ;
		translate([-clasp_w/2-3, -4, -supp_h ] )
			support_box( 4, 4, supp_h-clasp_h-2,
				0.3, 3, 10, 15, 0, 0, 0, 0 ) ;
		translate([clasp_w/2-1, -4, -supp_h ] )
			support_box( 4, 4, supp_h-clasp_h-2,
				0.3, 3, 10, 15, 0, 0, 0, 0 ) ;
		translate([-clasp_w/2-5, -5, -supp_h ] )
			cube( [ clasp_w+10, 6, 0.3 ] ) ;
	}

}

module clasp( clasp_w_raw ) 
{
	clasp_w = clasp_w_raw - 3 ; // to allow space between clasp and guards
	// axle for attachment
	difference() {
		cylinder( clasp_w, r=2.5, $fn=360 ) ;
		translate( [ 0, 0, -1 ] )
			cylinder( clasp_w+2, d=2.5, $fn=360 ) ;
	}

	// main arm
	translate( [ 0, -78, 0 ] )
	cylinder_wedge( 80, clasp_w, 90.9, 16.3 )
	difference() {
		translate( [ 0, 0, -1 ] )
		cylinder( clasp_w+2, r=80, $fn=360 ) ;
		translate( [ 0, 0, -2 ] )
		cylinder( clasp_w+4, r=78.5, $fn=360 ) ;
	}

	// catch
	translate( [ -43, -8, 0 ] ) 
	cylinder_wedge( 20, clasp_w, 4, 40 ) {
		difference() {
			cylinder( clasp_w+2, r=20, $fn=360 ) ;
			translate( [ 0, 0, -1 ] )
			cylinder( clasp_w+4, r=18.5, $fn=360 ) ;
		}
	}

	translate( [ -22.8, -6.0, 0 ] ) 
		cylinder( clasp_w, r=0.6, $fn=360 ) ;
}

clasp_w = 28 ;

// mounted receiver with support
// box and lip
clasp_w = 28 ;
translate( [ 2, 2, 0 ] ) difference() {
	cube( [ 56, 26, 31 ] ) ;
	translate( [ 4, 4, 4 ] )
	cube( [ 48, 18, 31 ] ) ;
}
translate( [ 0, 0, 30 ] ) difference() {
	cube( [ 60, 30, 5 ] ) ;
	translate( [ 6, 6, -1 ] )
	cube( [ 48, 18, 7 ] ) ;
}
translate( [ 30, 0, 35 ] )
clasp_receiver( clasp_w, 5, 9, 35 );

// mounted tip with support
// box and lip
translate( [ -80, 2, 0 ] ) difference() {
	cube( [ 56, 26, 31 ] ) ;
	translate( [ 4, 4, 4 ] )
	cube( [ 48, 18, 31 ] ) ;
}
translate( [ -82, 0, 30 ] ) difference() {
	cube( [ 60, 30, 5 ] ) ;
	translate( [ 6, 6, -1 ] )
	cube( [ 48, 18, 7 ] ) ;
}

translate( [ -50, 0, 35 ] )
clasp_top( clasp_w, 5, 9, 35 );

// clasp
translate( [ 0, -30, 0 ] ) clasp( clasp_w -1 ) ;

// nenad me fecit
