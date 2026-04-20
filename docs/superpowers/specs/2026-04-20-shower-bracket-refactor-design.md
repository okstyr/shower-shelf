# shower-bracket.scad Readability Refactor

**Date:** 2026-04-20  
**File:** `shower-bracket.scad`  
**Goal:** Improve readability via renaming, named computed values, flattened module nesting, and explicit undef guards.

---

## 1. Rename & remove dead code

- Rename `square_based()` → `bracket()`. The old name described an abandoned implementation strategy, not what the module produces.
- Remove the commented-out `//poly_based();` call at the bottom of the file.

## 2. Named computed values (top-level)

Add two named variables alongside the existing parameters:

```scad
total_width = frame_width + (2 * bracket_thickness);
// replaces the repeated expression used 4+ times in bracket()

dowell_hook_clearance = 8;
// gap (mm) between the top of the dowell hook circle centre and bracket_external_descent
// used as: dowell_hook_descent = bracket_external_descent - dowell_hook_clearance
```

## 3. Flatten nested modules

`make_rectangle`, `make_pad`, and `make_hook` are currently nested three levels deep (`square_based` → `dowell_hook` → sub-module). Lift them to top-level, prefixed with `dowell_` to signal their purpose and avoid name collisions:

| Old (nested) | New (top-level) |
|---|---|
| `make_rectangle(left, top, right, bottom)` | `dowell_rectangle(left, top, right, bottom)` |
| `make_pad()` | `dowell_pad()` |
| `make_hook()` | `dowell_hook_circle()` |

`dowell_hook()` becomes a thin caller of `dowell_hook_circle()` and `dowell_pad()`, and is itself called from `bracket()`.

`registration` and `attachment_hook` remain inside `bracket()` — they have no nesting problem and are not used elsewhere.

## 4. Fix `for(reg=undef)` pattern

The registration blocks silently no-op when `registration_internal` / `registration_external` are `undef`. Replace with explicit guards:

```scad
// before
for(reg=registration_internal) { registration(...); }

// after
if (registration_internal != undef)
    for (reg = registration_internal) { registration(...); }
```

Same pattern for `registration_external`.

## 5. Named intermediate value in dowell modules

Inside `dowell_hook_circle()`, the expression `dowell_hook_diameter + (2 * dowell_hook_thickness)` is used twice for the outer ring diameter. Extract to a local variable:

```scad
ring_outer_d = dowell_hook_diameter + (2 * dowell_hook_thickness);
```

---

## Out of scope

- Parameter grouping / section headers (low value given only ~15 parameters)
- Any geometry or dimension changes
- New features
