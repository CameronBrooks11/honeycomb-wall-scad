// hsw.scad: shared sizes and cell geometry for the honeycomb storage wall.
//
// The wall, the inserts and the clips all read their sizes from here, so a
// change to the hole, the wall or the depth carries through to every part.
// Include it before setting any of these in your own file to override them.
//
// Coordinates: the wall lies in the XY plane, back face at z = 0, front face
// at z = hsw_depth. Cells are hexagons with corners at 0 and 180 degrees,
// columns along x.

/* [Honeycomb size] */
// Hole across flats (mm)
hsw_hole = 20;
// Wall around each hole (mm); neighbouring cells sit wall to wall
hsw_wall = 1.8;
// Grid depth, back to front (mm)
hsw_depth = 8;

/* [Insert lock] */
// Height above the back face where the hole starts to widen (mm)
hsw_lock_z = 5.1;
// Depth of the wider opening at the front (mm)
hsw_lip_depth = 2;
// How much each wall thins in the front opening (mm)
hsw_lip = 1;
// Chamfer on the back edge of each hole, against elephant's foot (mm)
hsw_back_chamfer_w = 0.4;
hsw_back_chamfer_h = 0.5;

// ---------------- Derived ----------------
// Outer cell across flats, and the cell's side (= circumradius)
function hsw_cell_flats() = hsw_hole + 2 * hsw_wall;
function hsw_cell_side() = hsw_cell_flats() / sqrt(3);
// Centre-to-centre spacing: between columns, and between rows in a column
function hsw_pitch_x() = 1.5 * hsw_cell_side();
function hsw_pitch_y() = hsw_cell_flats();
// Hole across flats at the front opening
function hsw_front_hole() = hsw_hole + 2 * hsw_lip;

// The hole's width across flats from the back face (z = 0) to the front:
// chamfered at the back, straight to the lock, widening to the front opening.
function hsw_hole_profile(depth = hsw_depth) = [
  [hsw_hole + 2 * hsw_back_chamfer_w, 0],
  [hsw_hole, hsw_back_chamfer_h],
  [hsw_hole, hsw_lock_z],
  [hsw_front_hole(), depth - hsw_lip_depth],
  [hsw_front_hole(), depth],
];

// A regular hexagon across flats f, corners at 0 and 180 degrees.
module hsw_hexagon(f) {
  circle(r = f / sqrt(3), $fn = 6);
}

// The hole as a solid, slightly longer than the cell so it cuts cleanly.
module hsw_hole_solid(depth = hsw_depth) {
  p = hsw_hole_profile(depth);
  e = 0.01;
  rotate_extrude($fn = 6)
    polygon(concat(
      [[0, -e], [p[0][0] / sqrt(3), -e]],
      [for (q = p) [q[0] / sqrt(3), q[1]]],
      [[p[len(p) - 1][0] / sqrt(3), depth + e], [0, depth + e]]
    ));
}

// One cell: the outer hexagon less its hole.
module hsw_cell(depth = hsw_depth) {
  assert(depth >= hsw_lock_z + hsw_lip_depth,
         str("hsw_depth must be at least hsw_lock_z + hsw_lip_depth (", hsw_lock_z + hsw_lip_depth, " mm)"));
  difference() {
    linear_extrude(depth) hsw_hexagon(hsw_cell_flats());
    hsw_hole_solid(depth);
  }
}

// A straight wall with the hole's profile on its inner face, for closing a
// cut cell along a flat edge. It lies along y from 0 to len, outer face at
// x = 0 and inner face at x = hsw_wall, toward +x.
module hsw_edge_wall(len, depth = hsw_depth) {
  p = hsw_hole_profile(depth);
  rotate([90, 0, 0]) translate([0, 0, -len])
    linear_extrude(len)
      polygon(concat(
        [[0, 0]],
        [for (q = p) [hsw_wall - (q[0] - hsw_hole) / 2, q[1]]],
        [[0, depth]]
      ));
}
