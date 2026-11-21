// BOSL2 helper functions

// round_corners() helper
// to define points and rads together, use these two functions
function points(radpath) =
    [for (i = [0:len(radpath) - 1]) [for (j = [0:1]) radpath[i][j]]];
function rads(radpath) =
    [for (i = [0:len(radpath) - 1]) (len(radpath[i]) <= 2) ? 0 : radpath[i][2]];
