// Inserts laid out as a group, joined by connectors.
//
// Pick a preset, or set preset to "custom" and edit `layout`: a list of rows
// of insert types, bottom row first. Rows are half a cell apart and odd rows
// sit half a column to the right. Types:
//   0 none, 1 empty centre, 2 solid, 3 countersunk screw, 4 M3 nut,
//   5 M4 nut, 6 M5 nut, 7 screw hole with an open back,
//   8 countersunk screw with an open back.
//
// [[1, 1, 1], [1], [1], [2, 2]] is three empty inserts along the bottom row,
// one in each of the next two rows (the third sits directly above the
// first), and two solid inserts in the fourth row.

include <../inserts.scad>

/* [Inserts] */
// A ready-made layout, or "custom" for the layout below
preset = "zigzag column"; // [single, zigzag column, horizontal strip, every type, custom]
// Shrinks the parts that go into the cell (mm)
tolerance = 0; // [0:0.05:0.5]
// Groove pattern and chamfers on the face
decoration = true;

/* [Hidden] */
// Used when preset is "custom"
layout = [[1], [1], [1], [1]];

$fa = 8;
$fs = 0.25;

PRESETS = [
  ["single", [[1]]],
  ["zigzag column", [[1], [1], [1], [1]]],
  ["horizontal strip", [[1, 1, 1], [1, 1]]],
  ["every type", [[1, 2, 3], [4, 5], [6, 7, 8]]],
];
chosen = preset == "custom" ? layout : [for (p = PRESETS) if (p[0] == preset) p[1]][0];
assert(!is_undef(chosen), str("unknown preset ", preset));

hsw_insert_layout(chosen);
