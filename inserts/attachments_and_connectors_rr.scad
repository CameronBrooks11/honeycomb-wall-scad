// https://www.printables.com/model/1430719-customizable-honeycomb-wall-size-layout-thickness/files

wall_thickness = 1.8; //thickness of thicker hexgrid-wall, default: 1.8

include <insert_util_RR.scad>

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [Options] */
tolerance = 0;
decoration = true;

/**
 * The structure array documents the layout of individual
 *
 * 0 - No insert
 * 1 - Empty center
 * 2 - Solid
 * 3 - Countersunk
 * 4 - m3
 * 5 - m4
 * 6 - m5
 * 7 - Empty countersunk
 * 8 - Empty countersunk 85°
 * 9 - ...
 */

// try this out, if you're unsure how the structure is defined:
// structure = [ [1,1,1], [1], [1], [2,2] ];
// this defines three inserts of type 1 on the x-axis, one insert of type 1 in the 2nd row,
// one insert of type 1 in the 3rd row (directly above the first insert of the first row),
// and two inserts of type 2 in the fourth row.
structure = [[1], [1], [1], [1]];

insert_plug_adv(structure);

module insert_plug_adv(structure) {
  for (y_pos = [0:len(structure) - 1]) {
    for (x_pos = [0:len(structure[y_pos]) - 1]) {
      if (structure[y_pos][x_pos] != 0) {
        _draw_insert(structure, x_pos, y_pos, tolerance, decoration);
      }
    }
  }
}
