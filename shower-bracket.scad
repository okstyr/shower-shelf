// shower_brackets
// brackets to mount 'hexbox' over top of shower wall
// all measures are in mm

frame_width = 13;  // how wide the frame is accross the top
frame_height = 27; // how long the frame is where it covers the glass
                   // should include the silicone bead
frame_lip = 3;  // the distance between the glass and the outside of the frame
                // this will make the ends of the bracket this much thicker
                // set to 0 to ignore

bracket_thickness = 3;
bracket_width = 8;
bracket_internal_descent = 100;  // should be 60 in and 50 out
bracket_external_descent = 100;

dowell_hook_descent = bracket_external_descent - 8 ; // how far down is the centre
dowell_hook_pad = [24,14];  // padding between the bracket and the hook. its a rectangle of [x,y]
dowell_hook_thickness = 3;
dowell_hook_diameter = 17; // the centre of the circle will be .5 * diameter from the outside edge of the pad
dowell_hook_extra_degrees = 5;

// registration-* > 0 makes a trianguler outdent to assist with lining up the basket (hexbox)

// registration-* are distances from the top of the frame, not the bracket
// they can be a scalar or a list. set to undef if you dont want any
//registration_internal = [9,15];  // should be about 25
//registration_external = 11;
registration_internal=undef;
registration_external=undef;

// instead of registering and gluing, how about a couple of hooks
// attachment top and bottom form two hooks where the bottom of att-top and
// the top of att-bottom is this far from the top of the bracket.  ie the difference between them should be the height of your basket
attachment_hook_internal = 36 ;
attachment_hook_external = 13;

//attachment_bottom_internal = 18 ;
//attachment_bottom_external = 18;

//constants for x and y directions
POS_X = 1;
NEG_X = -1;
POS_Y = 1;
NEG_Y = -1;

module square_based () {
    module registration (origin, opposite, adjacent) {
        // draws a right angle triangle at origin with sides of length opposite
        // and adjacent.
        translate(origin)
            polygon([[0,0],[opposite,adjacent],[0,adjacent]]);
    }

    module attachment_hook(origin, thickness, width, height, xdir, ydir) {
        // make a hook. drawing time:
        // drawing made from the perspective of the hook extending into negative x and positive y
        // origin     _    .   _
        //                    | |
        // y = inside _     __| |  (or, height - thickness)
        // y = height _    |____|
        //
        // x = width  .  .  .   |
        //
        // Note that noting is printed along origin(y) - this isthe material that the hook
        // extends from
        //
        // xdir and ydir should be either 1 or -1 to determine in what directions the hook extends
        // from origin. ie to get the drawing above, x=-1 and y=1

        //ydir = 1;
        //xdir = -1;
        // adjust our base dimensions for direction
        thicky = ydir*thickness;
        thickx = xdir*thickness;
        heighty = ydir*height;
        widthx = -xdir*width;

        // now derive the outer and internal (inner bottom) dimmensions
        bottom = heighty;
        left = widthx-thickx;
        internal = heighty-thicky;
        translate(origin)
            polygon([
                    [0,0],
                    [0,bottom],
                    [widthx,bottom],
                    [widthx,0],
                    [left,0],
                    [left,internal],
                    [0,internal]
            ]);


    }

    module dowell_hook() {
        module make_rectangle(left, top, right, bottom){
            polygon([[left,top], [right, top], [right, bottom], [left,bottom]]);
        };
        module make_pad(){
            radius=dowell_hook_diameter/2;
            // just calling this what it is - a sign of bad maths somewhere
            // it means i cant do something nice like curve the sides of the pad
            // till i work it out.  Note the bigger the hook diameter gets the
            // more this varies to the negative, the smaller, the more positive
            // its not float probs. its my maths
            fudge_factor = -0.5;
            translate([dowell_hook_diameter+bracket_width+dowell_hook_pad[0],dowell_hook_descent,0]) // same as hook so it can be embedded later

                make_rectangle(
                        left=-radius,
                        top=-dowell_hook_pad[1]/2,
                        right=-(radius+dowell_hook_pad[0]+dowell_hook_thickness+fudge_factor),
                        bottom=dowell_hook_pad[1]/2
                        );
        }

        module make_hook() {
            radius=dowell_hook_diameter/2;
            translate([dowell_hook_diameter+bracket_width+dowell_hook_pad[0],dowell_hook_descent,0])

                difference(){
                    circle(d=dowell_hook_diameter+(2*dowell_hook_thickness));
                    circle(d=dowell_hook_diameter);

                    polygon([
                            [0,0],
                            [-radius*1.2,-(radius+dowell_hook_thickness)],
                            [radius+dowell_hook_thickness,-(radius+dowell_hook_thickness)],
                            [radius+dowell_hook_thickness,0]
                    ]);
                }
        }

        make_hook();
        make_pad();
    }

    linear_extrude(height = bracket_width) {

        //top
        square([ frame_width+(2 * bracket_thickness), bracket_thickness], center = false);
        //insid
        square([ bracket_thickness, bracket_internal_descent+bracket_thickness], center=false);
        //outside
        translate([frame_width+( bracket_thickness),0,0])
            square([ bracket_thickness, bracket_external_descent+bracket_thickness], center=false);

        // frame_lip
        translate([bracket_thickness, frame_height+bracket_thickness,0])
            polygon([[0,0],[frame_lip,bracket_thickness],[frame_lip,bracket_internal_descent-frame_height-bracket_thickness],[0,bracket_internal_descent-frame_height]]);

        translate([frame_width + bracket_thickness, frame_height+bracket_thickness,0])
            polygon([[0,0],[-frame_lip,bracket_thickness],[-frame_lip,bracket_external_descent-frame_height-bracket_thickness],[0,bracket_external_descent-frame_height]]);

        // registration
        for(reg=registration_internal) {
            registration([0,reg,0], -bracket_thickness, bracket_thickness);
        }
        for(reg=registration_external) {
            registration([frame_width+(2*bracket_thickness),registration_external,0], bracket_thickness, bracket_thickness);
        }
        attachment_hook([0,attachment_hook_internal,0],bracket_thickness, -(bracket_thickness*2), (bracket_thickness*2),NEG_X, POS_Y);
        attachment_hook([frame_width+(2*bracket_thickness),attachment_hook_external,0],bracket_thickness, -(bracket_thickness*2), (bracket_thickness*2),POS_X, POS_Y);
        dowell_hook();
    }
}


square_based();
//poly_based();
