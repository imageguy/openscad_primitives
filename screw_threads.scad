/*
   A simple metric screw library. It builds metric screws in the sense that
   the thread geometry follows the metric standard. See
   http://www.apollointernational.in/iso-metric-thread-chart.php for a
   helpful diagram.

   openScad will generally not show the thread properly in preview. It will,
   however, show it fine after rendering, so you might prefix your constructs
   with the render() operator, or select Render (F6) in the user interface.
   
   The library contains four modules:

   screw_segment - builds a screw segment and contains all the thread logic.

   nut_core - builds a inward-facing thread encased in a thin outer wall.
   Thread is built by diffing an appropriate screw segment from a cylinder.

   hex_bolt - builds a hex bolt with the part of the body optionaly not
   being threaded.

   hex_nut - builds a hex nut.

   To use the library, put this file in your search path (or in the folder
   where you are working) and put
   use <screw_threads.scad>
   statement in your code.

   If you run openScad on this file, it will build an example bolt and nut.

   Each module takes three positional parameters and a number of optional
   named parameters. The positional parameters are the same as are used to
   specify metric screw sizes: diameter, pitch and length, all in mm. Named
   parameters refine and modify the screw shape as follows:
	
	Common parameters:

	fn = 50 : polyhedron segments per turn
	radial_slop = +/-0.1 : nominal outer radius change (changes backlash)
			       negative for screw, positive for nut
	trunc = -1 : how much to trim the outer peak. -1 : h/4
	fill = -1 :  how much to fill the inner valley. -1 : h/8
	chamfer_top = true : // chamfer the screw or nut on the top
	chamfer_bottom = false : // chamfer the screw or nut on the bottom

	screw_segment only:

	lead_top = true :  lead thread (recessing into interior) on the top
	lead_bottom = false : lead thread on the bottom

	hex_bolt only:

	thread_length = -1 : thread length in mm, -1 is equal to bolt length

	hex_bolt and hex_nut:

	hex_width = -1 : hex wrench size in mm, -1 for auto
	hex_thickness = -1 :  head (or nut) thickness in mm, -1 for auto

   We assume the screw is built vertically, so "bottom" and "top" refer to
   the two screw ends.

   Assuming the defaults are set properly, you should be able to just
   specify the screw dimensions and be able to fit the resulting screw and
   nut together. The example at the bottom of this file builds a M10-1.5x25
   bolt and a corresponding nut.

   Crucial parameters are radial_slop, trunc and fill and will depend on
   your print quality. The defaults here are the standard metric screw
   defaults and are almost certainly too tight for 3D printed objects. You
   might try radial_slop of +/- 0.5mm and set trunc and fill to same value
   in a similar range.

   Algorithm note: The thread spiral is built as a single polyhedron,
   defined as a sequence of vertical trapezes. Each trapeze base is trimmed
   slightly, so that the points on adjacent spirals don't coincide.

   By Nenad Rijavec

   I put no restrictions on this code. You are welcome to use, share and
   modify it as you see fit.
*/
module screw_segment( 
	diam,   // outer nominal diameter
	pitch,  // mm per turn
	length, // in mm
	fn = 50,  // polyhedron segments per turn
	radial_slop = -0.1, // nominal outer radius change (changes backlash)
			    // negative for screw, positive for nut
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	lead_top = true, // lead thread (recessing into interior) on the top
	lead_bottom = false, //lead thread on the bottom
	chamfer_top = true, // chamfer the screw on the top
	chamfer_bottom = false // chamfer the screw on the bottom
	)
{
	//notation: "p" is in axial (pitch) direction, "h" is in radial (height)
	//direction
	angle = 60 ; // metric thread is equilateral triangle
	// trapeze is trimmed on the inside, so polyhedron points on
	// adjacent threads don't coincide. 
	p_space = 0.01 ;
	h_space = tan(angle) * p_space ;
	h = cos(angle/2)*pitch ;
	wtrunc = trunc==-1 ? h/4 : trunc ;
	wfill = fill==-1 ? h/8 : fill ;
	r = diam/2 - h + radial_slop ;
	r_outer = r + h - wtrunc ;
	trap_p = pitch*wtrunc/(2*h) ;
	h_net = h - wtrunc ;
	degstep = 360/fn ;
	step_up = pitch/fn ;
	n = (length-pitch)*fn/pitch ;
	// lead thread possibly on the first and last 120 degrees
	endseg = floor(120/degstep) ;
	// effective radius is a function, so we can recess the thread
	// spiral on the lead thread segments
	function r_eff(r,i) = i < endseg && lead_bottom ?
		r-h_net+h_net*(i+1)/endseg :
		(i<=n-endseg || !lead_top ? r : r-h_net+h_net*(n-i+1)/endseg) ; 
	// order of points in each slice doesn't really matter - the points
	// are ordered as necessary in face definitions
	function oneslice(i) = [ 
		// trapeze base, upper point
		[r_eff(r,i)*cos(i*degstep)+h_space, 
		r_eff(r,i)*sin(i*degstep)+h_space, 
		i*step_up+p_space ],
		// trapeze base, lower point
		[r_eff(r,i)*cos(i*degstep)+h_space,
		r_eff(r,i)*sin(i*degstep)+h_space, 
		i*step_up+pitch-p_space ],
		// trapeze other parallel, upper point
		[(r_eff(r_outer,i))*cos(i*degstep), 
			(r_eff(r_outer,i))*sin(i*degstep),
			i*step_up+trap_p+pitch/2],
		// trapeze other parallel, lower point
		[(r_eff(r_outer,i))*cos(i*degstep),
			(r_eff(r_outer,i))*sin(i*degstep),
			i*step_up-trap_p+pitch/2]
	] ;
	vertices = [ for ( i = [0:n] ) each(oneslice(i)) ] ;
	n_vert = len(vertices) ;
	faces = [ 
		// first and last vertical faces
		[ 0, 1, 2,3 ], [n_vert-1,n_vert-2, n_vert-3, n_vert-4],
		// all other faces
		// order of points in two "oneslice" sets is reflected in
		// indexing here, so each polyhedron face has points ordered
		// clockwise.
		each([ for (j=[0:n-1]) each(
			[[ 4*j+4, 4*j+5, 4*j+1, 4*j+0],  
			[  4*j+5, 4*j+6, 4*j+2, 4*j+1],  
			[  4*j+6, 4*j+7, 4*j+3, 4*j+2],
			[  4*j+7, 4*j+4, 4*j+0, 4*j+3] ] 
		)])
	] ;
	// chamfering takes into account that the thread may be recessed
	// (lead thread)
	function r_c( i ) = sqrt( // oneslice outer radius for chamfering
		vertices[i][0]*vertices[i][0] +
		vertices[i][1]*vertices[i][1] ) ;
	if ( chamfer_top || chamfer_bottom ) difference() {
		union() {
			polyhedron( vertices, faces ) ;
			cylinder( length, r=r+(wfill>0.1?wfill:0.1), $fn=fn ) ;
		}
		union() {
			if ( chamfer_top ) {
				hh = length - vertices[n_vert-2][2] ;
				translate( [0, 0, vertices[n_vert-2][2] ] ) 
				difference() {
					cylinder( hh+1, r=r_outer+1, $fn=fn ) ;
					cylinder( hh, r1=r_c(n_vert-1)+wfill, 
						r2 = r_c(n_vert-3), $fn = fn) ;
				}
			}
			if ( chamfer_bottom ) {
				difference() {
					cylinder( vertices[3][2],
						r = r_outer+1, $fn=fn ) ;
					cylinder( vertices[3][2], r1 = r_c(0),
						r2 = r_c(3)+wfill, $fn = fn ) ;
				}
			}
		}

	} else { // no chamfer
		polyhedron( vertices, faces ) ;
		cylinder( length, r=r+(wfill>0.1?wfill:0.1), $fn = fn ) ;
	}
}

// nut_core provides a nut thread encased in a thin cylinder wall
// use this to make nuts
// nut opening may be chamfered, but there is no lead thread
module nut_core( 
	diam,   // outer nominal diameter
	pitch,  // mm per turn
	length, // in mm
	fn = 50,  // polyhedron segments per turn
	radial_slop = 0.1, // nominal outer radius change (changes backlash)
			    // negative for screw, positive for nut
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	chamfer_top = true, // chamfer the nut on the top
	chamfer_bottom = false // chamfer the nut on the bottom
	)
{
	// no leads or chamfer on the screw used for diff
	angle = 60 ;
	h = cos(angle/2)*pitch ;
	difference() {
		cylinder( length, d = diam+1+2*radial_slop, $fn = fn ) ;
		union() {
			// thread
			translate( [0, 0, -pitch ] )
			screw_segment( diam, pitch, length+2*pitch,
				radial_slop = radial_slop, 
				// fill and trunc are interchanged,
				// so have to handle defaults here
				fill = (trunc==-1 ? h/4 : trunc),
				trunc = (trunc==-1 ? h/4 : trunc),
				lead_top=false, lead_bottom=false,
				chamfer_top = false, chamfer_bottom = false ) ;
			if ( chamfer_top ) 
				translate( [ 0, 0, length-pitch/2 ] )
				cylinder( 0.1+pitch/2, d1 = diam-2*h,
					d2 = diam, $fn = fn ) ;
			if ( chamfer_bottom ) 
				translate( [ 0, 0, -0.1 ] )
				cylinder( 0.1+pitch/2, d1 = diam,
					d2 = diam-2*h, $fn = fn ) ;
		}
	}
}

// utility functions
// "hw" is the nominal wrench size in mm
function hw(hex_width,diam) = (hex_width!=-1 ? hex_width :
		(hex_width < 6 ? diam+2.5 :
		(hex_width < 8 ? diam+4 :
		(hex_width < 10 ? diam+5 : diam+7 ) ) ) ) ;

module hex_bolt( 
	diam,   // outer nominal diameter
	pitch,  // mm per turn
	length, // total body length in mm
	fn = 50,  // polyhedron segments per turn
	radial_slop = -0.1, // nominal outer radius change (changes backlash)
			    // negative for screw, positive for nut
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	thread_length = -1, // thread length in mm, -1 is equal to length
	hex_width = -1, // hex wrench size in mm, -1 for auto
	hex_thickness = -1 // head thickness in mm, -1 for auto
	)
{
	// build the hex head on the bottom
	// "hw" is the nominal wrench size in mm
	// hdiam is the circle, slightly undersized
	hdiam = hw( hex_width,diam ) / cos(30) - 0.5 ;
	// thickness is oversized compared to standard metal dimensions,
	// since plastic is softer
	ht = hex_thickness!=-1 ? hex_thickness : 6 ;
	// head is chamfered slightly
	difference() {
		cylinder( ht, d=hdiam, $fn = 6 ) ;
		union() {
			// top head chamfer
			translate( [ 0, 0, ht-1.99 ] )
			difference() {
				cylinder( 2.5, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, -0.01 ] )
				cylinder( 2.02, d1 = hdiam+0.1,
						d2 = 0.8*hdiam,
						$fn = fn ) ;
			}
			// bottom head chamfer
			translate( [ 0, 0, -0.01 ] )
			difference() {
				cylinder( 2.1, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, 0.01 ] )
				cylinder( 2.02, d1 = 0.8*hdiam,
						d2 = hdiam+0.1,
						$fn = fn ) ;
			}
		}
	}
	// barrel with no thread, if any
	// barrel is chamfered on top
	blen = thread_length == -1 ? 0 : length - thread_length ;
	if ( blen > 0 ) {
		translate( [ 0, 0, ht-0.01] )
		difference() {
			cylinder( blen+0.01, d=diam, $fn = fn ) ;
			translate( [ 0, 0, blen-0.99 ] )
			difference() {
				cylinder( 1.5, d = diam+1, $fn = fn ) ;
				translate( [ 0, 0, -0.01 ] )
				cylinder( 1.02, d1 = diam+0.1,
						d2 = 0.90*diam,
						$fn = fn ) ;
			}
		}
	}
	// screw part, chamfered on top
	translate( [ 0, 0, ht+blen-pitch/2-0.01 ] )
	screw_segment( diam, pitch, (length-blen+pitch/2+0.01), fn = fn,
	radial_slop = radial_slop,
	trunc = trunc,
	fill = fill,
	lead_top = true,
	lead_bottom = false,
	chamfer_top = true,
	chamfer_bottom = false ) ;
}

module hex_nut( 
	diam,   // outer nominal diameter
	pitch,  // mm per turn
	length, // total body length in mm
	fn = 50,  // polyhedron segments per turn
	radial_slop = +0.1, // nominal outer radius change (changes backlash)
			    // negative for screw, positive for nut
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	hex_width = -1, // hex wrench size in mm, -1 for auto
	hex_thickness = -1 // head thickness in mm, -1 for auto
	)
{
	// "hw" is the nominal wrench size in mm
	// hdiam is the circle, slightly undersized
	hdiam = hw( hex_width, diam+2*radial_slop ) / cos(30) - 0.5 ;
	// thickness is oversized compared to standard metal dimensions,
	// since plastic is softer
	ht = hex_thickness!=-1 ? hex_thickness : 6 ;
	// nut is chamfered slightly
	difference() {
		cylinder( ht, d=hdiam, $fn = 6 ) ;
		union() {
			// hole
			translate( [ 0, 0, -1 ] )
			cylinder( ht+2, d= diam+0.1, $fn=fn ) ;
			// top head chamfer
			translate( [ 0, 0, ht-1.99 ] )
			difference() {
				cylinder( 2.5, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, -0.01 ] )
				cylinder( 2.02, d1 = hdiam+0.1,
						d2 = 0.8*hdiam,
						$fn = fn ) ;
			}
			// bottom head chamfer
			translate( [ 0, 0, -0.01 ] )
			difference() {
				cylinder( 2.1, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, 0.01 ] )
				cylinder( 2.02, d1 = 0.8*hdiam,
						d2 = hdiam+0.1,
						$fn = fn ) ;
			}
		}
	}
	nut_core( diam, pitch, length,  fn = fn,
	radial_slop = radial_slop,
	trunc = trunc,
	fill = fill,
	chamfer_top = true, chamfer_bottom = true ) ;
}

render() hex_bolt( 10, 1.5, 25, thread_length = 15,
	radial_slop = -0.4, trunc = 0.3, fill = 0.3 ) ;
translate( [ 18, 0, 0 ] )
render() hex_nut( 10, 1.5, 6, radial_slop = 0.4, trunc = 0.3, fill = 0.3 ) ;

