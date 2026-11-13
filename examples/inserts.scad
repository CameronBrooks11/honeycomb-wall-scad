// Inserts laid out as a group, joined by connectors.
//
// Each row of `layout` is a list of insert types, bottom row first; rows are
// half a cell apart and odd rows sit half a column to the right. Types:
//   0 none, 1 empty centre, 2 solid, 3 countersunk screw, 4 M3 nut,
//   5 M4 nut, 6 M5 nut, 7 screw hole with an open back,
//   8 countersunk screw with an open back.
//
// [[1, 1, 1], [1], [1], [2, 2]] is three empty inserts along the bottom row,
// one in each of the next two rows (the third sits directly above the
// first), and two solid inserts in the fourth row.

include <../inserts.scad>

$fa = 8;
$fs = 0.25;

tolerance = 0;
decoration = true;
layout = [[1], [1], [1], [1]];

hsw_insert_layout(layout);
