// tool_holder.scad: a screw-on rack of tool holders.
//
// A flange strip with a screw hole at each end carries a row of holders:
// angled hex pegs with a bore down the middle (for bits, spokes or anything
// slim), or rings that hold a screwdriver by its shank.

/* [Rack] */
// What the rack holds
holder = "peg"; // [peg, ring]
// Number of holders
count = 8;
// Distance from the first holder to the last (mm)
span = 142;

/* [Flange] */
flange_height = 10;
flange_thickness = 3;
// Screw hole diameter (mm)
mount_hole = 5;

/* [Pegs] */
// Across corners of the hex peg (mm)
peg_diameter = 6;
peg_length = 40;
// Upward tilt from horizontal (degrees)
peg_tilt = 15;
// Bore down the peg's axis (mm)
peg_bore = 2.5;

/* [Rings] */
// Shank hole (mm)
ring_hole = 11;
ring_wall = 3;
// Ring height (mm)
ring_height = 12;
// Gap between the ring and the flange (mm)
ring_standoff = 15;

$fn = $preview ? 32 : 64;

pitch = count > 1 ? span / (count - 1) : 0;
flange_length = span + max(holder == "ring" ? ring_hole + 2 * ring_wall : peg_diameter, 0) + 4 * mount_hole;

// The flange lies in the XZ plane, wall side at y = 0 and holder side at
// y = -flange_thickness; holders stand out toward -y.
module flange() {
  difference() {
    translate([-flange_length / 2, -flange_thickness, -flange_height / 2])
      cube([flange_length, flange_thickness, flange_height]);
    for (s = [-1, 1])
      translate([s * (flange_length / 2 - mount_hole), 1, 0]) rotate([90, 0, 0])
        cylinder(d = mount_hole, h = flange_thickness + 2);
  }
}

// A hex peg rising at peg_tilt from the flange face, its root cut flush with
// the flange so it sits flat on it.
module peg() {
  difference() {
    rotate([90 - peg_tilt, 0, 0]) rotate([0, 0, 30]) translate([0, 0, -peg_diameter])
      cylinder(d = peg_diameter, h = peg_length + peg_diameter, $fn = 6);
    rotate([90 - peg_tilt, 0, 0]) translate([0, 0, -peg_diameter - 1])
      cylinder(d = peg_bore, h = peg_length + peg_diameter + 2);
    // keep only what stands in front of the flange face
    translate([-peg_diameter, 0, -2 * peg_length]) cube([2 * peg_diameter, 2 * peg_length, 4 * peg_length]);
  }
}

// A ring for a screwdriver shank, on an arm out from the flange.
module ring() {
  od = ring_hole + 2 * ring_wall;
  y = -(ring_standoff + od / 2);
  difference() {
    union() {
      translate([0, y, -ring_height / 2]) cylinder(d = od, h = ring_height);
      translate([-ring_wall, y, -ring_height / 2]) cube([2 * ring_wall, -y, ring_height]);
    }
    translate([0, y, -ring_height / 2 - 1]) cylinder(d = ring_hole, h = ring_height + 2);
  }
}

module tool_rack() {
  union() {
    flange();
    for (i = [0:count - 1])
      translate([-span / 2 + i * pitch, -flange_thickness, 0])
        if (holder == "ring") ring(); else peg();
  }
}

tool_rack();
