"""Render the wall, inserts, clips and attachments, and check their geometry.

usage: python3 tests/test_hsw.py [OPENSCAD]

Each render uses --hardwarnings. A binary STL's separate solids are counted
(triangles sharing a vertex belong to the same solid), sizes are checked to
within 0.01 mm, and volumes come from the mesh.
"""

import collections
import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WALL = os.path.join(ROOT, "honeycomb-wall.scad")
INSERTS = os.path.join(ROOT, "examples", "inserts.scad")
CLIP = os.path.join(ROOT, "hsw-clips", "hsw_clip.scad")
SECTION = os.path.join(ROOT, "tests", "hole_section.scad")
FIT = os.path.join(ROOT, "tests", "insert_fit.scad")
ATT = os.path.join(ROOT, "attachments")

RESIZED = {"hsw_hole": 25, "hsw_wall": 2.5, "hsw_depth": 10}


def pieces(path):
    """[(volume, (min, max) corners)] for each separate solid in an STL."""
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    tris = [struct.unpack_from("<9f", data, 84 + i * 50 + 12) for i in range(n)]
    parent = {}

    def find(v):
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    for t in tris:
        corners = [t[0:3], t[3:6], t[6:9]]
        for c in corners:
            parent.setdefault(c, c)
        root = find(corners[0])
        for c in corners[1:]:
            parent[find(c)] = root
    vol = collections.defaultdict(float)
    pts = collections.defaultdict(list)
    for t in tris:
        p, q, r = t[0:3], t[3:6], t[6:9]
        k = find(p)
        vol[k] += (p[0] * (q[1] * r[2] - q[2] * r[1]) - p[1] * (q[0] * r[2] - q[2] * r[0])
                   + p[2] * (q[0] * r[1] - q[1] * r[0])) / 6
        pts[k] += [p, q, r]
    return [(abs(vol[k]), ([min(p[i] for p in pts[k]) for i in range(3)], [max(p[i] for p in pts[k]) for i in range(3)]))
            for k in vol]


def size(ps):
    lo = [min(b[0][i] for _, b in ps) for i in range(3)]
    hi = [max(b[1][i] for _, b in ps) for i in range(3)]
    return [h - l for l, h in zip(lo, hi)]


def render(openscad, scad, out, defines=None):
    cmd = [openscad, "--hardwarnings", "--export-format", "binstl", "-o", out]
    for name, value in (defines or {}).items():
        cmd += ["-D", f"{name}={value}"]
    return subprocess.run(cmd + [scad], capture_output=True, text=True)


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    failures = []

    def report(label, ok, got):
        print(f"{'ok  ' if ok else 'FAIL'} {label}: {got}")
        if not ok:
            failures.append(label)

    with tempfile.TemporaryDirectory() as tmp:
        stl = os.path.join(tmp, "case.stl")

        def shape(label, scad, want_solids, want_size, defines=None, want_volume=None):
            result = render(openscad, scad, stl, defines)
            if result.returncode != 0:
                report(label, False, result.stderr.strip().splitlines()[-1][:120])
                return
            ps = pieces(stl)
            got = size(ps)
            vol = sum(v for v, _ in ps)
            ok = (len(ps) == want_solids and all(abs(a - b) <= 0.01 for a, b in zip(got, want_size))
                  and (want_volume is None or abs(vol - want_volume) <= 0.1))
            report(label, ok, f"{len(ps)} solids, " + " x ".join(f"{v:.2f}" for v in got) + " mm"
                   + ("" if want_volume is None else f", {vol:.1f} mm3"))

        # The wall: filling a bed, a custom layout, flat edges, and resized. The
        # two volumes are those of the wall this one was rewritten from, which
        # matched it exactly.
        shape("wall, fill the default bed", WALL, 1, [211.19, 247.80, 8], want_volume=90272.165)
        shape("wall, example column layout", WALL, 1, [190.76, 200.60, 8], {"column_data_index": 1})
        shape("wall, all four edges flat", WALL, 1, [204.38, 247.80, 8],
              {"edge_left": "true", "edge_top": "true", "edge_right": "true", "edge_bottom": "true"},
              want_volume=102498.518)
        shape("wall, hole 25, wall 2.5, depth 10, 150 x 120 bed", WALL, 1, [138.56, 120.00, 10],
              {**RESIZED, "max_grid_width": 150, "max_grid_height": 120})

        # The hole's width across flats at four heights: the back chamfer, the
        # straight part, halfway up the widening, and the front opening.
        for z, want in ((0.05, 20.72), (3, 20), (5.55, 21), (7, 22)):
            result = render(openscad, SECTION, stl, {"Z": z})
            got = size(pieces(stl))[1] if result.returncode == 0 else -1
            report(f"hole across flats at z = {z}", abs(got - want) <= 0.01, f"{got:.2f} mm")

        # An insert seated in a cell: the lip lies on the front face and the body
        # sits in the hole, so the only overlap is the six snaps, behind the lock.
        for label, defines, lock in (("defaults", {}, 5.1), ("hole 25, wall 2.5, depth 10", RESIZED, 5.1)):
            result = render(openscad, FIT, stl, defines)
            ps = [p for p in pieces(stl) if p[0] > 0.01] if result.returncode == 0 else []
            ok = (len(ps) == 6 and all(0.5 < v < 1 for v, _ in ps)
                  and all(b[1][2] < lock for _, b in ps))
            report(f"insert seated in a cell, {label}: only the 6 snaps press in", ok,
                   f"{len(ps)} pieces, " + ", ".join(f"{v:.2f}" for v, _ in ps) + " mm3")

        # The clips follow the shared sizes.
        shape("clip", CLIP, 1, [21.89, 10, 8], {"generate_clip": "true"})
        shape("clip, hole 25", CLIP, 1, [26.89, 12.5, 8], {"generate_clip": "true", "hsw_hole": 25})

        # Insert layouts: neighbours join into one piece, separated ones don't.
        shape("inserts, the example column", INSERTS, 1, [46.42, 57.90, 10])
        shape("inserts, a dense block", INSERTS, 1, [107.73, 57.90, 10], {"layout": "[[1,1,1],[1,1],[1,1,1],[1,1]]"})
        shape("inserts, two not touching", INSERTS, 2, [107.73, 22.50, 10], {"layout": "[[1,0,1]]"})
        shape("inserts, every type", INSERTS, 1, [107.73, 46.10, 10], {"layout": "[[1,2,3],[4,5],[6,7,8]]"})

        # Attachments.
        shape("hook, filleted", os.path.join(ATT, "hook.scad"), 1, [90, 60, 144.98])
        shape("hook, chamfered", os.path.join(ATT, "hook.scad"), 1, [90, 60, 145], {"edge_style": '"chamfer"'})
        shape("plier holder", os.path.join(ATT, "plier_holder.scad"), 1, [12.72, 25, 50])
        shape("tool rack, pegs", os.path.join(ATT, "tool_holder.scad"), 1, [168, 42.41, 18.25])
        shape("tool rack, rings", os.path.join(ATT, "tool_holder.scad"), 1, [179, 35, 12], {"holder": '"ring"'})

        # A depth too shallow for the lock and the front opening is refused.
        result = render(openscad, WALL, stl, {"hsw_depth": 6})
        report("depth 6 is refused", result.returncode != 0 and "hsw_depth must be at least" in result.stderr,
               "refused" if result.returncode != 0 else "rendered")

    print("all checks passed" if not failures else f"{len(failures)} failed")
    sys.exit(1 if failures else 0)


main()
