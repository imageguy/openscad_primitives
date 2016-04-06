// support box
// box is set at 0,0,0
// The box is drawn so that the support plates are across shorter dimension.
// Plate thickness defaults to 0.3mm and plate spacing to 1.2mm.
// Defaults can changed by adding parameters to the call.

// Call syntax:
// support_box( xdim, ydim, zdim,
//              plate_w, plate_gap, 
//              cross_h, cross_gap  )
// where
// xdim - box width
// ydim - box depth
// zdim - box height
// plate_w - thickness of each plate, default is 0.3
// plate_gap - distance between plates, default is 1.2
// cross_h - if the box is higher than this, then put in cross plates for
//      bracing.  Defaults to 10.
// cross_gap - if cross plates are printed, they are this far apart.
// 	Defaults to 15.
//
// Cross plates are build 2mm shorter than main plates to make detaching
// easier.

// By Nenad Rijavec.
// Feel free to use and modify as you see fit.

// Module to draw the plates, once the direction has been established.

module draw_support_box( dim, trans_vec, cube_vec,
			plate_w, plate_gap ) {
    	n_iter = ceil( (dim-plate_w)/(plate_w+plate_gap) ) ;
    	plate_diff = (dim-plate_w)/n_iter - plate_w ;
	for (i = [0:n_iter] ) {
		translate(i * ( plate_w + plate_diff )*trans_vec)
		cube( cube_vec ) ;
	}
}

// main module.

module support_box( xdim, ydim, zdim,
		plate_w=0.3, plate_gap=1.2,
		cross_h=10, cross_gap=15 ) {
   	if ( ydim < xdim ) {
		draw_support_box( xdim, [1, 0, 0], [plate_w, ydim, zdim],
				plate_w, plate_gap ) ;
		if ( zdim > cross_h )
			translate( [0,ydim>cross_gap? cross_gap/2:ydim/2,0]) 
			draw_support_box(
				ydim>cross_gap?ydim-cross_gap:plate_w+0.01,
		 		[0, 1, 0], [xdim, plate_w, zdim-2],
				plate_w, cross_gap ) ;
    	} else {
		draw_support_box( ydim, [0, 1, 0], [xdim, plate_w, zdim],
				plate_w, plate_gap ) ;
		if ( zdim > cross_h )
			translate( [xdim>cross_gap?cross_gap/2:xdim/2,0,0]) 
			draw_support_box(
				xdim>cross_gap?xdim-cross_gap:plate_w+0.01,
				[1, 0, 0],
				[plate_w, ydim, zdim-2],
				plate_w, cross_gap ) ;
	}
}

// test calls

support_box( 5, 15, 10 ) ;
color( "green" )
translate( [ 10, 0, 0 ] ) support_box( 25, 23, 15, 0.3, 1.2, 8, 10 ) ;
color( "blue" )
translate( [0, 30, 0 ] ) support_box( 25, 5, 10, 0.2, 1.8, 10,15 ) ;


// nenad me fecit
