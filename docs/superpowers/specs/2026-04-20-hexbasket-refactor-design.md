# hexbasket.scad Readability & Maintainability Refactor

**Date:** 2026-04-20  
**File:** `hexbasket.scad`  
**Goal:** Improve readability and fix a latent maintainability bug, following the same pattern applied to shower-bracket.scad.

---

## 1. Bug fix: magic `3` in `hexgrid_box`

```scad
// before
translate([3, 0, height])
    hexgrid_panel(height, depth, YZ);

// after
translate([cell_wall, 0, height])
    hexgrid_panel(height, depth, YZ);
```

The literal `3` equals `cell_wall` by coincidence. If `cell_wall` is changed, the left panel silently misaligns. Replace with `cell_wall`.

## 2. Rename `short_radius` → `hex_apothem`

`short_radius` is the geometric apothem of the hexagon (distance from centre to midpoint of a side). Rename to `hex_apothem` with an updated comment:

```scad
hex_apothem = sqrt((radius ^ 2) - ((radius / 2) ^ 2));
// distance from hex centre to the midpoint of a side
```

Update the one usage of `short_radius` inside `hexgrid_panel` to `hex_apothem`.

## 3. Named local variables for hex step arithmetic

Inside `create_hexgrid` (see §4), extract three named locals before the `for` loop:

```scad
col_step   = cell_wall + (radius * 2) - (radius / 2);
row_step   = cell_wall + (hex_apothem * 2);
odd_offset = -(hex_apothem + (cell_wall / 2));
```

The `translate` inside the `for` loop becomes:

```scad
translate([
    col_step * row,
    (is_odd(row) ? odd_offset : 0) + (row_step * column),
    0
])
```

## 4. Lift `create_hexgrid` to top level

`create_hexgrid(w, h)` is currently a nested module inside `hexgrid_panel`. Lift it to top level, placed before `hexgrid_panel` in the file. `hexgrid_panel` calls it as before.

Add a one-line comment above the second `color("maroon")` block inside `create_hexgrid`:

```scad
// solid border strips to close panel edges
```

---

## Out of scope

- `startx` / `starty` variables — intentionally named for future flexibility per original author comment; leave as-is
- `wall_thickness` / `cell_wall` relationship — these are distinct geometric concepts (in-plane vs extrusion depth) that happen to share a value by design choice; leave as-is
- Any geometry or dimension changes
- New features
