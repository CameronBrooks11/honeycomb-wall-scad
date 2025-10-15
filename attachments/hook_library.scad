/* 
Customizable hook with fillet or chamfer
By: Eric Buijs
version: 1.1
Date: 24-September 2022

Changelog
v 1.1. Added countersunk option for screw holes

CC BY-SA (explanation of Creative Common licenses: https://creativecommons.org/licenses/)

Customizable hook that can be changed in length (both horizontal and vertical), width, thickness, radius of the edge, type of edge (fillet or chamfer), diameter of the screw holes. 

By choosing the size of the fillet or chamfer make sure that the sum of each fillet (or chamfer) stays well below the width of the hook.

Source: https://www.printables.com/model/91734-parametric-hook-with-source-file

*/

/* [Dimensions of hook]*/
//vertical length of square part the hook 
length1 = 90;

//width of hook
width = 60;

//horizontal length square part of the hook
length2 = 40;

radius1 = width / 2;

//thickness of the hook
thickness = 15;

/*[Type of hook ] */
//type of hook (fillet=checked, chamfer=unchecked) 
type = true;

//size of the fillet
fillet = 1;

//size of the chamfer
chamfer = 5;

//radius of the hook (also changes the total length of the hook)
hookRadius = 10;

/* [Other] */
//number of fragments
$fn = 30;

//diameter of the screw holes
diameter = 6; // [5,6,8,10]

//enable countersunk in screw hole
countersunk = false;

/*** MODULES ***/

//cylinderWithRadius creates a c1ylinder (h1, r1) with a radius r2
module cylinderWithFillet(h1, r1, r2) {
  radius = r2;
  diameter = radius * 2;
  minkowski() {
    cylinder(h=h1 - diameter, r=r1 - (radius), center=true, $fn=100);
    sphere(r=radius);
  }
}

//halfCylinderWithRadius create half a cylinder (h1, r1) with a radius r2
module halfCylinderWithFillet(h1, r1, r2) {
  difference() {
    cylinderWithFillet(h1, r1, r2);
    translate([0, -r1, -0.5 * h1])
      cube([r1, 2 * r1, h1]);
  }
}

//the fillet module creates a fillet with a length of l and a radius of r1
module fillet(l, r1) {
  intersection() {
    cube([l, l, l]);
    cylinder(h=l, r=r1, $fn=50);
  }
}

// roundedCube creates a cube (l: length of the fillet, w: width, h: thickness) with a radius of r1;
module roundedCube(l, w, h, r1) {
  d = 2 * r1;
  translate([r1, r1, 0])
    hull() {
      rotate([0, 0, 180]) fillet(l, r1);
      translate([0, w - d, 0]) rotate([0, 0, 90]) fillet(l, r1);
      translate([h - d, 0, 0]) rotate([0, 0, 270]) fillet(l, r1);
      translate([h - d, w - d, 0]) rotate([0, 0, 0]) fillet(l, r1);
    }
}

// bendedCubeWithFillet creates a bended cube (length, width, thickness) with a fillet size a. hr is the radius of the hook.
module bendedCubeWithFillet(l, w, h, hr) {
  rotate_extrude(angle=90, convexity=2, $fn=50) {
    translate([hr, 0, 0]) //x-value changes radius
      minkowski() {
        projection()
          roundedCube(l, w, h, fillet);
      }
  }
}

//chamferedCube create a cube (l#translate([thickness/2,width/2,0]) rotate([0,90,0]) cylinder(r=diameter/2, h=thickness+4, center=true);,w,h) with a chamfer (or bevel)
module chamferedCube(l, w, h, c) {
  linear_extrude(height=l) {
    hull() {
      polygon([[c, 0], [0, c], [c, c]]);
      translate([w - c, h - c, 0]) polygon([[0, 0], [c, 0], [0, c]]);
      translate([w - c, 0, 0]) polygon([[0, 0], [0, c], [c, c]]);
      translate([0, h - c, 0]) polygon([[0, 0], [c, 0], [c, c]]);
    }
  }
}

//bendedChamferedCube creates a cube (l,w,h) with a chamfer c. If radius changes also change in MAIN
module bendedChamferedCube(l, w, h, c, hr) {
  rotate_extrude(angle=90, convexity=2, $fn=100)
    translate([hr, 0, 0]) //x-value changes radius
      projection()
        chamferedCube(l, w, h, c);
}

//halfCylinderWithChamfer create half a circle with radius r and thickness th. It also has a chamfer with size c.
module halfCylinderWithChamfer(r, c, th) {
  rotate_extrude(angle=180, convexity=2, $fn=60)
    polygon([[0, 0], [r - c, 0], [r, c], [r, th - c], [r - c, th], [0, th]]);
}

// added countersunk option in this module
module screwHoles(dia, countersunk) {
  translate([thickness / 2, width / 2, length1])
    rotate([0, 90, 0])
      cylinder(r=dia / 2, h=thickness + 4, center=true);

  translate([thickness / 2, width / 2, length1 / 3])
    rotate([0, 90, 0])
      cylinder(r=dia / 2, h=thickness + 4, center=true);

  if (countersunk == true) {

    translate([thickness / 8 - 0.01, width / 2, length1 / 3])
      rotate([0, 90, 0])
        cylinder(r1=dia / 2 * 1.7, r2=dia / 2, h=thickness / 4, center=true);

    translate([thickness / 8 - 0.01, width / 2, length1])
      rotate([0, 90, 0])
        cylinder(r1=dia / 2 * 1.7, r2=dia / 2, h=thickness / 4, center=true);
  }
}

//MAIN

if (type == true) {

  //**** fillet ****
  difference() {
    union() {
      // create the fillet at top
      translate([thickness / 2, radius1, length1])
        rotate([0, 90, 0])
          halfCylinderWithFillet(thickness, radius1, fillet);

      // create the vertical body part of the hook
      roundedCube(length1, width, thickness, fillet);

      // create the internal bend at the inner side of the hook
      translate([-hookRadius, 0, 0]) rotate([-90, 0, 0])
          bendedCubeWithFillet(length1, width, thickness, hookRadius);

      // create the horizontal body part of the hook
      translate([-length2 - hookRadius, 0, -hookRadius])
        rotate([0, 90, 0])
          roundedCube(length2, width, thickness, fillet);

      // create the external bend at the outer side of the hook
      translate([-length2 - hookRadius, 0, 0])
        rotate([-90, 90, 0])
          bendedCubeWithFillet(length1, width, thickness, hookRadius);

      // create the fillet at the bottom
      translate([-length2 - (2 * hookRadius) - thickness / 2, radius1, 0])
        rotate([0, 90, 0])
          halfCylinderWithFillet(thickness, radius1, fillet);
    }
    screwHoles(diameter, countersunk);
  }

  echo("The total height of the hook is: ", length1 + hookRadius + thickness + radius1);
  echo("The total depth of the hook is: ", length2 + 2 * (hookRadius + thickness));
} else {

  //**** chamfer ****
  difference() {
    translate([thickness, 0, 0]) rotate([0, 0, 90])
        union() {
          chamferedCube(length1, width, thickness, chamfer);
          translate([radius1, thickness, length1])
            rotate([90, 0, 0])
              halfCylinderWithChamfer(radius1, chamfer, thickness);
          translate([0, thickness + hookRadius, 0])
            rotate([-90, 0, -90])
              bendedChamferedCube(width, thickness, width, chamfer, hookRadius);
          translate([0, thickness + hookRadius, -hookRadius])
            rotate([-90, 0, 0])
              chamferedCube(length2, width, thickness, chamfer);
          translate([0, length2 + thickness + hookRadius, 0])
            rotate([0, 90, 0])
              bendedChamferedCube(width, thickness, width, chamfer, hookRadius);
          translate([radius1, length2 + 2 * thickness + 2 * hookRadius, 0])
            rotate([90, 0, 0])
              halfCylinderWithChamfer(radius1, chamfer, thickness);
        }
    screwHoles(diameter, countersunk);
  }

  echo("The total height of the hook is: ", length1 + hookRadius + thickness + radius1);
  echo("The total depth of the hook is: ", length2 + 2 * (hookRadius + thickness));
}
