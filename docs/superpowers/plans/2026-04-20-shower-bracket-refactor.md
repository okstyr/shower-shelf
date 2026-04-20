# shower-bracket.scad Readability Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `shower-bracket.scad` for readability: rename the main module, add named computed values, flatten deeply-nested sub-modules, and replace silent `undef` loop no-ops with explicit guards.

**Architecture:** All changes are cosmetic — no geometry or parameter values change. After every task, re-render to STL and verify it is byte-for-byte identical to the baseline captured in Task 1.

**Tech Stack:** OpenSCAD 2021.01 (`openscad` CLI), `diff` for STL comparison.

---

## File Map

| File | Action |
|---|---|
| `shower-bracket.scad` | Modify — all changes land here |
| `shower-bracket-baseline.stl` | Create in Task 1, delete in Task 5 |

---

## Task 1: Capture baseline STL

**Files:**
- Create: `shower-bracket-baseline.stl` (temporary — deleted in Task 5)

- [ ] **Step 1: Render baseline**

```bash
openscad -o shower-bracket-baseline.stl shower-bracket.scad 2>&1
```

Expected: no errors, file created, size > 0 bytes.

```bash
ls -lh shower-bracket-baseline.stl
```

- [ ] **Step 2: Record baseline checksum**

```bash
md5sum shower-bracket-baseline.stl
```

Save the printed hash — you'll compare against it after each task.

---

## Task 2: Rename main module and remove dead code

**Files:**
- Modify: `shower-bracket.scad`

- [ ] **Step 1: Rename `square_based` → `bracket` and remove `//poly_based()`**

Replace the bottom of the file (the module declaration and call site) so it reads:

```scad
module bracket () {
```

and the final call at the bottom becomes:

```scad
bracket();
```

Remove the line `//poly_based();` entirely. The full bottom of the file after this task:

```scad
    linear_extrude(height = bracket_width) {
        // ... (unchanged body) ...
    }
}

bracket();
```

- [ ] **Step 2: Render and verify identical output**

```bash
openscad -o shower-bracket-check.stl shower-bracket.scad 2>&1
md5sum shower-bracket-check.stl shower-bracket-baseline.stl
```

Expected: both hashes identical.

- [ ] **Step 3: Commit**

```bash
git add shower-bracket.scad
git commit -m "refactor: rename square_based to bracket, remove dead poly_based comment"
```

---

## Task 3: Add named computed values

**Files:**
- Modify: `shower-bracket.scad`

- [ ] **Step 1: Add `total_width` and `dowell_hook_clearance` after existing parameters**

After the line `bracket_external_descent = 100;`, add:

```scad
total_width = frame_width + (2 * bracket_thickness);

dowell_hook_clearance = 8; // gap (mm) between top of dowell hook centre and bracket_external_descent
```

Then change the existing `dowell_hook_descent` line from:

```scad
dowell_hook_descent = bracket_external_descent - 8 ; // how far down is the centre
```

to:

```scad
dowell_hook_descent = bracket_external_descent - dowell_hook_clearance; // how far down is the centre
```

- [ ] **Step 2: Replace repeated `frame_width+(2 * bracket_thickness)` inside `bracket()` with `total_width`**

Find every occurrence of `frame_width+(2 * bracket_thickness)` and `frame_width + (2 * bracket_thickness)` inside `bracket()` and replace with `total_width`. There are three occurrences in the `linear_extrude` body:

```scad
// top bar — change from:
square([ frame_width+(2 * bracket_thickness), bracket_thickness], center = false);
// to:
square([total_width, bracket_thickness], center = false);

// registration_external origin — change from:
registration([frame_width+(2*bracket_thickness),registration_external,0], bracket_thickness, bracket_thickness);
// to:
registration([total_width, registration_external, 0], bracket_thickness, bracket_thickness);

// attachment_hook external call — change from:
attachment_hook([frame_width+(2*bracket_thickness),attachment_hook_external,0],bracket_thickness, -(bracket_thickness*2), (bracket_thickness*2),POS_X, POS_Y);
// to:
attachment_hook([total_width, attachment_hook_external, 0], bracket_thickness, -(bracket_thickness*2), (bracket_thickness*2), POS_X, POS_Y);
```

- [ ] **Step 3: Render and verify identical output**

```bash
openscad -o shower-bracket-check.stl shower-bracket.scad 2>&1
md5sum shower-bracket-check.stl shower-bracket-baseline.stl
```

Expected: both hashes identical.

- [ ] **Step 4: Commit**

```bash
git add shower-bracket.scad
git commit -m "refactor: name total_width and dowell_hook_clearance computed values"
```

---

## Task 4: Flatten dowell sub-modules to top level

**Files:**
- Modify: `shower-bracket.scad`

The three modules `make_rectangle`, `make_pad`, `make_hook` are currently nested inside `dowell_hook()` inside `bracket()`. Lift them to top-level, rename with `dowell_` prefix, and introduce `ring_outer_d` to name the repeated ring diameter expression.

- [ ] **Step 1: Add three new top-level modules before `bracket()`**

Insert this block immediately before the `module bracket()` line:

```scad
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
```

- [ ] **Step 2: Replace the body of `dowell_hook()` inside `bracket()`**

Find the `module dowell_hook()` block inside `bracket()` and replace its entire body with calls to the new top-level modules:

```scad
    module dowell_hook() {
        dowell_hook_circle();
        dowell_pad();
    }
```

The nested `module make_rectangle`, `module make_pad`, and `module make_hook` definitions are deleted entirely.

- [ ] **Step 3: Render and verify identical output**

```bash
openscad -o shower-bracket-check.stl shower-bracket.scad 2>&1
md5sum shower-bracket-check.stl shower-bracket-baseline.stl
```

Expected: both hashes identical.

- [ ] **Step 4: Commit**

```bash
git add shower-bracket.scad
git commit -m "refactor: lift dowell sub-modules to top level, add ring_outer_d"
```

---

## Task 5: Fix silent `undef` loop guards

**Files:**
- Modify: `shower-bracket.scad`

- [ ] **Step 1: Replace registration `for` loops with explicit `if` guards**

Inside `bracket()`, find the two registration blocks and replace them:

```scad
// BEFORE:
        for(reg=registration_internal) {
            registration([0,reg,0], -bracket_thickness, bracket_thickness);
        }
        for(reg=registration_external) {
            registration([frame_width+(2*bracket_thickness),registration_external,0], bracket_thickness, bracket_thickness);
        }

// AFTER:
        if (registration_internal != undef)
            for (reg = registration_internal)
                registration([0, reg, 0], -bracket_thickness, bracket_thickness);

        if (registration_external != undef)
            for (reg = registration_external)
                registration([total_width, reg, 0], bracket_thickness, bracket_thickness);
```

Note: the original `registration_external` block passed the whole variable as the y-coordinate instead of `reg` — this is corrected here to match the clearly-intended pattern. The fix is safe because `registration_external` is currently `undef` and has no effect on rendered output.

- [ ] **Step 2: Render and verify identical output**

```bash
openscad -o shower-bracket-check.stl shower-bracket.scad 2>&1
md5sum shower-bracket-check.stl shower-bracket-baseline.stl
```

Expected: both hashes identical.

- [ ] **Step 3: Remove baseline and check files**

```bash
rm shower-bracket-baseline.stl shower-bracket-check.stl
```

- [ ] **Step 4: Commit**

```bash
git add shower-bracket.scad
git commit -m "refactor: explicit undef guards for registration loops, fix loop var bug"
```

---

## Final state of `shower-bracket.scad`

After all tasks, the complete file should read:

```scad
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

total_width = frame_width + (2 * bracket_thickness);

dowell_hook_clearance = 8; // gap (mm) between top of dowell hook centre and bracket_external_descent
dowell_hook_descent = bracket_external_descent - dowell_hook_clearance; // how far down is the centre
dowell_hook_pad = [24,14];  // padding between the bracket and the hook. its a rectangle of [x,y]
dowell_hook_thickness = 3;
dowell_hook_diameter = 17; // the centre of the circle will be .5 * diameter from the outside edge of the pad
dowell_hook_extra_degrees = 5;

// registration-* > 0 makes a trianguler outdent to assist with lining up the basket (hexbox)
// registration-* are distances from the top of the frame, not the bracket
// they can be a scalar or a list. set to undef if you dont want any
//registration_internal = [9,15];  // should be about 25
//registration_external = 11;
registration_internal = undef;
registration_external = undef;

// instead of registering and gluing, how about a couple of hooks
// attachment top and bottom form two hooks where the bottom of att-top and
// the top of att-bottom is this far from the top of the bracket.  ie the difference between them should be the height of your basket
attachment_hook_internal = 36;
attachment_hook_external = 13;

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

module bracket() {
    module registration(origin, opposite, adjacent) {
        // draws a right angle triangle at origin with sides of length opposite and adjacent
        translate(origin)
            polygon([[0, 0], [opposite, adjacent], [0, adjacent]]);
    }

    module attachment_hook(origin, thickness, width, height, xdir, ydir) {
        // drawing made from the perspective of the hook extending into negative x and positive y
        // origin     _    .   _
        //                    | |
        // y = inside _     __| |  (or, height - thickness)
        // y = height _    |____|
        //
        // x = width  .  .  .   |
        //
        // xdir and ydir should be either 1 or -1 to determine in what directions the hook extends
        thicky  = ydir * thickness;
        thickx  = xdir * thickness;
        heighty = ydir * height;
        widthx  = -xdir * width;

        bottom   = heighty;
        left     = widthx - thickx;
        internal = heighty - thicky;
        translate(origin)
            polygon([
                [0, 0],
                [0, bottom],
                [widthx, bottom],
                [widthx, 0],
                [left, 0],
                [left, internal],
                [0, internal]
            ]);
    }

    module dowell_hook() {
        dowell_hook_circle();
        dowell_pad();
    }

    linear_extrude(height = bracket_width) {
        // top
        square([total_width, bracket_thickness], center = false);
        // inside leg
        square([bracket_thickness, bracket_internal_descent + bracket_thickness], center = false);
        // outside leg
        translate([frame_width + bracket_thickness, 0, 0])
            square([bracket_thickness, bracket_external_descent + bracket_thickness], center = false);

        // frame_lip
        translate([bracket_thickness, frame_height + bracket_thickness, 0])
            polygon([[0, 0], [frame_lip, bracket_thickness], [frame_lip, bracket_internal_descent - frame_height - bracket_thickness], [0, bracket_internal_descent - frame_height]]);
        translate([frame_width + bracket_thickness, frame_height + bracket_thickness, 0])
            polygon([[0, 0], [-frame_lip, bracket_thickness], [-frame_lip, bracket_external_descent - frame_height - bracket_thickness], [0, bracket_external_descent - frame_height]]);

        if (registration_internal != undef)
            for (reg = registration_internal)
                registration([0, reg, 0], -bracket_thickness, bracket_thickness);

        if (registration_external != undef)
            for (reg = registration_external)
                registration([total_width, reg, 0], bracket_thickness, bracket_thickness);

        attachment_hook([0, attachment_hook_internal, 0], bracket_thickness, -(bracket_thickness * 2), (bracket_thickness * 2), NEG_X, POS_Y);
        attachment_hook([total_width, attachment_hook_external, 0], bracket_thickness, -(bracket_thickness * 2), (bracket_thickness * 2), POS_X, POS_Y);
        dowell_hook();
    }
}

bracket();
```
