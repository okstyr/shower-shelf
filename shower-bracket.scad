// shower_brackets
// brackets to mount 'hexbox' over top of shower wall
// all measures are in mm

/* [shower glass frame parameters] */


// how wide the frame of the shower glass is across the top (mm - like all other measurements)
frame_width = 13;
// how long the frame is where it covers the glass (should include the silicone bead)
frame_height = 27;
// if frame_lip is non zero the hook will clip over the frame and sit snugly against the glass
// the distance between the glass and the outside of the frame - set to 0 to ignore
frame_lip = 3;

/* [bracket dimensions] */

// how thick the bracket is where it touches the frame
bracket_thickness = 3;
// how wice the bracket is
bracket_width = 8;
// how far the bracket descends on the inside of the shower glass
bracket_internal_descent = 100;
// how far the bracket descends on the outside of the shower glass
bracket_external_descent = 100;

total_width = frame_width + (2 * bracket_thickness);


/* [hook for a dowell] */

// how far above the bottom of the bracket_external_descent should the centre of the hook sit
dowell_hook_clearance = 8; 

dowell_hook_descent = bracket_external_descent - dowell_hook_clearance; // how far down is the centre


// padding between the bracket and the hook. its a rectangle of [x,y]
dowell_hook_pad = [24,14];
// thickness of the hook
dowell_hook_thickness = 3;
// diameter of hook
dowell_hook_diameter = 17; // the centre of the circle will be .5 * diameter from the outside edge of the pad
// how much extra hook to build, to grip the dowell (degrees)
dowell_hook_extra_degrees = 5;

/* [attachments for hexbox] */

// instead of registering and gluing, how about some hooks?
// you probably want these set to undef if you are using registrations
//
// the distance down from the top of the bracket to the top of the internal hook
attachment_hook_internal = 36 ;
// the distance down from the top of the bracket to the top of the external hook
attachment_hook_external = 13;

// this is unused, if you would rather glue than use little hooks, edit registration_* in the code to make registration marks to assist with gluing. also remember you might want to set attachment hook to undef
registration_marks=0;

/* [Hidden] */

// registration-* > 0 makes a trianguler outdent to assist with lining up the basket for possible gluing
// registration-* are distances from the top of the frame, not the bracket
// they can be a scalar or a list (for more than one registration). set to undef if you dont want any
// registration_internal = [9,15];  // should be about 25
// registration_external = 11;

registration_internal=undef;
registration_external=undef;



//constants for x and y directions
POS_X = 1;
NEG_X = -1;
POS_Y = 1;
NEG_Y = -1;

module dowell_rectangle(left, top, right, bottom) {
    polygon([[left, top], [right, top], [right, bottom], [left, bottom]]);
}

module dowell_pad() {
    radius = dowell_hook_diameter / 2;
    fudge_factor = -0.5;
    translate([dowell_hook_diameter + bracket_width + dowell_hook_pad[0], dowell_hook_descent, 0])
        dowell_rectangle(
            left   = -radius,
            top    = -dowell_hook_pad[1] / 2,
            right  = -(radius + dowell_hook_pad[0] + dowell_hook_thickness + fudge_factor),
            bottom = dowell_hook_pad[1] / 2
        );
}

module dowell_hook_circle() {
    radius = dowell_hook_diameter / 2;
    ring_outer_d = dowell_hook_diameter + (2 * dowell_hook_thickness);
    translate([dowell_hook_diameter + bracket_width + dowell_hook_pad[0], dowell_hook_descent, 0])
        difference() {
            circle(d = ring_outer_d);
            circle(d = dowell_hook_diameter);
            polygon([
                [0, 0],
                [-radius * 1.2, -(radius + dowell_hook_thickness)],
                [radius + dowell_hook_thickness, -(radius + dowell_hook_thickness)],
                [radius + dowell_hook_thickness, 0]
            ]);
        }
}

module bracket () {
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
        dowell_hook_circle();
        dowell_pad();
    }

    linear_extrude(height = bracket_width) {

        //top
        square([ total_width, bracket_thickness], center = false);
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
        if (registration_internal != undef)
            for (reg = registration_internal)
                registration([0, reg, 0], -bracket_thickness, bracket_thickness);

        if (registration_external != undef)
            for (reg = registration_external)
                registration([total_width, reg, 0], bracket_thickness, bracket_thickness);
        attachment_hook([0,attachment_hook_internal,0],bracket_thickness, -(bracket_thickness*2), (bracket_thickness*2),NEG_X, POS_Y);
        attachment_hook([total_width,attachment_hook_external,0],bracket_thickness, -(bracket_thickness*2), (bracket_thickness*2),POS_X, POS_Y);
        dowell_hook();
    }
}


bracket();
