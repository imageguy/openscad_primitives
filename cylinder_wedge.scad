// Part of the openscad_primitives library

// Operator cylinder_wedge operator reduces an object to a wedge of a given
// radius, angle and height. The outer edge can optionally be smoothed.

// Call syntax:
// cylinder_wedge( r, h, start_angle, angle, smooth_fn=0 ) { }
// where
//     r - radius of the wedge
//     h - height of the wedge
//     start_angle - angle where the wedge starts
//     angle - angle covered by the edge
//     smooth_fn - defaults to zero. If not zero, the value is treated as
//     $fn passed to a cylinder that is intersected to smooth the outher
//     boundary.

// Wedge is constructed by making an union of whole cubes to cover
// multiples of 90 degrees, with the remainder being an intersection of two
// rotated cubes. This construct is intersected with the first child object
// in the operator's scope.

// Algorithm gives a rectangular outer perimeter, which does not matter if
// the object being trimmed is a cylinder or smaller than the given radius.
// If the smooth_fn is nonzero, the child object is first intesected with a
// cylinder of the wedge radius and height, with smooth_fn passed as the $fn
// to the cylinder call.
// 
// See examples on the bottom.

// By Nenad Rijavec.
// Feel free to use and modify as you see fit.

// operates on the first child
module cylinder_wedge( r, h, start_angle, angle, smooth_fn=0 )
{
	r_wrk = r+1 ;
	a = floor( angle/90 ) ;
	offset = 90 * a ;
	rem = angle - offset ;
	intersection() {
		union() {
			if ( a > 0 ) for ( i=[0:a-1] ) {
				rotate( [ 0, 0, start_angle+90 * i ] )
					cube( [ r_wrk, r_wrk, h ] ) ;
			}
			intersection() {
				rotate( [ 0, 0, start_angle+offset-90+rem] )
					cube( [ r_wrk, r_wrk, h ] ) ;
				rotate( [ 0, 0, start_angle+offset] )
					cube( [ r_wrk, r_wrk, h ] ) ;
			}
		}
		if ( smooth_fn == 0 )
			children( 0 ) ;
		else intersection() {
			cylinder( h, r=r, $fn=smooth_fn ) ;
			children( 0 ) ;
		}
	}
}

// examples: all have r=10, h=20, start_angle=10, angle=210

// trim a cube, so the effect of outer smoothness shows
// no outer smoothing, cube being trimmed bigger than r
cylinder_wedge( 10, 20, 10, 210 )
	cube( [ 30, 30, 20 ], center=true ) ;
// outer smoothing, cube being trimmed bigger than r
translate( [ -30, 0, 0 ] )
	cylinder_wedge( 10, 20, 10, 210, 100 )
		cube( [ 30, 30, 20 ], center=true ) ;
// cube being trimmed smaller than r: outer smoothing has no effect
translate( [ -30, 30, 0 ] )
	cylinder_wedge( 10, 20, 10, 210, 100 )
		cube( [ 12, 12, 20 ], center=true ) ;

// cylinder wedge - no need to smooth
translate( [ 0, 30, 0 ] )
	cylinder_wedge( 10, 20, 10, 210 )
		cylinder( 20, r=10, $fn=100 ) ;

// ring wedge
translate( [ 30, 30, 0 ] )
	cylinder_wedge( 10, 20, 10, 210 )
	difference() {
		cylinder( 20, r=10, $fn=100 ) ;
		translate( [ 0, 0, -0.5 ] )
		cylinder( 21, r=5, $fn=100 ) ;
	}

// nenad me fecit
