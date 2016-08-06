// Part of the openscad_primtives library.

// Makes a set of plates for support. Plates will be perforated by default
// at the top for easier removal and a 0.2 gap will be left at the top by
// default.

// There are two external modules. "support_box" makes support plates and
// perforates, if desired, at the top, assuming  that the attached object
// is flat. "perf_support_surface" is an operator that will take the first
// object in scope and perforate the layer below it. It will make three
// copies of the object, so it's computationally much more intensive.

// support_box makes a box at 0,0,0
// The box is drawn so that the support plates are across shorter dimension,
// but see the orient parameter below.
// Defaults can changed by adding parameters to the call.

// Call syntax:
// support_box( xdim, ydim, zdim,
//              plate_w=0.3, plate_gap=3, 
//              cross_h=10, cross_gap=15  )
//		perf_height=2.5, perf_block=1.5, perf_gap=2,
//		orient=0 )
// where
// xdim - box width
// ydim - box depth
// zdim - box height
// plate_w - thickness of each plate
// plate_gap - distance between plates
// cross_h - if the is higher than this, put in cross plates for bracing
// cross_gap - if cross plates are printed, they are this far apart
// perf_height - height of the perforater layer
// perf_block - length of the each perforation printed block
// perf_gap - gap between two perforation attachments
// orient - 0: default - go crosswise, unless the box is too narrow
//          1: go lengthwise
// Cross plates are built 3mm shorter than main plates to make detaching
// easier. 

// perf_support_surface( position, xdim, ydim, zdim,
//              plate_w=0.3, plate_gap=3, 
//              cross_h=10, cross_gap=15  )
//		perf_height=2.5, perf_block=1.5, perf_gap=2,
//		orient=0 ) {}

// where position is location of the support box, since the object may not be
// at the origin. Other parameters are as above.
// 
// The object in the scope is not built, so it does not have
// to be the same as the object actually to be supported. It can be anything,
// as long as the bottom surface is correct. Make sure the surface is thick
// enough to cover the tops of the plates plus perf_height. Otherwise, the
// plates will be sticking through.

// By Nenad Rijavec.
// Feel free to use and modify as you see fit.

// Module to draw the plates, once the direction has been established.

module draw_support_box( dim, trans_vec, cube_vec,
			plate_w, plate_gap )
{
    	n_iter = ceil( (dim-plate_w)/(plate_w+plate_gap) ) ;
    	plate_diff = (dim-plate_w)/n_iter - plate_w ;
	for (i = [0:n_iter] ) {
		translate(i * ( plate_w + plate_diff )*trans_vec)
		cube( cube_vec ) ;
	}
}


module draw_perforated_box( dim, trans_vec, cube_vec,
			plate_w, plate_gap, 
			perf_height, perf_block, perf_gap )
{
	// modify perforations so we start and end on a block
	plate_len = trans_vec[0]==1 ? cube_vec[1] : cube_vec[0] ;
	n_perf = ceil((plate_len-perf_block)/(perf_block+perf_gap)) ;
	scale_fac = ((n_perf+1)*perf_block+n_perf*perf_gap)/plate_len ;
	block_l = perf_block / scale_fac ;
	gap_l = perf_gap / scale_fac ;
	perf_vec = [
		1 - trans_vec[0],
		trans_vec[0],
		0
	] ;
	block_vec = [
		trans_vec[0]==1 ? plate_w : block_l,
		trans_vec[0]==1 ? block_l : plate_w,
		perf_height
	] ;
	// figure out the plates
    	n_iter = ceil( (dim-plate_w)/(plate_w+plate_gap) ) ;
    	plate_diff = (dim-plate_w)/n_iter - plate_w ;
	for (i = [0:n_iter] ) {
		translate(i * ( plate_w + plate_diff )*trans_vec)
		cube( block_vec ) ;
		for ( j = [ 1:n_perf] ) {
			translate(i * ( plate_w + plate_diff )*trans_vec)
			translate( j*(block_l+gap_l)*perf_vec ) 
			cube( block_vec ) ;
		}
	}
}

module support_box( xdim, ydim, zdim_raw,
		plate_w=0.3, plate_gap=3,
		cross_h=10, cross_gap=15,
		perf_height=2.5, perf_block=1, perf_gap=3, 
		orient = 0 )
{
	zdim = perf_height > 0 ? zdim_raw - perf_height :
			zdim_raw ;
	cross_headroom = 3 ;
   	if ( ( ydim < xdim && orient==0 && ydim > 3 ) ||
		( xdim < ydim && (orient==1 || xdim < 3 ) )) {
		draw_support_box( xdim, [1, 0, 0], [plate_w, ydim, zdim],
				plate_w, plate_gap ) ;
		if ( zdim_raw > cross_h )
			translate( [0,ydim>cross_gap? cross_gap/2:ydim/2,0]) 
			draw_support_box(
				ydim>cross_gap?ydim-cross_gap:plate_w+0.01,
		 		[0, 1, 0],
				[xdim, plate_w, zdim-cross_headroom],
				plate_w, cross_gap ) ;
		if ( perf_height > 0 ) {
			translate( [ 0, 0, zdim ] )
			draw_perforated_box( xdim, [1, 0, 0],
				[plate_w, ydim, perf_height],
				plate_w, plate_gap,
				perf_height, perf_block, perf_gap ) ;
		}
    	} else {
		draw_support_box( ydim, [0, 1, 0], [xdim, plate_w, zdim],
				plate_w, plate_gap ) ;
		if ( zdim_raw > cross_h )
			translate( [xdim>cross_gap?cross_gap/2:xdim/2,0,0]) 
			draw_support_box(
				xdim>cross_gap?xdim-cross_gap:plate_w+0.01,
				[1, 0, 0],
				[plate_w, ydim, zdim-cross_headroom],
				plate_w, cross_gap ) ;
		if ( perf_height > 0 ) {
			translate( [ 0, 0, zdim ] )
			draw_perforated_box( ydim,[0, 1, 0],
				[xdim, plate_w, perf_height],
				plate_w, plate_gap,
				perf_height, perf_block, perf_gap ) ;

		}
	}
}

module perf_support_surface( position, xdim, ydim, zdim,
		plate_w=0.3, plate_gap=3,
		cross_h=10, cross_gap=15,
		perf_height=2.5, perf_block=1.5, perf_gap=2,
		orient = 0 )
{
	child_pos = [ 0, 0, -perf_height ] - position ;
	// solid and perforated overlap a smidge to preserve watertightness
	overlap = [ 0, 0, 0.05 ] ;
	translate( position ) {
		// take the perf_height band next to the child from perforated
		difference() {
			intersection() {
				translate( child_pos ) children(0) ;
   				if ( ( ydim < xdim && orient==0 && ydim > 3 ) ||
					( xdim < ydim && (orient==1 || xdim < 3 ) )) 
					draw_perforated_box( xdim, [1, 0, 0],
						[plate_w, ydim, zdim],
						plate_w, plate_gap,
						zdim, perf_block, perf_gap ) ;
				else
					draw_perforated_box( ydim,[0, 1, 0],
						[xdim, plate_w, zdim],
						plate_w, plate_gap,
						zdim, perf_block, perf_gap ) ;
			}
			translate( -position+overlap ) children(0) ;
		}
		// knock out the perforated part out of solid plates
		difference() {
			support_box( xdim, ydim, zdim, plate_w, plate_gap,
				cross_h, cross_gap, 0, 0, 0, orient ) ;
			translate( child_pos ) children(0) ;
		}
	}
}

// test calls

// support_box examples

color("red")
support_box( 5, 15, 15, 0.3, 3, 10, 15, 0 ) ; // no perforations
color("cyan")
translate( [ -10, 0, 0 ] ) support_box( 5, 15, 15 ) ; // default perforations
color( "green" )
translate( [ 10, 0, 0 ] ) support_box( 25, 23, 15, 0.3, 1.2, 8, 10 ) ;

// orientation
// default
color( "blue" )
translate( [0, 30, 0 ] ) support_box( 25, 5, 10, 0.2, 1.8, 10,15,
				2.5, 1.5, 2, 0 ) ; // default orient of 0
// lengthwise
color( "magenta" )
translate( [0, 40, 0 ] ) support_box( 25, 5, 10, 0.2, 1.8, 10,15,
				2.5, 1.5, 2, 1 ) ; // lengthwise orient of 1
// narrow automatically switches to lengthwise
color( "brown" )
translate( [0, 50, 0 ] ) support_box( 25, 2, 10 ) ;

// perf_support_surface examples supporting hollow cylinders

translate( [ -25, 0, 0 ] )
union() {
	intersection() {
		translate( [ -0.5, -0.5, 4.5 ] ) cube( [ 11, 11, 5.5] ) ;
		translate( [ 0, 5, 10 ] ) difference() {
			rotate([0,90,0]) cylinder(r=5, h=10, $fn=100);
			translate([-0.5,0,0])rotate([0,90,0])
				cylinder(r=4, h=11, $fn=100);
		}
}
perf_support_surface( [0,0.1,0], 10, 9.8, 10, 
		0.3, 3, 10, 15, 
		2.5, 1.5, 2.5, 0 )
translate( [ -0.5, 5, 10 ] ) rotate([0,90,0])
		cylinder(r=5, h=11, $fn=100);

}

translate( [ -25, 15, 0 ] )
union() {
	intersection() {
		translate( [ -0.5, -0.5, 4.5 ] ) cube( [ 11, 11, 5.5] ) ;
		translate( [ 0, 5, 10 ] ) difference() {
			rotate([0,90,0]) cylinder(r=5, h=10, $fn=100);
			translate([-0.5,0,0])rotate([0,90,0])
				cylinder(r=4, h=11, $fn=100);
		}
	}
	perf_support_surface( [0,0.1,0], 9.6, 9.8, 10, 
				0.3, 3, 10, 15, 
				2.5, 1.5, 2.5 )
	translate( [ -0.5, 5, 10 ] ) rotate([0,90,0])
			cylinder(r=5, h=11, $fn=100);
}

// lengthwise
translate( [ -25, 30, 0 ] )
union() {
	intersection() {
		translate( [ -0.5, -0.5, 4.5 ] ) cube( [ 20, 15, 5.5] ) ;
		translate( [ 0, 5, 10 ] ) difference() {
			rotate([0,90,0]) cylinder(r=5, h=16, $fn=100);
			translate([-0.5,0,0])rotate([0,90,0])
				cylinder(r=4, h=20, $fn=100);
		}
	}
	perf_support_surface( [0,0.1,0], 15.6, 9.8, 10, 
				0.3, 3, 10, 15, 
				2.5, 1.5, 2.5, 1 )
	translate( [ -0.5, 5, 10 ] ) rotate([0,90,0])
			cylinder(r=5, h=20, $fn=100);
}

// nenad me fecit
