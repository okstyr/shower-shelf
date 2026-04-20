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


module create_hexgrid(w, h) {
    hex_apothem = sqrt((radius ^ 2) - ((radius / 2) ^ 2));
    // distance from hex centre to the midpoint of a side

    rows    = floor(w / (radius + cell_wall)) + 3;
    columns = floor(h / (radius + cell_wall)) + 3;
    startx  = cell_wall;
    starty  = cell_wall;

    color("maroon") translate([0, 0, 0])
        linear_extrude(height = wall_thickness)
        difference()
        {
            square([w, h]);
            translate([startx, starty, 0]) for (row = [0:1:rows]) for (column = [0:1:columns]) translate([
                    ((cell_wall + (radius * 2) - (radius / 2)) * row),
                    ((is_odd(row) ? -(hex_apothem + (cell_wall / 2)) : 0)) +
                    (((cell_wall) + (hex_apothem * 2)) * column),
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

module hexgrid_panel(width, height, plane_select = XY) {
    if (plane_select == XZ) {
        rotate([90, 0, 0])
            create_hexgrid(width, height);
    } else if (plane_select == YZ) {
        rotate([270, 0, 90])
            create_hexgrid(height, width);
    } else {
        create_hexgrid(width, height);
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
    translate([cell_wall, 0, height])
        hexgrid_panel(height, depth, YZ);

    // Right panel (YZ plane)
    translate([width, 0, height])
        hexgrid_panel(height, depth, YZ);
}

// Create the box with the specified dimensions
hexgrid_box(box_width, box_depth, box_height);
