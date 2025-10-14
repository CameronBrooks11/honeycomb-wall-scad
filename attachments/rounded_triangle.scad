// rounded_triangle.scad — modularized, mathematically tangent version
// -------------------------------------------------------------

$fn = 64; // Smoothness of circles

// =============================================================
// Modules
// =============================================================

// Main module: triangle with smooth semicircular tip
module rounded_triangle(base, height, tip_dia) {
  r = tip_dia / 2;
  circle_center = [base / 2, height - r];

  // Compute tangent points to ensure perfect tangency
  T_left = tangent_point(circle_center, r, [0, 0], +1);
  T_right = tangent_point(circle_center, r, [base, 0], -1);

  union() {
    polygon(points=[[0, 0], [base, 0], T_right, T_left]);
    translate(circle_center)
      circle(r=r);
  }
}

// Utility: find tangent point on circle from external point
// side = +1 (left tangent), -1 (right tangent)
function tangent_point(center, radius, ext_point, side = 1) =
  let (
    v = center - ext_point,
    L = norm(v),
    s = radius / L,
    a = sqrt(L * L - radius * radius),
    c = a / L,
    rot = [
      [c, -side * s],
      [side * s, c],
    ]
  ) ext_point + rot * (a * (v / L));

// =============================================================
// Parameters
// =============================================================
triangle_height = 23;
triangle_base = 11;
tip_diameter = 2;

// =============================================================
// Main build
// =============================================================
rounded_triangle(triangle_base, triangle_height, tip_diameter);
