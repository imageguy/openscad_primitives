// nut holes for various nut sizes, centered at 0,0,0
// to use, translate and difference from the base solid.

// By Nenad Rijavec

// Feel free to use, modify and share as you see fit.


// draw a nut hex with the given dimensions. Use directly, or via precooked
// modules for each size.

module draw_nut_hex( r, thickness ) {
	linear_extrude( thickness )
	circle( r, $fn=6  ) ;
}

// modules for various nut sizes
//thickness defaults to the usual nut thickness, but can be changed as
//needed.
module nut_m3( thickness=2.8 ) { draw_nut_hex( 3.5, thickness ) ; }
module nut_m4( thickness=3.5 )  { draw_nut_hex( 4.5, thickness ) ; }
module nut_m5( thickness=4.0 ) { draw_nut_hex( 5.4, thickness ) ; }

//test calls 
translate( [10, 5, 0] ) nut_m3() ;
translate( [10, 15, 0] ) nut_m4() ;
translate( [10, 30, 0] ) nut_m5() ;
