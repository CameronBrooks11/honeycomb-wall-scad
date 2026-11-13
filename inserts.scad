// inserts.scad: snap-in inserts for the honeycomb storage wall.
//
// An insert has a hex body that pushes into a cell, a lip that stays on the
// wall's front face, and six snaps that catch behind the cell's lock. Its
// centre can be left open, solid, or cut for a screw or a nut. Inserts laid
// out together are joined by connectors across the wall between cells.
//
// Sizes follow hsw.scad, so inserts fit whatever hole, wall and depth the
// wall was made with.

include <hsw.scad>

/* [Insert] */
// Shrink the parts that fit into the cell, for a looser fit (mm)
tolerance = 0.1;
// Add a groove pattern and chamfers to the front face
decoration = true;

// ---------------- Sizes ----------------
// Body: 0.3 mm under the hole, narrowing 0.4 mm more over its last 0.4 mm
function ins_body() = hsw_hole - 0.3;
function ins_body_tip() = hsw_hole - 0.7;
ins_tip_h = 0.4;
// Lip: reaches across the wall, leaving room for a connector to the next lip
ins_connector_w = 1.1;
function ins_lip() = hsw_hole + 2 * hsw_wall - ins_connector_w;
function ins_lip_side() = ins_lip() / sqrt(3);
ins_lip_h = 2.5;
// Overall height, lip face to the end of the body
function ins_h() = hsw_depth + 2;
// Centre opening across flats
function ins_core() = hsw_hole - 6.6;
// Reliefs near the end of the body that let each flat flex as it snaps in
ins_relief_h = 3.5;
ins_relief_len = 8;
ins_relief_depth = 0.8;
ins_relief_slot = 1;
function ins_relief_r() = hsw_hole / 2 - 1.75;
// Snaps: a ramp on each flat
ins_snap_r = 0.5;
ins_snap_w = 2;
// Decoration
ins_deco_depth = 0.3;

e = 0.002;

// A hex prism across flats f (corners at 0 and 180 degrees), its corner
// circle shrunk by tol on each side.
module ins_prism(f, h, tol = 0, f_top = undef) {
  d = 2 * f / sqrt(3) - 2 * tol;
  if (is_undef(f_top)) cylinder(d = d, h = h, $fn = 6);
  else cylinder(d1 = d, d2 = 2 * f_top / sqrt(3) - 2 * tol, h = h, $fn = 6);
}

// What a type cuts from the insert's centre:
//   1 empty centre, 2 solid, 3 countersunk screw, 4 M3 nut, 5 M4 nut, 6 M5 nut,
//   7 screw hole with an open back, 8 countersunk screw with an open back.
// Any other type leaves the centre empty, like 1.
module ins_centre(type, tol = 0) {
  h = ins_h();
  if (type == 2) {
  } else if (type == 3) {
    cylinder(r = 5, h = 6);
    translate([0, 0, 6]) cylinder(r1 = 5, r2 = 1.75, h = 3.25);
    cylinder(r = 1.75, h = h + 2 * e);
  } else if (type == 4) {
    ins_nut_pocket(nut = 5.8, depth = 6.3, bolt = 1.6);
  } else if (type == 5) {
    ins_nut_pocket(nut = 7.1, depth = 7, bolt = 2.1, chamfer = 0.3);
  } else if (type == 6) {
    ins_nut_pocket(nut = 8.1, depth = 7, bolt = 2.55, chamfer = 0.3);
  } else if (type == 7) {
    ins_prism(ins_core(), 6, -tol);
    cylinder(r = 1.75, h = h + 2 * e);
  } else if (type == 8) {
    ins_prism(ins_core(), 6.001, -tol);
    translate([0, 0, 6]) cylinder(r1 = 5, r2 = 1.75, h = 3.25);
    cylinder(r = 1.75, h = h + 2 * e);
  } else {
    // a straight-through opening: no fit, so no tolerance
    ins_prism(ins_core(), h + 2 * e);
  }
}

// A nut pocket entered from the body end: a 3 mm hex counterbore 11.4 mm
// across, the nut's hex `depth` deep, and the bolt hole (with an optional
// chamfer where it stops short of the lip face).
module ins_nut_pocket(nut, depth, bolt, chamfer = 0) {
  h = ins_h();
  translate([0, 0, h + 2 * e]) mirror([0, 0, 1]) {
    ins_prism(11.4, 3);
    ins_prism(nut, depth);
    if (chamfer == 0) cylinder(r = bolt, h = h + 2 * e);
    else {
      cylinder(r = bolt, h = 9.7);
      translate([0, 0, 9.7 - e]) cylinder(r1 = bolt, r2 = bolt + chamfer, h = chamfer + 3 * e);
    }
  }
}

// The six flex reliefs, near the end of the body.
module ins_reliefs(tol) {
  for (i = [0:5]) rotate(i * 60)
    translate([-ins_relief_len / 2, ins_relief_r(), ins_h() - ins_relief_h]) {
      translate([0, -tol, 0]) cube([ins_relief_len, ins_relief_depth, ins_relief_h + e]);
      cube([ins_relief_len, (ins_body() - 2 * ins_relief_r()) / 2 + e, ins_relief_slot]);
    }
}

// The six snaps: a ramp on each flat, from a bump just past the reliefs to
// nothing at the body tip.
module ins_snaps(tol) {
  for (i = [0:5]) rotate(i * 60) translate([0, ins_body() / 2 - tol, 0])
    hull() {
      translate([0, 0, ins_h() - ins_relief_h + ins_relief_slot + ins_snap_r])
        rotate([0, 90, 0]) cylinder(r = ins_snap_r, h = ins_snap_w, center = true, $fn = 20);
      translate([0, 0, ins_h() - e - ins_tip_h])
        rotate([0, 90, 0]) cylinder(r = e, h = ins_snap_w, center = true, $fn = 20);
    }
}

// One insert, lip face down at z = 0. `joined` lists, for the six
// directions at 30 + 60 * k degrees, whether a neighbouring insert is there:
// a joined side keeps its lip edge square for the connector.
module hsw_insert(type = 1, tol = tolerance, deco = decoration, joined = [0, 0, 0, 0, 0, 0]) {
  difference() {
    union() {
      ins_prism(ins_body(), ins_h() - ins_tip_h, tol);
      translate([0, 0, ins_h() - ins_tip_h]) ins_prism(ins_body(), ins_tip_h, tol, f_top = ins_body_tip());
      ins_prism(ins_lip(), ins_lip_h);
      ins_snaps(tol);
    }
    for (k = [0:5]) rotate(30 + 60 * k) {
      // trim each vertical corner of the body above the lip
      rotate(30) translate([ins_body() / sqrt(3) - 0.1 - tol, -0.5, ins_lip_h + e])
        cube([1, 1, ins_h() - ins_lip_h]);
      // chamfer the lip's face edge, unless a connector joins there
      if (deco || !joined[k])
        translate([ins_lip() / 2, 0, 0]) rotate([0, 45, 0])
          cube([ins_deco_depth / cos(45), ins_lip_side() + 1, ins_deco_depth / cos(45)], center = true);
      // decorative groove on the face
      if (deco)
        rotate(-90) translate([0, ins_core() / 2 + 2, 0]) cube([10.62, 1, 0.6], center = true);
    }
    translate([0, 0, -e]) ins_centre(type, tol);
    ins_reliefs(tol);
  }
}

// ---------------- Layouts ----------------
// A layout is a list of rows, bottom to top, each a list of insert types (0
// for none). Rows are half a cell apart, and odd rows sit half a column to
// the right, so consecutive rows interlock like the wall's cells.

// Neighbour of [x, y] in direction k (30 + 60 * k degrees).
function ins_neighbour(p, k) =
  let (
    step = [[0, 1], [0, 2], [-1, 1], [-1, -1], [0, -2], [0, -1]][k],
    odd_shift = (p[1] % 2 == 1 && k != 1 && k != 4) ? 1 : 0
  ) [p[0] + step[0] + odd_shift, p[1] + step[1]];

function ins_present(layout, p) =
  p[0] >= 0 && p[1] >= 0 && p[1] < len(layout) && p[0] < len(layout[p[1]]) && layout[p[1]][p[0]] > 0;

function ins_position(p) =
  let (half = hsw_pitch_y() / 2) [p[0] * 2 * hsw_pitch_x() + (p[1] % 2) * hsw_pitch_x(), p[1] * half, 0];

// The connector from an insert's lip toward its neighbour in direction k,
// across the wall. Where three inserts meet, the upward connectors grow a
// point to fill the junction.
module ins_connector(layout, p, k, deco) {
  s1 = ins_lip() / 2 - 0.001;
  s3 = s1 + ins_connector_w + 0.002;
  half_side = ins_lip_side() / 2;
  tip_x = s1 + ins_connector_w / 2 + 0.001;
  pointed = (k == 0 || k == 2) && ins_present(layout, ins_neighbour(p, 1));
  tip_y = pointed ? half_side + (ins_connector_w + 0.001) * sin(60) : half_side;
  h = ins_lip_h - (deco ? ins_deco_depth : 0);
  rotate(30 + 60 * k) mirror([0, k == 2 ? 1 : 0, 0])
    linear_extrude(h)
      polygon([[s1, -half_side], [s1, half_side], [tip_x, tip_y], [s3, half_side], [s3, -half_side]]);
}

module hsw_insert_layout(layout, tol = tolerance, deco = decoration) {
  for (y = [0:len(layout) - 1], x = [0:len(layout[y]) - 1])
    if (layout[y][x] != 0) {
      p = [x, y];
      translate(ins_position(p)) union() {
        hsw_insert(layout[y][x], tol, deco, [for (k = [0:5]) ins_present(layout, ins_neighbour(p, k)) ? 1 : 0]);
        // each insert draws the connectors on its upper three sides
        translate([0, 0, deco ? ins_deco_depth : 0])
          for (k = [0:2]) if (ins_present(layout, ins_neighbour(p, k))) ins_connector(layout, p, k, deco);
      }
    }
}
