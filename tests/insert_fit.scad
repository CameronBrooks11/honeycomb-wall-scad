// One insert seated in one cell, intersected with it. The insert's lip face
// is its z = 0; seated, the lip lies on the wall's front face and the body
// reaches back into the hole. Only the six snaps should press into the wall.
include <../inserts.scad>

TYPE = 1;
intersection() {
  hsw_cell();
  translate([0, 0, hsw_depth + ins_lip_h]) mirror([0, 0, 1]) hsw_insert(TYPE, tol = 0, deco = false);
}
