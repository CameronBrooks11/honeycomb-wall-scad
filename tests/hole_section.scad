// The hole's cross-section at height Z above the back face: a thin slice of
// the space inside one cell. Its extent across y is the hole across flats.
include <../hsw.scad>

Z = 3;
// thin enough that a sloped wall changes less than 0.01 mm across it
SLICE = 0.002;

intersection() {
  translate([-50, -50, Z - SLICE / 2]) cube([100, 100, SLICE]);
  difference() {
    linear_extrude(hsw_depth) hsw_hexagon(hsw_cell_flats());
    hsw_cell();
  }
}
