// hook.scad: a screw-on wall hook.
//
// A strip bent into a J: a back plate against the wall, a bend into a
// horizontal arm, and a bend up into the lip. The two free ends are rounded
// across the strip's width. Edges are filleted or chamfered.

/* [Size] */
// Back plate length, from the bend to the start of its rounded top (mm)
back_length = 90;
// Strip width (mm)
width = 60;
// Strip thickness (mm)
thickness = 15;
// Arm length between the two bends (mm)
arm_length = 40;
// Inside radius of both bends (mm)
bend_radius = 10;

/* [Edges] */
edge_style = "fillet"; // [fillet, chamfer]
// Fillet radius (mm)
fillet = 1;
// Chamfer size (mm)
chamfer = 3;

/* [Screws] */
// Screw hole diameter (mm)
screw_diameter = 6; // [5, 6, 8, 10]
// Countersink the holes on the hook side
countersink = false;

$fn = $preview ? 32 : 64;

// The strip's cross-section: x across the thickness, y across the width.
module section() {
  if (edge_style == "chamfer") {
    c = min(chamfer, thickness / 2 - 0.01, width / 2 - 0.01);
    polygon([[c, 0], [thickness - c, 0], [thickness, c], [thickness, width - c],
             [thickness - c, width], [c, width], [0, width - c], [0, c]]);
  } else {
    f = min(fillet, thickness / 2 - 0.01, width / 2 - 0.01);
    translate([f, f]) offset(r = f) square([thickness - 2 * f, width - 2 * f]);
  }
}

// A straight run of strip along +z, from z = 0 to len.
module run(len) {
  linear_extrude(len) section();
}

// A rounded end across the strip's width, standing on z = 0.
module rounded_end() {
  r = width / 2;
  if (edge_style == "chamfer") {
    c = min(chamfer, thickness / 2 - 0.01);
    intersection() {
      translate([0, r, 0]) rotate([0, 90, 0]) hull() {
        cylinder(r = r - c, h = thickness);
        translate([0, 0, c]) cylinder(r = r, h = thickness - 2 * c);
      }
      translate([0, 0, 0]) cube([thickness, width, r]);
    }
  } else {
    f = min(fillet, thickness / 2 - 0.01);
    intersection() {
      translate([f, r, 0]) rotate([0, 90, 0]) minkowski() {
        cylinder(r = r - f, h = thickness - 2 * f);
        sphere(f, $fn = 16);
      }
      cube([thickness, width, r]);
    }
  }
}

// A quarter bend of strip: the section swept 90 degrees about an axis along
// y, inside radius bend_radius.
module bend() {
  rotate([90, 0, 0]) rotate_extrude(angle = 90)
    translate([bend_radius, 0]) rotate(0) mirror([0, 1]) section();
}

module screw_holes() {
  for (z = [back_length / 3, back_length])
    translate([0, width / 2, z]) rotate([0, 90, 0]) {
      translate([0, 0, -1]) cylinder(d = screw_diameter, h = thickness + 2);
      if (countersink)
        translate([0, 0, -0.01]) cylinder(d1 = screw_diameter * 1.7, d2 = screw_diameter, h = thickness / 4);
    }
}

// The back plate stands at x = 0..thickness, wall side at x = thickness; the
// hook opens toward -x.
module hook() {
  r = bend_radius;
  difference() {
    union() {
      run(back_length);
      translate([0, 0, back_length]) rounded_end();
      // bend at the bottom of the back plate, into the arm
      translate([-r, 0, 0]) rotate([0, 0, 0]) mirror([0, 0, 1]) bend();
      // the arm, running toward -x
      translate([-r, 0, -r]) rotate([0, -90, 0]) translate([-thickness, 0, 0]) run(arm_length);
      // bend up into the lip
      translate([-r - arm_length, 0, 0]) rotate([0, 0, 180]) translate([0, -width, 0]) mirror([0, 0, 1]) bend();
      // the lip's rounded top
      translate([-2 * r - arm_length - thickness, 0, 0]) rounded_end();
    }
    screw_holes();
  }
  echo(str("Hook: ", back_length + width / 2 + r + thickness, " mm tall, ", arm_length + 2 * (r + thickness), " mm deep"));
}

hook();
