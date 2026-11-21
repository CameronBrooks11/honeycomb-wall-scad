/* [Shape of the hexes -- lowercase is deprecated and will go away] */

// The hole, wall, depth and lip come from the wall's shared sizes in hsw.scad,
// so the clips fit whatever grid the wall was made with.
include <../hsw.scad>

hswx_wall = hsw_wall; // hexagon inner wall thickness [:0.01]

hswx_inside = hsw_hole; // hexagon inside width flat-flat
hswx_outside = hswx_inside + hswx_wall * 2; // hexagon outside width flat-flat

hswx_side = hswx_outside / sqrt(3); // hexagon outside side length
hswx_od = hswx_side * 2; // outer diameter of circle containing outer hexagon

hswx_depth = hsw_depth; // depth of grid

hswx_lock_depth = 5; // depth of locking section start

hswx_lock_lip = hsw_lip; // depth of lip = protrusion of lip = chamfer
