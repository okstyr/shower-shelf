# hexbasket.scad Readability & Maintainability Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `hexbasket.scad` for readability and maintainability: fix a latent alignment bug, rename an opaque variable, lift a nested module to top level, and name the hex step arithmetic.

**Architecture:** All changes are cosmetic — no geometry or parameter values change. After every task, re-render to STL and verify it is byte-for-byte identical to the baseline captured in Task 1. Note: lifting `create_hexgrid` to top level requires moving its dependencies (`short_radius`/`hex_apothem`, `rows`, `columns`, `startx`, `starty`) into the module body, since they currently live in the enclosing `hexgrid_panel` scope.

**Tech Stack:** OpenSCAD 2021.01 (`openscad` CLI), `md5sum` for STL comparison.

---

## File Map

| File | Action |
|---|---|
| `hexbasket.scad` | Modify — all changes land here |
| `hexbasket-baseline.stl` | Create in Task 1, delete in Task 4 |

---

## Task 1: Capture baseline STL

**Files:**
- Create: `hexbasket-baseline.stl` (temporary — deleted in Task 4)

- [ ] **Step 1: Render baseline**

```bash
openscad -o hexbasket-baseline.stl hexbasket.scad 2>&1
```

Expected: no errors, file created.

- [ ] **Step 2: Record baseline checksum**

```bash
md5sum hexbasket-baseline.stl
```

Save the printed hash — compare against it after each task.

---

## Task 2: Fix magic `3` → `cell_wall` in `hexgrid_box`

**Files:**
- Modify: `hexbasket.scad`

- [ ] **Step 1: Fix the left-panel translate**

Find this line in `hexgrid_box`:

```scad
    // Left panel (YZ plane)
    translate([3, 0, height])
```

Change it to:

```scad
    // Left panel (YZ plane)
    translate([cell_wall, 0, height])
```

- [ ] **Step 2: Render and verify identical output**

```bash
openscad -o hexbasket-check.stl hexbasket.scad 2>&1
md5sum hexbasket-check.stl hexbasket-baseline.stl
```

Expected: both hashes identical. (`3` and `cell_wall` are both 3, so geometry is unchanged.)

```bash
rm hexbasket-check.stl
```

- [ ] **Step 3: Commit**

```bash
git add hexbasket.scad
git commit -m "fix: replace magic 3 with cell_wall in hexgrid_box left panel translate"
```

---

## Task 3: Lift `create_hexgrid` to top level and rename `short_radius`

**Files:**
- Modify: `hexbasket.scad`

Currently `create_hexgrid` is a nested module inside `hexgrid_panel`. It references locals that `hexgrid_panel` computes: `short_radius`, `rows`, `columns`, `startx`, `starty`. Lifting it means moving those computations into `create_hexgrid` itself (using its own `w`/`h` parameters instead of the outer `width`/`height`).

- [ ] **Step 1: Replace `hexgrid_panel` with a thin rotation wrapper**

Replace the entire `module hexgrid_panel(...)` block with:

```scad
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
```

Place `create_hexgrid` before `hexgrid_panel` in the file (after the `is_odd` function).

- [ ] **Step 2: Render and verify identical output**

```bash
openscad -o hexbasket-check.stl hexbasket.scad 2>&1
md5sum hexbasket-check.stl hexbasket-baseline.stl
```

Expected: both hashes identical. If they differ, compare the two modules carefully — likely a typo in the `translate` arithmetic.

```bash
rm hexbasket-check.stl
```

- [ ] **Step 3: Commit**

```bash
git add hexbasket.scad
git commit -m "refactor: lift create_hexgrid to top level, rename short_radius to hex_apothem"
```

---

## Task 4: Add named hex step locals and border comment, then final verify

**Files:**
- Modify: `hexbasket.scad`

- [ ] **Step 1: Add named locals and simplify the for-loop translate**

Inside `create_hexgrid`, add three named locals after `starty` and before the `color("maroon")` line:

```scad
    col_step   = cell_wall + (radius * 2) - (radius / 2);
    row_step   = cell_wall + (hex_apothem * 2);
    odd_offset = -(hex_apothem + (cell_wall / 2));
```

Then replace the `translate` inside the `for` loop from:

```scad
            translate([
                    ((cell_wall + (radius * 2) - (radius / 2)) * row),
                    ((is_odd(row) ? -(hex_apothem + (cell_wall / 2)) : 0)) +
                    (((cell_wall) + (hex_apothem * 2)) * column),
                    0
            ])
```

to:

```scad
            translate([
                    col_step * row,
                    (is_odd(row) ? odd_offset : 0) + (row_step * column),
                    0
            ])
```

- [ ] **Step 2: Add border comment**

Add a one-line comment immediately before the second `color("maroon")` block:

```scad
    // solid border strips to close panel edges
    color("maroon")
```

- [ ] **Step 3: Render and verify identical output**

```bash
openscad -o hexbasket-check.stl hexbasket.scad 2>&1
md5sum hexbasket-check.stl hexbasket-baseline.stl
```

Expected: both hashes identical.

- [ ] **Step 4: Remove baseline and check files**

```bash
rm hexbasket-baseline.stl hexbasket-check.stl
```

- [ ] **Step 5: Commit**

```bash
git add hexbasket.scad
git commit -m "refactor: name hex step locals col_step/row_step/odd_offset, add border comment"
```

---

## Final state of `hexbasket.scad`

After all tasks, the complete file should read:

```scad
// hexbox
// as is, makes a five sided box where each side is made of a grid of hexes aranged
// in a panel. Note that a 'hex' is the empty space (or part thereof) surrounded by a wall (a cell wall
// if you will)
// these terms 'box grid hex panel cell_wall' have particular meanings throughout the code.

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

module create_hexgrid(w, h) {
    hex_apothem = sqrt((radius ^ 2) - ((radius / 2) ^ 2));
    // distance from hex centre to the midpoint of a side

    rows    = floor(w / (radius + cell_wall)) + 3;
    columns = floor(h / (radius + cell_wall)) + 3;
    startx  = cell_wall;
    starty  = cell_wall;

    col_step   = cell_wall + (radius * 2) - (radius / 2);
    row_step   = cell_wall + (hex_apothem * 2);
    odd_offset = -(hex_apothem + (cell_wall / 2));

    color("maroon") translate([0, 0, 0])
        linear_extrude(height = wall_thickness)
        difference()
        {
            square([w, h]);
            translate([startx, starty, 0]) for (row = [0:1:rows]) for (column = [0:1:columns]) translate([
                    col_step * row,
                    (is_odd(row) ? odd_offset : 0) + (row_step * column),
                    0
            ]) circle(r = radius, $fn = 6);
        }
    // solid border strips to close panel edges
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

module hexgrid_box(width, depth, height) {
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
```
