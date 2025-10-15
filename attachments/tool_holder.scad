/*
    screwdriver screwdriver_holder v1.0
    author: Ken Serrine 2023-01-06
    modified by: Cameron K. Brooks 2025-10-13
*/

$fn = $preview ? 32 : 64;
z_fight = $preview ? 0.05 : 0;

hd = 11; // hole diameter
th = 3; // wall thickness
mount_hole_diameter = 5;
hole_height = 30; // vertical hole separation

// Derived
total_width = hd + (th * 2);
total_depth = hole_height + (th * 2);
total_height = hole_height + (th * 2);

// simple spoke parameters
spoke_hole = 2.5;

spoke_length = 40;
spoke_diameter = 6;
spoke_angle = 15;

module spoke_holder() {
  reorigin_y = spoke_diameter / 2 * sin(spoke_angle);
  echo(reorigin_y);
  translate([0, -reorigin_y, 0])
    rotate([-90 + spoke_angle, 0, 0])
      difference() {
        difference() {
          cylinder(h=spoke_length, d=spoke_diameter, $fn=6);
          translate([0, 0, -z_fight / 2])
            cylinder(h=spoke_length + z_fight, d=spoke_hole);
        }

        // diameter of circle to hex
        triangle_pts = [
          [0, 0],
          [spoke_diameter, 0],
          [0, spoke_diameter * tan(spoke_angle)],
        ];

        translate([-spoke_diameter / 2, -spoke_diameter / 2, 0])
          rotate([0, 0, 90])
            rotate([90, 0, 0])

              color("red")
                linear_extrude(height=spoke_diameter)
                  polygon(points=triangle_pts);
      }
}

module screwdriver_holder() {
  difference() {
    cube([total_width, total_depth, total_height], center=true);

    // cut off back corners
    for (i = [-1, 1])
      translate([0, total_depth * 3 / 4, i * total_height * 3 / 4])
        rotate([45, 0, 0])
          cube([total_width + z_fight, total_depth, total_height], center=true);

    cylinder(h=hole_height * 2, d=hd, center=true);

    rotate([0, 90, 0])
      cylinder(h=hd * 2, d=hole_height - (th * 2), center=true);

    translate([0, -hole_height / 2 + th, 0])
      cube(hole_height - (th * 2), center=true);
  }
}

module mounted_screwdriver_holder() {
  screwdriver_holder();
  mounting_flange(width=total_width + mount_hole_diameter * 2);
}

module mounting_flange(width) {
  handle_width = width + mount_hole_diameter / 3 * 2;

  difference() {
    translate([0, 0, 0])
      cube([handle_width + (th * 2), th, 10], center=true);

    translate([-handle_width / 2 + mount_hole_diameter / 3, 0, 0])
      rotate([90, 0, 0])
        cylinder(h=th + z_fight, d=mount_hole_diameter, center=true);

    translate([handle_width / 2 - mount_hole_diameter / 3, 0, 0])
      rotate([90, 0, 0])
        cylinder(h=th + z_fight, d=mount_hole_diameter, center=true);
  }
}

module multi_screwdriver_holder(separation, number_of_holders) {
  individual_separation = separation / number_of_holders;
  translate([-(individual_separation * (number_of_holders - 1)) / 2, 0, 0]) {
    for (i = [0:number_of_holders - 1]) {
      translate([i * individual_separation, 0, 0])
        screwdriver_holder();
    }
  }

  translate([0, hole_height / 2 + th / 2, 0])
    mounting_flange(width=separation);
}

module multi_spoke_holder(separation, number_of_holders) {
  individual_separation = separation / number_of_holders;
  translate([-(individual_separation * (number_of_holders - 1)) / 2, 0, 0]) {
    for (i = [0:number_of_holders - 1]) {
      translate([i * individual_separation, 0, 0])
        spoke_holder();
    }
  }

  mounting_flange(width=separation);
}

//multi_screwdriver_holder(separation=162, number_of_holders=5);

multi_spoke_holder(162, number_of_holders=8);
