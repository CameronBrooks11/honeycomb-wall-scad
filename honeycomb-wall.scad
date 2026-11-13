// honeycomb-wall.scad: a parametric honeycomb storage wall.
//
// Fills a print bed with honeycomb cells, or builds a custom layout column
// by column, with optional gaps, solid cells and flat edges. Cell sizes come
// from hsw.scad, shared with the inserts and clips.

include <hsw.scad>

/* [Grid size] */
// Largest wall that fits the print bed (mm). The defaults suit a Bambu Lab
// A1 (about 10 x 10 cells); a Prusa i3 MK3 takes 240 x 208.
max_grid_width = 211;
max_grid_height = 248;

/* [Layout] */
// 0 fills the grid size; the others are column-by-column layouts
column_data_index = 0; // [0:Fill the grid size, 1:Example layout, 2:IKEA 365+ drybox filament end, 3:IKEA 365+ drybox other end]
// Cells in each column, left to right, for each layout
column_data = [
  [],
  [3, 5, 8, 6, 4, 3, 4, 5, 6],
  [7, 6, 5, 7, 7, 6, 5, 7],
  [4, 5, 4, 5, 4, 5, 4, 5],
];
// Start the half-cell stagger on the first column instead of the second
flip_staggering = true;

// Move columns up or down, in cells (custom layouts can then exceed the grid size)
include_offsets = false;
column_offsets = [0, -2, -3, -1, 0, 2, 4];

// Leave cells out: for each column, the rows to skip, counting from 1
include_gaps = false;
column_gaps = [[], [3, 4], [4, 5], [2]];

/* [Solid cells] */
// Close the front of chosen cells with a solid face. Tip: add solid_height to
// hsw_depth to keep the same insert depth behind it.
include_solids = false;
solid_height = 1;
// For each column, the rows to close, counting from 1
column_solids = [[], [], [for (i = [3:7]) i], [for (i = [2:7]) i]];

/* [Flat edges] */
edge_left = false;
edge_top = false;
edge_right = false;
edge_bottom = false;

$fn = $preview ? 32 : 64;

// ---------------- Layout ----------------
fill = column_data_index == 0;
columns = column_data[column_data_index];
// A flat edge cuts a cell in half, so it makes room for half a cell more.
half_x = (edge_left ? 0.5 : 0) + (edge_right ? 0.5 : 0);
half_y = (edge_top ? 0.5 : 0) + (edge_bottom ? 0.5 : 0);

column_count = fill ? floor(max_grid_width / hsw_pitch_x() + half_x) : len(columns);
// Rows in the unshifted columns, and in the columns shifted half a cell down
rows_even = fill ? floor(max_grid_height / hsw_pitch_y() + half_y) : max(columns);
rows_odd = fill ? floor(max_grid_height / hsw_pitch_y() - 0.5 + half_y) : max(columns) - 0.5;

// How far down the grid reaches, for trimming the bottom edge
grid_height = hsw_pitch_y() * max(rows_even - 0.5, rows_odd);

function shifted(col) = (col + (flip_staggering ? 1 : 0)) % 2;
function rows_in(col) = shifted(col) == 0 ? rows_even : rows_odd;
function listed(list, col, row) = col < len(list) && len(search(row + 1, list[col])) > 0;

// ---------------- Build ----------------
translate([edge_left ? 0 : hsw_cell_side(), edge_top ? 0 : -hsw_pitch_y() / 2, 0])
  for (col = [0:column_count - 1]) {
    n = fill ? rows_even : columns[col];
    lift = include_offsets && col < len(column_offsets) ? column_offsets[col] : 0;
    for (row = [0:n - 1])
      if (row < rows_in(col) && !(include_gaps && listed(column_gaps, col, row))) {
        y = -hsw_pitch_y() * (row + lift + shifted(col) / 2);
        last = row + 1 == rows_in(col);
        translate([hsw_pitch_x() * col, y, 0])
          wall_cell(
            left = edge_left && col == 0,
            top = edge_top && row == 0 && shifted(col) == 0,
            right = edge_right && col == column_count - 1,
            // only a last cell that runs past the bottom, centre still inside
            bottom = edge_bottom && last && hsw_pitch_y() - y > grid_height + 0.001 && hsw_pitch_y() / 2 - y <= grid_height,
            solid = include_solids && listed(column_solids, col, row)
          );
      }
  }

// A cell, cut in half and closed with a flat wall on each side that asks,
// and closed at the front if solid.
module wall_cell(left, top, right, bottom, solid) {
  h = hsw_pitch_y();
  d = 2 * hsw_cell_side();
  difference() {
    union() {
      hsw_cell();
      if (solid)
        translate([0, 0, hsw_depth - solid_height])
          linear_extrude(solid_height) hsw_hexagon(hsw_cell_flats());
      if (left) translate([0, -h / 2, 0]) hsw_edge_wall(h);
      if (right) translate([0, h / 2, 0]) rotate([0, 0, 180]) hsw_edge_wall(h);
      if (top) translate([-d / 2, 0, 0]) rotate([0, 0, -90]) hsw_edge_wall(d);
      if (bottom) translate([d / 2, 0, 0]) rotate([0, 0, 90]) hsw_edge_wall(d);
    }
    if (left) translate([-d / 2, -h, -1]) cube([d / 2, 2 * h, hsw_depth + 2]);
    if (right) translate([0, -h, -1]) cube([d / 2, 2 * h, hsw_depth + 2]);
    if (top) translate([-d / 2, 0, -1]) cube([d, h, hsw_depth + 2]);
    if (bottom) translate([-d / 2, -h, -1]) cube([d, h, hsw_depth + 2]);
  }
}
