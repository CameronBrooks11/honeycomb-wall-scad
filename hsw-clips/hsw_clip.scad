include <BOSL2/std.scad>
include <BOSL2/rounding.scad>
include <BOSL2_utils.scad>
include <hswx.scad>

$fn = $preview ? 32 : 64;

generate_clipconnector = false;
generate_clip = false;
generate_clip_rect_base = false;
generate_clip_hex_base = false;

// A double clip to hold two pieces of HSW together
module hsw_clipconnector(
  slop = 0, // some extra gap so the fit is not so tight
  rectbase = 0, // put a rectangular base on top and give it a height
  hexbase = 0 // put a hexbase on top and give it a height
) {

  bridge_x = hswx_outside - hswx_inside;
  bridge_y = (hswx_inside / 2) - slop;

  difference() {
    union() {
      // two clips with base
      hsw_clip(center=true, rotate=180, type=0, rectbase=rectbase, slop=slop, hexbase=hexbase);
      translate([hswx_outside, 0, 0])
        hsw_clip(center=true, rotate=0, type=0, rectbase=rectbase, slop=slop, hexbase=hexbase);
      translate([hswx_outside / 2 - bridge_x / 2, -bridge_y / 2, 0])
        cube([bridge_x, bridge_y, height]);
    }

    height = max(rectbase, hexbase);

    // carve out the stress-reliever between them to bend
    translate([hswx_outside / 2, hswx_inside / 2, height])
      rotate([90, 0, 0])
        cylinder(h=hswx_inside, d=height);
  }
}

plug_base_thickness = 1;
plug_base_lip = 1;
plug_stud_thickness = 1.7;
plug_stud_height = hswx_lock_depth - 2;
plug_spring_base = 3;
plug_spring_depth = 5;
plug_spring_thickness = 1.4;

module hsw_clip(
  center = false, // center or start from [0,0,0]
  rotate = 0, // rotate result
  type = 0, // type not used -- may someday specify weak v. strong directional
  hexbase = 0, // put a hexbase on top and give it a height
  rectbase = 0, // put a rectangular base on top and give it a height
  slop = 0
) // introduce slop to clip length if too tight
{
  hswx_inside = hswx_inside - slop;
  outline = [
    [
      [-plug_base_lip, 0],
      [slop, 0, 0.1], // origin
      [slop, hswx_lock_depth], // strong-side base
      [-hswx_lock_lip, hswx_lock_lip + hswx_lock_depth, 0.5], // strong lock

      [-hswx_lock_lip, hswx_depth, 1.5],

      [plug_stud_thickness, hswx_depth], // spring
      [plug_spring_base, hswx_depth, 3.5],
      [hswx_inside / 2, hswx_depth - plug_spring_depth - 0.5, 5.0], // upper spring midpoint
      [hswx_inside - plug_spring_base, hswx_depth, 3.5],
      [hswx_inside - plug_stud_thickness, hswx_depth],

      [hswx_inside, hswx_depth, 2.0], // weak lock
      [hswx_inside + hswx_lock_lip, hswx_lock_depth + hswx_lock_lip, 0.5],
      [hswx_inside, hswx_lock_depth], // weak-side base
      [hswx_inside, 0.1, 0.1],
      [hswx_inside + 0.1, 0],
      [hswx_inside - plug_stud_thickness - 0.5, 0],
      [hswx_inside - plug_stud_thickness, 0.5, 1.0],
      /**/
      [hswx_inside - plug_stud_thickness, hswx_depth - plug_spring_thickness - 1.4, 1.5],
      [hswx_inside - plug_spring_base + .1, hswx_depth - plug_spring_thickness - 0.1, 1.0],

      [hswx_inside / 2, hswx_depth - plug_spring_depth - plug_spring_thickness, 6.0],

      [plug_spring_base, hswx_depth - plug_spring_thickness, 2.0],
      [plug_stud_thickness, hswx_depth / 3, 1.0],
      [hswx_inside / 3.4, 0],
      [plug_stud_thickness, 0],
    ],
  ];

  translate(center ? [0, 0, 0] : [hswx_inside / 2, hswx_inside / 4, 0])
    rotate([0, 0, rotate])
      union() {
        translate([-hswx_inside / 2, -hswx_inside / 4, 0])
          rotate([-90, 0, 0])
            linear_extrude(hswx_inside / 2)
              polygon(round_corners(path=points(outline[type]), radius=rads(outline[type]), $fn=90));
        if (hexbase) {
          cyl(l=hexbase, d=hswx_od - 1, $fn=6, anchor=BOTTOM, spin=30, rounding2=hexbase / 2);
        }
        if (rectbase) {
          //rounding
          cuboid(size=[hswx_outside, hswx_inside / 2, rectbase], rounding=rectbase / 2, edges=[TOP + LEFT, TOP + RIGHT], anchor=BOTTOM + CENTER);
        }
      }
}

// hsw_clip(center=true, rotate=0); //, type=0, hexbase=3);
if (generate_clipconnector)
  rotate([90, 0, 0])
    hsw_clipconnector(slop=0.05, rectbase=generate_clip_rect_base ? 3 : 0, hexbase=generate_clip_hex_base ? 3 : 0);

if (generate_clip)
  hsw_clip(center=true, rectbase=generate_clip_rect_base ? 3 : 0, hexbase=generate_clip_hex_base ? 3 : 0);
