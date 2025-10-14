use <rounded_triangle.scad>

$fn = $preview ? 32 : 64; // Smoothness of circles
z_fight = $preview ? 0.05 : 0; // Small offset to prevent z-fighting in preview mode

// =============================================================
// Parameters
// =============================================================
triangle_height = 25;
triangle_base = 12;
tip_diameter = 3;

length = 50;

screw_diameter = 3.3;

// =============================================================
// Main build
// =============================================================
difference() {
  // Extrude a rounded triangle
  translate([-triangle_base / 2, 0, 0])
    linear_extrude(height=length)
      rounded_triangle(triangle_base, triangle_height, tip_diameter);

  // Chamfer the bottom edges
  for (i = [0:1])
    mirror([i, 0, 0])
      translate([-triangle_base / 2, 0, length / 2])
        rotate([0, 0, 25])
          cube([triangle_base / 4, triangle_base / 2, length + z_fight], center=true);

  // Mass cut off at the bottom to reduce material use
  translate([0, 0, length / 2])
    scale([1, 2.5, 1])
      cylinder(h=length + z_fight, d=tip_diameter * 2, center=true, $fn=32);

  // Mass cut off at the bottom to reduce material use
  translate([0, triangle_height * 0.8, length / 2])
    scale([0.5, 2, 1])
      cylinder(h=length + z_fight, d=tip_diameter, center=true, $fn=32);

  // Head bore
  translate([0, triangle_height / 2, length / 2 + screw_diameter * 3])
    cylinder(h=length + z_fight, d=screw_diameter * 1.67, center=true, $fn=32);

  // Screw hole
  translate([0, triangle_height / 2, length / 2])
    cylinder(h=length + z_fight, d=screw_diameter, center=true, $fn=32);
}
