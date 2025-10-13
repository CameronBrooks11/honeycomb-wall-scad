// https://www.printables.com/model/1430719-customizable-honeycomb-wall-size-layout-thickness/files

/*[ Hex unit size ]*/

//Width of the hexagon's hole (flat side to flat side)
hole_width = 20;
//Thickness of the thicker wall forming each hexagon. The thinner one is 1mm less.
wall_thickness = 1.8; //default: 1.8

/*[ Grid size settings ]*/
//Prusa CoreOne: 240x220
max_grid_width = 240;
max_grid_height = 220;

/*[ Grid shape ]*/
//If checked, ignores custom column sizes and fills grid to maximum size.
fill = true;
flip_staggering = false;
//Amount of hexagons per column. Each entry defines a one column, where the number specifies the amount of hex units that will be generated for the respective column. (Ignored if "fill" is checked)
columns = [3, 5, 8, 6, 4, 3, 4, 5, 6];

//Optional: Offset for each column. This will ignore grid size limits.
include_offsets = false;
column_offsets = [0, -2, -3, -1, 0, 2, 4];

//Optional: Gaps for each column.
include_gaps = false;
column_gaps = [[], [3, 4], [4, 5], [2]];

//Optional: Solid bottom for each column.
// If you add solid sections, you may want to change the "depth" of the grid
// from "8" to "8 + solid_height" to ensure that inserts can still be locked in.
include_solids = false;
solid_height = 1;
depth = 8; //Depth of the grid, default: 8
column_solids = [[], [], [for (i = [3:1:7]) i], [for (i = [2:1:7]) i]];

/*[ Flat edges ]*/
edge_left = false;
edge_top = false;
edge_right = false;
edge_bottom = false;

//Calculated global variables
//Hexagon dimensions
hex_inner_r = hole_width / sqrt(3); //Inner radius/side length (center to point)
hex_h = hole_width + wall_thickness * 2; //Outer side to side distance
hex_s = hex_h / sqrt(3); //Outer radius/side length 
hex_d = 2 * hex_s; //Outer diameter (point to point)
hex_t = hex_s / 2;
//Grid dimensions
max_grid_hexagons_x = fill ? floor(max_grid_width / (hex_d - hex_t) + (edge_left ? 0.5 : 0) + (edge_right ? 0.5 : 0)) : len(columns);
max_grid_hexagons_y = fill ? floor(max_grid_height / hex_h + (edge_top ? 0.5 : 0) + (edge_bottom ? 0.5 : 0)) : max(columns);
max_grid_hexagons_y_lo = fill ? floor(max_grid_height / hex_h - 0.5 + (edge_top ? 0.5 : 0) + (edge_bottom ? 0.5 : 0)) : (max(columns) - 0.5);
total_width = max_grid_hexagons_x * (hex_d - hex_t) + hex_t;
total_height = hex_h * max(max_grid_hexagons_y - 0.5, max_grid_hexagons_y_lo);

translate([edge_left ? 0 : hex_s, edge_top ? 0 : -hex_h / 2, 0])
  grid(columns, include_offsets ? column_offsets : [], include_gaps ? column_gaps : [], include_solids ? column_solids : [], depth, hole_width, wall_thickness, fill);

module grid(cols, offsets, gaps, solids, height, hole_width, wall_width, fill) {
  for (hcol = [0:fill ? max_grid_hexagons_x - 1 : (len(cols) - 1)]) {
    for (hrow = [0:(fill ? (max_grid_hexagons_y - 1) : (cols[hcol] - 1))]) {
      skip = hcol < len(gaps) && len(search(hrow + 1, gaps[hcol])) > 0;
      solid_t = hcol < len(solids) && len(search(hrow + 1, solids[hcol])) > 0;
      if (!skip) {
        offset_value = hcol > len(offsets) - 1 ? 0 : offsets[hcol];

        lo = (hcol + (flip_staggering ? 1 : 0)) % 2;
        x = (hex_d - hex_t) * hcol;
        y = -(hex_h) * (hrow + offset_value + lo / 2);

        if (hcol < max_grid_hexagons_x && hrow < (lo == 0 ? max_grid_hexagons_y : max_grid_hexagons_y_lo)) {
          left = edge_left && hcol == 0;
          top = edge_top && hrow == 0 && hcol % 2 == (flip_staggering ? 1 : 0);
          right = edge_right && hcol == max_grid_hexagons_x - 1;
          bottom = edge_bottom && hrow + 1 == (lo == 0 ? max_grid_hexagons_y : max_grid_hexagons_y_lo) && -y + hex_h > total_height + 0.001 && -y + hex_h / 2 <= total_height;
          translate([x, y, 0]) halfhex(height, hex_s, wall_width, hole_width, left, top, right, bottom, solid_t);
        }
      }
    }
  }
}

module halfhex(height, radius, wall_thickness, hole_width, left, top, right, bottom, solid_t) {
  difference() {
    union() {
      hex(height, radius, wall_thickness, hole_width, solid_t);
      if (left) translate([0, hex_h / 2, 0]) wall(depth, wall_thickness, hex_h);
      if (top) translate([hex_d / 2, 0, 0]) rotate([0, 0, -90]) wall(depth, wall_thickness, hex_d);
      if (right) translate([0, -hex_h / 2, 0]) rotate([0, 0, 180]) wall(depth, wall_thickness, hex_h);
      if (bottom) translate([-hex_d / 2, 0, 0]) rotate([0, 0, 90]) wall(depth, wall_thickness, hex_d);
    }
    if (left) translate([-hex_d / 2, -hex_h, 0]) cube([hex_d / 2, 2 * hex_h, depth]);
    if (top) translate([-hex_d / 2, 0, 0]) cube([hex_d, hex_h, depth]);
    if (right) translate([0, -hex_h, 0]) cube([hex_d / 2, 2 * hex_h, depth]);
    if (bottom) translate([-hex_d / 2, -hex_h, 0]) cube([hex_d, hex_h, depth]);
  }
}

module hex(height, radius, wall_thickness, hole_width, solid_t) {
  for (i = [0:5]) {
    rotate([0, 0, i * 60 + 30])
      translate([-hole_width / 2 - wall_thickness, radius / 2, 0])
        wall(height, wall_thickness, radius);
  }

  if (solid_t)
    translate([0, 0, depth - solid_height])
      linear_extrude(height=solid_height)
        polygon([for (i = [0:60:359]) [hex_s * cos(i), hex_s * sin(i)]]);
}

module wall(height, wall_thickness, length) {
  hmax = height;
  hmin = 5.1;
  hd = 6;
  tmax = wall_thickness;
  tmin = wall_thickness - 1;
  ft = 0.4; //fillet thickness
  fh = 0.5; //fillet height

  difference() {
    rotate([90, 0, 0])
      linear_extrude(length)
        polygon([[-0.01, 0], [-0.01, hmax], [tmin, hmax], [tmin, hd], [tmax, hmin], [tmax, fh], [tmax - ft, 0]]);
  }
}
