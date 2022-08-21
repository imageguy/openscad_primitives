/*
   A simple metric screw library. It builds metric screws in the sense that
   the thread geometry follows the metric standard. See
   https://www.machiningdoctor.com/charts/metric-thread-charts/#c-mc
   for an excellent explanation of the metric thread geometry and
   http://www.apollointernational.in/iso-metric-thread-chart.php for
   the ISO thread size tolerance tables.

   Varying the angle parameter will produce threads outside of metric
   standard.

   openScad will generally not show the thread properly in preview. It will,
   however, show it fine after rendering, so you might prefix your constructs
   with the render() operator, or select Render (F6) in the user interface.
   
   The library contains five modules:

   screw_segment - builds a screw segment and contains all the thread logic.

   nut_core - builds a inward-facing thread encased in a thin outer wall.
   Thread is built by diffing an appropriate screw segment from a cylinder.

   hex_bolt - builds a hex bolt with the part of the body optionaly not
   being threaded.

   hex_nut - builds a hex nut.

   wing_nut - builds a wing nut.

   To use the library, put this file in your search path (or in the folder
   where you are working) and put
   use <screw_threads.scad>
   statement in your code.

   If you run openScad on this file, it will build an example bolt and nut.

   Each module takes two or three positional parameters and a number of optional
   named parameters. The positional parameters are the same as are used to
   specify metric screw sizes: diameter, pitch and length, all in mm. the
   length parameter is passed to screw and bolt modules only, nuts infer the
   length from the hex_thickness parameter. We use named hex_thickness to
   make it clear that it can be left out, in which case the thickness (and
   the corresponding thread length) is computed automatically.
   
   Named parameters refine and modify the screw shape as follows:
	
	Common parameters:

	fn = 50 : polyhedron segments per turn
	diam_adj = +/-0.1 : nominal outer diameter change (changes backlash)
			       negative for screw, positive for nut
	trunc = -1 : how much to trim the outer peak. -1 : h/4
	fill = -1 :  how much to fill the inner valley. -1 : h/8
	angle = 60 : thread cross-section triangle outer thread angle.
				Metric threads have equilateral triangle
				cross section before any trimming, so this
				is 60 degrees. Smaller angles yield deeper
				thread, larger angles yield shallower
				thread.
	chamfer_top = true : // chamfer the screw or nut on the top
	chamfer_bottom = false : // chamfer the screw or nut on the bottom

	screw_segment only:

	lead_top = true :  lead thread (recessing into interior) on the top
	lead_bottom = false : lead thread on the bottom

	hex_bolt only:

	thread_length = -1 : thread length in mm, -1 is equal to bolt length

	hex_bolt, hex_nut and wing_nut:

	hex_width = -1 : hex wrench size in mm, -1 for auto
	hex_thickness = -1 :  head (or nut) thickness in mm, -1 for auto

   We assume the screw is built vertically, so "bottom" and "top" refer to
   the two screw ends.

   We follow the ISO logic, where the outer screw diameter is to the outer
   face, namely after the trim has been subtracted. You should be able to
   leave trim and fill as defaults and only change diag_adj as needed. In
   general, screws should be shrunk a little and bolts expanded a little, to
   account for the fact thath the 3D prints are not as sharp as machined
   metal.

   Run by itself, the code can produce bolt and nut combination for each of
   the sizes M3, M4, M5, M6, M8 and M10. On my printer, using PLA, diam_adj
   varies from -0.7 to -0.3 for bolts and stays at 0.3. for nuts. You may
   have to change this depending on your screw size, print material and
   print quality.

   Set the true/false flags at the start of the code to select what to
   render. By default, all sizes except M3 are built. M3 requires very good
   print quality for the screw (nut is OK, but then even a blank cylinder of
   proper size works as a M3 nut), and the screw is too spindly to be of
   much use.

   Algorithm note: The thread spiral is built as a single polyhedron,
   defined as a sequence of vertical trapezes. Each trapeze base is trimmed
   slightly, so that the points on adjacent spirals don't coincide.

   By Nenad Rijavec

   I put no restrictions on this code. You are welcome to use, share and
   modify it as you see fit.
*/

debug_echo = false ; // set to "true" to echo sizes in screw_segment

// selects what to display as a test, see show_all module on the bottom
do_m3 = false ;
do_m4 = true ;
do_m5 = true ;
do_m6 = true ;
do_m8 = true ;
do_m10 = true ;
showlist = [ do_m3, do_m4, do_m5, do_m6, do_m8, do_m10 ] ;
n_show = len(showlist) ;

// basic thread module, called by everything else
module screw_segment( 
	diam,   // outer nominal diameter
	pitch,  // mm per turn
	length, // in mm
	fn = 50,  // polyhedron segments per turn
	diam_adj = -0.1, // nominal diameter change (changes backlash)
			    // negative for screw, positive for nut
	angle = 60,  // outer thread cross-section angle, 60 is metric standard
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	lead_top = true, // lead thread (recessing into interior) on the top
	lead_bottom = false, //lead thread on the bottom
	chamfer_top = true, // chamfer the screw on the top
	chamfer_bottom = false // chamfer the screw on the bottom
	)
{
	//notation: "p" is in axial (pitch) direction, 
	// "h" is in radial (height) direction
	// trapeze is trimmed on the inside, so polyhedron points on
	// adjacent threads don't coincide. 
	p_space = 0.001 ;
	h_space = p_space * tan((180-angle)/2) ;
	h = cos(angle/2)*pitch ;
	wtrunc = trunc==-1 ? h/8 : trunc ;
	wfill = fill==-1 ? h/4 : fill ;
	hs = h - wtrunc - wfill ;
	r = (diam + diam_adj)/2 - hs ;
	r_outer = r + hs ;
	if ( debug_echo ) {
		echo( "diam", diam ) ;
		echo( "diam_adj", diam_adj ) ;
		echo( "r", r ) ;
		echo( "r_outer", r_outer ) ;
		echo( "h", h ) ;
		echo( "wtrunc", wtrunc ) ;
		echo( "wfill", wfill ) ;
		echo( "a", angle, "tan", tan((180-angle)/2) ) ;
		echo( "p_space", p_space ) ;
		echo( "h_space", h_space ) ;
	}
	trap_p = pitch*wtrunc/(2*h) ;
	h_net = hs ;
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
		[(r_eff(r,i)+h_space)*cos(i*degstep), 
		(r_eff(r,i)+h_space)*sin(i*degstep), 
		i*step_up+p_space ],

		// trapeze base, lower point
		[(r_eff(r,i)+h_space)*cos(i*degstep),
		(r_eff(r,i)+h_space)*sin(i*degstep), 
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
			cylinder( length, r=r+(wfill>0.001?wfill:0.001), $fn=fn ) ;
		}
		union() {
			if ( chamfer_top ) {
				hh = length - vertices[n_vert-2][2] ;
				//hh = pitch/4 ;
				translate( [0, 0, vertices[n_vert-2][2] ] ) 
				difference() {
					cylinder( hh+1, r=r_outer+1, $fn=fn ) ;
					cylinder( pitch/4, r1=r_c(n_vert-1)+wfill, 
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
	diam_adj = 0.1, // nominal diameter change (changes backlash)
			    // negative for screw, positive for nut
	angle = 60,  // outer thread cross-section angle, 60 is metric standard
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	chamfer_top = true, // chamfer the nut on the top
	chamfer_bottom = false // chamfer the nut on the bottom
	)
{
	// no leads or chamfer on the screw used for diff
	h = cos(angle/2)*pitch ;
	difference() {
		cylinder( length, d = diam+1+diam_adj, $fn = fn ) ;
		union() {
			// thread
			translate( [0, 0, -pitch ] )
			screw_segment( diam, pitch, length+2*pitch,
				diam_adj = diam_adj, 
				angle = angle,
				// fill and trunc are interchanged,
				// so have to handle defaults here
				fill = (trunc==-1 ? h/8 : trunc),
				trunc = (fill==-1 ? h/4 : fill),
				lead_top=false, lead_bottom=false,
				chamfer_top = false, chamfer_bottom = false ) ;
			if ( chamfer_top ) 
				translate( [ 0, 0, length-pitch/2 ] )
				cylinder( 0.1+pitch/2, d1 =
				diam+diam_adj-2*h,
					d2 = diam+diam_adj, $fn = fn ) ;
			if ( chamfer_bottom ) 
				translate( [ 0, 0, -0.1 ] )
				cylinder( 0.1+pitch/2, d1 =
				diam+diam_adj,
					d2 = diam+diam_adj-2*h, $fn = fn ) ;
		}
	}
}

// following modules can be called to build bolts and nuts

// utility functions
// "hw" is the nominal wrench size in mm
function hw(hex_width,diam) = (hex_width!=-1 ? hex_width :
		(diam < 6 ? diam+2.5 :
		(diam < 8 ? diam+4 :
		(diam < 10 ? diam+5 : diam+7 ) ) ) ) ;

module hex_bolt( 
	diam,   // outer nominal diameter
	pitch,  // mm per turn
	length, // total body length in mm
	fn = 50,  // polyhedron segments per turn
	diam_adj = -0.1, // nominal outer diameter change (changes backlash)
			    // negative for screw, positive for nut
	angle = 60,  // outer thread cross-section angle, 60 is metric standard
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
	ht = hex_thickness!=-1 ? hex_thickness : 
		(diam < 6 ? 4 : 3 * diam / 4) ;
	// head is chamfered slightly
	difference() {
		cylinder( ht, d=hdiam, $fn = 6 ) ;
		union() {
			f = 0.55 ;
			// top head chamfer
			translate( [ 0, 0, 0.70*ht ] )
			difference() {
				cylinder( f*ht, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, -0.01 ] )
				cylinder( f*ht+0.02, d1 = hdiam+0.1,
						d2 = 0.8*hdiam,
						$fn = fn ) ;
			}
			// bottom head chamfer
			translate( [ 0, 0, (0.3-f)*ht ] )
			difference() {
				cylinder( f*ht, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, 0.001 ] )
				cylinder( f*ht+0.012, d1 = 0.8*hdiam,
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
	diam_adj = diam_adj,
	angle = angle,
	trunc = trunc,
	fill = fill,
	lead_top = true,
	lead_bottom = false,
	chamfer_top = true,
	chamfer_bottom = false ) ;
}

module hex_nut( 
	diam,   // inner nominal diameter
	pitch,  // mm per turn
	//length, // total body length in mm
	fn = 50,  // polyhedron segments per turn
	diam_adj = +0.1, // nominal outer diameter change (changes backlash)
			    // negative for screw, positive for nut
	angle = 60,  // outer thread cross-section angle, 60 is metric standard
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	hex_width = -1, // hex wrench size in mm, -1 for auto
	hex_thickness = -1 // head thickness in mm, -1 for auto
	)
{
	// "hw" is the nominal wrench size in mm
	// hdiam is the circle, slightly undersized
	hdiam = hw( hex_width, diam ) / cos(30) - 0.5 ;
	// thickness is oversized compared to standard metal dimensions,
	// since plastic is softer
	ht = hex_thickness!=-1 ? hex_thickness : 
		(diam < 6 ? 4 : 3 * diam / 4) ;
	// nut is chamfered slightly
	difference() {
		cylinder( ht, d=hdiam, $fn = 6 ) ;
		union() {
			translate( [ 0, 0, -1 ] )
				cylinder(  ht+2, d=diam+1, $fn=50) ;
			f = 0.55 ;
			// top head chamfer
			translate( [ 0, 0, 0.70*ht ] )
			difference() {
				cylinder( f*ht, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, -0.01 ] )
				cylinder( f*ht+0.02, d1 = hdiam+0.1,
						d2 = 0.8*hdiam,
						$fn = fn ) ;
			}
			// bottom head chamfer
			translate( [ 0, 0, (0.3-f)*ht ] )
			difference() {
				cylinder( f*ht, d = hdiam+1, $fn = fn ) ;
				translate( [ 0, 0, 0.001 ] )
				cylinder( f*ht+0.012, d1 = 0.8*hdiam,
						d2 = hdiam+0.1,
						$fn = fn ) ;
			}
		}
	}
	nut_core( diam, pitch, ht,  fn = fn, diam_adj = diam_adj,
		angle = angle, trunc = trunc, fill = fill,
		chamfer_top = true, chamfer_bottom = true ) ;
}

// builds a wing nut wing. Mirrored to get the other wing
module wing( wdiam, ht, hdiam )
{
	wing_t = wdiam < 8 ? 4 : wdiam / 2 ;
	wing_l = wdiam < 8 ? 12 : 1.5 * wdiam ;
	wing_angle = 45 ;
	difference() {
		hull() union() {
			translate( [ hdiam/2, 0, wing_t/2 ] )
				sphere( d=wing_t, $fn=10 ) ;
			translate( [ cos(wing_angle)*wing_l+hdiam/2, 0,
					sin(wing_angle)*wing_l ] )
				sphere( d=wing_t, $fn=10 ) ;
			translate( [ hdiam/2-1, 0, ht-wing_t/2+1 ] )
				sphere( d=wing_t, $fn=10 ) ;
			translate( [ cos(wing_angle)*wing_l+hdiam/2-4, 0,
					sin(wing_angle)*wing_l+2 ] )
				sphere( d=wing_t, $fn=10 ) ;
		}
		// on smaller nuts, wing can protrude into the thread
		// this takes care of it
		translate( [ 0, 0, -5 ] )
			cylinder( 3*ht, d=wdiam+0.5, $fn = 10 ) ;
	}

}

// for consistency, we refer to "hex", even though the nut is round
module wing_nut( 
	diam,   // inner nominal diameter
	pitch,  // mm per turn
	fn = 50,  // polyhedron segments per turn
	diam_adj = +0.1, // nominal outer diameter change (changes backlash)
			    // negative for screw, positive for nut
	angle = 60,
	trunc = -1, // how much to trim the outer peak. -1 : h/4
	fill = -1,  // how much to fill the inner valley. -1: h/8
	hex_width = -1, // hex wrench size in mm, -1 for auto
	hex_thickness = -1 // head thickness in mm, -1 for auto
	)
{
	wdiam = diam + diam_adj ;
	hdiam = hw( hex_width, diam ) / cos(angle/2) - 0.5 ;
	// thickness is oversized compared to standard metal dimensions,
	// since plastic is softer
	ht = hex_thickness!=-1 ? hex_thickness : 6 ;
	difference() {
		scale( [ 1, 1, 3*ht/hdiam ] ) sphere( d = hdiam, $fn=fn  ) ;
		union() {
			translate( [ -2*hdiam, -2*hdiam, -2*hdiam ] )
				cube( [ 4*hdiam,4*hdiam,2*hdiam] ) ;
			translate( [ -2*hdiam, -2*hdiam, ht ] )
				cube( [ 4*hdiam,4*hdiam,hdiam] ) ;
			translate( [ 0, 0, -1 ] )
			cylinder( 2*hdiam, d=wdiam, $fn = 50 ) ;
		}
	}
	if( true )
	nut_core( diam, pitch, ht,  fn = fn,
		diam_adj = diam_adj,
		angle = angle,
		trunc = trunc,
		fill = fill,
		chamfer_top = true, chamfer_bottom = true ) ;
	wing( wdiam, ht, hdiam ) ;
	mirror( [ 1, 0, 0 ] ) wing( wdiam, ht, hdiam ) ;
}

// for sizes M3, M4 M5, M6, M8 and M10, bolt and nut can be rendered.
// set "true" on the top of the file for the sizes to be rendered.
size = [ 10, 12, 14, 16, 20, 20 ] ; // y-space covered by each size
// bolt parameters for each size
// M3-M8 have the thread over the whole 15mm length
// M10 has 15mm of thread over 25mm bolt length
bolt_params = [
	[ 3, 0.5,  15, -0.3, 30, -1,  5 ],
	[ 4, 0.7,  15, -0.3, 50, -1,  5 ],
	[ 5, 0.8,  15, -0.5, 50, -1,  5 ],
	[ 6, 1.0,  15, -0.5, 50, -1, -1 ],
	[ 8, 1.25, 15, -0.7, 50, -1, -1 ],
	[10, 1.5,  25, -0.7, 50, 15, -1 ],
] ;
// nut parameters for each size
nut_params = [
	[ 3, 0.5,  0.3, 30,  5 ],
	[ 4, 0.7,  0.3, 50,  5 ],
	[ 5, 0.8,  0.3, 50,  5 ],
	[ 6, 1.0,  0.3, 50, -1 ],
	[ 8, 1.25, 0.3, 50, -1 ],
	[10, 1.5,  0.3, 50,  8 ],
] ;

// recursive function, returns space used by previously rendered sizes
function sizesum(i) = (i ==0) ? 0 : 
	(showlist[i-1] ?  sizesum(i-1)+size[i-1] : sizesum(i-1)) ;

// show all the selected bolt/nut sizes
module show_all()
{
	render() union() for ( i = [ 1:n_show ] ) {
		n = len( [ for( j=[0:n_show]) if (j<i && showlist[j] ) 1 ] ) ;
		if( showlist[i-1] ) {
			translate( [ 0, sizesum(i-1), 0 ] )
			rotate( [ 0, 0, 30 ] )
			hex_bolt( 
				bolt_params[i-1][0],
				bolt_params[i-1][1],
				bolt_params[i-1][2],
				diam_adj = bolt_params[i-1][3],
				fn = bolt_params[i-1][4],
				thread_length = bolt_params[i-1][5],
				hex_thickness = bolt_params[i-1][6] ) ;
			translate( [ 20, sizesum(i-1), 0 ] )
			rotate( [ 0, 0, 30 ] )
			hex_nut( 
				nut_params[i-1][0],
				nut_params[i-1][1],
				diam_adj = nut_params[i-1][2],
				fn = nut_params[i-1][3],
				hex_thickness = nut_params[i-1][4] ) ;
		} else
			echo("no", bolt_params[i-1][0] ) ;
	}
}

if ( true )
show_all() ;
else
	// or build a wing nut
	render() wing_nut( 10, 1.5, diam_adj = 0.3, hex_thickness = 8 ) ;
