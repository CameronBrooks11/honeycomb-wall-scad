// Customizable Honeycomb Storage Wall 
// https://www.printables.com/model/1108485
// https://www.printables.com/model/1430719

$fn = $preview ? 32 : 64;
z_fight = $preview ? 0.05 : 0;

/*[ Hex unit size ]*/
// Depth of the grid
depth = 8;
// Width of the hexagon's hole (flat-to-flat)
hole_width = 20;
// Thickness of the wall forming each hexagon
wall_thickness = 1.8;

/*[ Grid size settings ]*/
// Bambu Lab A1 bed (approx 10×10 cells with defaults)
max_grid_width = 211;
max_grid_height = 248;
// Prusa i3 mk3 (example):
// max_grid_width  = 240;
// max_grid_height = 208;

/*[ Grid shape ]*/
column_data_index = 0; // [ 0:No custom columns, 1:Original by xander, 2:IKEA365 drybox filament end, 3:IKEA365 drybox other end ]
fill = !column_data_index; // if true, ignores custom column sizes and fills to limits
flip_staggering = true;

// Predefined column sets (ignored when fill = true)
column_data = [
  [], // no gaps: auto-fill to limits
  [3, 5, 8, 6, 4, 3, 4, 5, 6], // original example
  [7, 6, 5, 7, 7, 6, 5, 7], // IKEA365 filament end
  [4, 5, 4, 5, 4, 5, 4, 5], // IKEA365 other end
];
columns = column_data[column_data_index];

// Optional column vertical offsets (ignores grid limits when used)
include_offsets = false;
column_offsets = [0, -2, -3, -1, 0, 2, 4];

// Optional column gaps by row index (1-based)
include_gaps = false;
column_gaps = [[], [3, 4], [4, 5], [2]];

/*[ Solid bottoms ]*/
// If enabled, adds solid floors to selected cells in each column
// Tip: increase `depth` to `depth + solid_height` if you need the same insert depth.
include_solids = false;
solid_height = 1;
column_solids = [[], [], [for (i = [3:1:7]) i], [for (i = [2:1:7]) i]];

/*[ Flat edges ]*/
edge_left = false;
edge_top = false;
edge_right = false;
edge_bottom = false;

// ---------------- Derived hex/grid geometry ----------------
hex_inner_r = hole_width / sqrt(3); // inner side length (center→point)
hex_h = hole_width + 2 * wall_thickness; // outer flat-to-flat
hex_s = hex_h / sqrt(3); // outer side length
hex_d = 2 * hex_s; // outer point-to-point
hex_t = hex_s / 2;

max_grid_hexagons_x =
  fill ? floor(max_grid_width / (hex_d - hex_t) + (edge_left ? 0.5 : 0) + (edge_right ? 0.5 : 0))
  : len(columns);

max_grid_hexagons_y =
  fill ? floor(max_grid_height / hex_h + (edge_top ? 0.5 : 0) + (edge_bottom ? 0.5 : 0))
  : max(columns);

max_grid_hexagons_y_lo =
  fill ? floor(max_grid_height / hex_h - 0.5 + (edge_top ? 0.5 : 0) + (edge_bottom ? 0.5 : 0))
  : (max(columns) - 0.5);

total_width = max_grid_hexagons_x * (hex_d - hex_t) + hex_t;
total_height = hex_h * max(max_grid_hexagons_y - 0.5, max_grid_hexagons_y_lo);

// ---------------- Build ----------------
translate([edge_left ? 0 : hex_s, edge_top ? 0 : -hex_h / 2, 0])
  grid(
    columns,
    include_offsets ? column_offsets : [],
    include_gaps ? column_gaps : [],
    include_solids ? column_solids : [],
    depth,
    hole_width,
    wall_thickness,
    fill
  );

// ===========================================================
// Modules
// ===========================================================
module grid(cols, offsets, gaps, solids, height, hole_w, wall_w, do_fill) {
  for (hcol = [0:do_fill ? max_grid_hexagons_x - 1 : (len(cols) - 1)]) {
    // Per-column helpers
    col_has_offsets = (hcol < len(offsets));
    col_has_gaps = (hcol < len(gaps));
    col_has_solids = (hcol < len(solids));
    col_height = do_fill ? max_grid_hexagons_y : cols[hcol];

    for (hrow = [0:(col_height - 1)]) {
      skip = col_has_gaps && (len(search(hrow + 1, gaps[hcol])) > 0);
      solid_t = col_has_solids && (len(search(hrow + 1, solids[hcol])) > 0);
      if (!skip) {
        offset_value = col_has_offsets ? offsets[hcol] : 0;

        lo = (hcol + (flip_staggering ? 1 : 0)) % 2;
        x = (hex_d - hex_t) * hcol;
        y = -hex_h * (hrow + offset_value + lo / 2);

        in_bounds = hcol < max_grid_hexagons_x && hrow < (lo == 0 ? max_grid_hexagons_y : max_grid_hexagons_y_lo);

        if (in_bounds) {
          left = edge_left && hcol == 0;
          top = edge_top && hrow == 0 && hcol % 2 == (flip_staggering ? 1 : 0);
          right = edge_right && hcol == max_grid_hexagons_x - 1;
          bottom = edge_bottom && hrow + 1 == (lo == 0 ? max_grid_hexagons_y : max_grid_hexagons_y_lo) && -y + hex_h > total_height + 0.001 && -y + hex_h / 2 <= total_height;

          translate([x, y, 0])
            halfhex(height, hex_s, wall_w, hole_w, left, top, right, bottom, solid_t);
        }
      }
    }
  }
}

module halfhex(height, radius, wall_w, hole_w, left, top, right, bottom, solid_t) {
  difference() {
    union() {
      hex(height, radius, wall_w, hole_w, solid_t);
      if (left) translate([0, hex_h / 2, 0]) wall(height, wall_w, hex_h);
      if (top) translate([hex_d / 2, 0, 0]) rotate([0, 0, -90]) wall(height, wall_w, hex_d);
      if (right) translate([0, -hex_h / 2, 0]) rotate([0, 0, 180]) wall(height, wall_w, hex_h);
      if (bottom) translate([-hex_d / 2, 0, 0]) rotate([0, 0, 90]) wall(height, wall_w, hex_d);
    }
    if (left) translate([-hex_d / 2, -hex_h, 0]) cube([hex_d / 2, 2 * hex_h, depth]);
    if (top) translate([-hex_d / 2, 0, 0]) cube([hex_d, hex_h, depth]);
    if (right) translate([0, -hex_h, 0]) cube([hex_d / 2, 2 * hex_h, depth]);
    if (bottom) translate([-hex_d / 2, -hex_h, 0]) cube([hex_d, hex_h, depth]);
  }
}

module hex(height, radius, wall_w, hole_w, solid_t) {
  // Six outer walls
  for (i = [0:5])
    rotate([0, 0, i * 60 + 30])
      translate([-hole_w / 2 - wall_w, radius / 2, 0])
        wall(height, wall_w, radius);

  // Optional solid floor
  if (solid_t)
    translate([0, 0, depth - solid_height])
      linear_extrude(height=solid_height)
        polygon([for (ang = [0:60:359]) [radius * cos(ang), radius * sin(ang)]]);
}

// Profiled wall with optional end-chamfer trimmers
module wall(height, wall_w, len, end_chamfer = false) {
  hmax = height;
  hmin = 5.1;
  hd = 2; // keep Edwin’s compatible heel depth
  tmax = wall_w;
  tmin = wall_w - 1;
  ft = 0.4; // fillet thickness
  fh = 0.5; // fillet height

  difference() {
    rotate([90, 0, 0])
      linear_extrude(len)
        polygon(
          [
            [-0.01, 0],
            [-0.01, hmax],
            [tmin, hmax],
            [tmin, hmax - hd],
            [tmax, hmin],
            [tmax, fh],
            [tmax - ft, 0],
          ]
        );

    // Optional end-face chamfers where walls meet
    // Typically not required as they become merged with adjacent walls
    // But useful for single standalone walls or maybe future scenarios
    if (end_chamfer)
      for (m = [0, 1])
        mirror([0, m, 0])
          translate([0, m * len, -z_fight / 2])
            rotate([0, 0, -30])
              cube([2 * tmax, tmax, hmax + z_fight]);
  }
}
