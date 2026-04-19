// hexbox
// as is, makes a five sided box where each side is made of a grid of hexes aranged
// in a panel. Note that a 'hex' is the empty space (or part thereof) surrounded by a wall (a cell wall
// if you will)
// these terms 'box grid hex panel cell_wall' have particular meanings throughout the code.

/*
   Silver
   Gray
   Black
   Red
   Maroon
   Yellow
   Olive
   Lime
   Green
   Aqua
   Teal
   Blue
   Navy
   Fuchsia
   Purple
   */

// glasses tray 160 x 90 x 30
// bottles tray 130 x 90 x 90

// Box dimensions (in mm)
box_width = 140;
box_depth = 90;
box_height = 90;

// Hexgrid parameters
cell_wall = 3;     // Space between hexes
radius = 8;        // Distance from centre of hex to an apex
wall_thickness = cell_wall; // Thickness of the walls

// plane selection constants
XY = 0; //not really needed, but makes the code look nicer
XZ = 1;
YZ = 2;

function is_odd(x) = x % 2; // naming function to make purpose more apparent

// hex grid
// remember centre of circle is at the coords


module hexgrid_panel(width, height, plane_select = XY) {
    // the real work of hexgrid panel is actually done in create_hexgrid, this section
    // just to calculate a few values we need, and importantly,  rotate the plane so that // create_hexgrid can work with an 'internal' xy coordinate space without needing to
    // think about 3 dimensions

    short_radius = (sqrt((radius ^ 2) - ((radius / 2) ^ 2)));
    // the distance from the centre of the hex to the middle of one side

    rows = floor(width / (radius + cell_wall)) + 3;    // x
    columns = floor(height / (radius + cell_wall)) + 3; // y
                                                        // start<blah>: give us cell_wall worth of space around the edge
                                                        // i just used these so that i could easily change these to a different
                                                        // value if i wanted later
    startx = cell_wall;
    starty = cell_wall;

    // Apply rotation based on plane selection
    if (plane_select == XZ) {       // XZ plane
        rotate([90, 0, 0])
            create_hexgrid(width, height);
    } else if (plane_select == YZ) { // YZ plane
        rotate([270, 0, 90])
        //rotate([90, 0, 0])
            create_hexgrid(height,width);
    } else {                       // XY plane (default)
        create_hexgrid(width, height);
    }

    module create_hexgrid(w, h) {
        color("maroon") translate([0, 0, 0])
            linear_extrude(height = wall_thickness)
            // the cell_wall shall be square in cross-section
            // in these for loops, the apparent off-by-one is a feature not a bug
            // we want the hexes to 'go over' so when we do a border it will
            // be hexes all the way to the edge
            difference()
            {
                square([w, h]);
                translate([startx, starty, 0]) for (row = [0:1:rows]) for (column = [0:1:columns]) translate([
                        ((cell_wall + (radius * 2) - (radius / 2)) * row), // x
                        ((is_odd(row) ? -(short_radius + (cell_wall / 2)) : 0)) +
                        (((cell_wall) + (short_radius * 2)) * column), // y
                        0
                ]) circle(r = radius, $fn = 6);
            }
        color("maroon")
        {
            linear_extrude(height = wall_thickness)
            {
                square([w, cell_wall]);
                square([cell_wall, h]);
                translate([0, h - cell_wall, 0]) square([w, cell_wall]);
                translate([w - cell_wall, 0, 0]) square([cell_wall, h]);
            }
        }
    }
}

// Create a complete box (5 sides, open top)
module hexgrid_box(width, depth, height) {
    // i do wonder if some of the code here should be combined with the outer code
    // in hexgrid panel - either here or there, since both bits of code are dealing with
    // 'hiding' the 3d stuff from create_hexgrid. but my reasoning was that leaving it
    // here makes the decision of how many panels and their distribuition was outside the
    // core hexgrid code. this is hexgrid_BOX afterall.

    // Bottom panel (XY plane)
    hexgrid_panel(width, depth, XY);

    // Front panel (XZ plane)
    translate([0, cell_wall, 0])
        hexgrid_panel(width, height, XZ);

    // Back panel (XZ plane)
    translate([0, depth, 0])
        hexgrid_panel(width, height, XZ);

    // Left panel (YZ plane)
    translate([3, 0, height])
        hexgrid_panel(height, depth, YZ);

    // Right panel (YZ plane)
    translate([width, 0, height])
        hexgrid_panel(height, depth, YZ);
}

// Create the box with the specified dimensions
hexgrid_box(box_width, box_depth, box_height);
