/* [Shape of the hexes -- lowercase is deprecated and will go away] */

hswx_wall = 1.8; // hexagon inner wall thickness [:0.01]

hswx_inside = 20; // hexagon inside width flat-flat
hswx_outside = hswx_inside + hswx_wall * 2; // hexagon outside width flat-flat

hswx_side = hswx_outside / sqrt(3); // hexagon outside side length
hswx_od = hswx_side * 2; // outer diameter of circle containing outer hexagon

hswx_depth = 8; // depth of grid

hswx_lock_depth = 5; // depth of locking section start

hswx_lock_lip = 1; // depth of lip = protrusion of lip = chamfer
hswx_lock_chamfer = hswx_lock_lip; // chamfer is 45deg, so defined = lock_lip

hswx_id_large = (hswx_inside + 2 * hswx_lock_lip) * 2 / sqrt(3); // diameter of circle containing larg hexagon fitting locks and clips
hswx_id_small = hswx_inside * 2 / sqrt(3); // diameter of circle containing small hexagon fitting standard plugs

module _hswx_constant_show_all() {
  echo("hswx_inside", hswx_inside);
  echo("hswx_wall", hswx_wall);
  echo("hswx_outside", hswx_outside);
  echo("hswx_side", hswx_side);
  echo("hswx_od", hswx_od);
  echo("hswx_lock_depth", hswx_lock_depth);
  echo("hswx_lock_lip", hswx_lock_lip);
  echo("hswx_id_large", hswx_id_large);
  echo("hswx_id_small", hswx_id_small);
}
