/*
Creator Rail interface plate - PARAMETRIC PLACEHOLDER

Replace rail_width, lip geometry, and locating features from the actual rail
cross-section. The puck-side interface is a stable 40 x 20 mm four-point grid.
*/
$fn = 72;

plate_w = 48;
plate_d = 36;
plate_t = 3.0;
corner_r = 4;

puck_grid_x = 40;
puck_grid_y = 20;
puck_hole_d = 3.0;

magnet_d = 10.2;
magnet_depth = 2.8;

rail_width = 24;     // MEASURE ACTUAL RAIL
rail_lip = 2.0;      // MEASURE ACTUAL RAIL
rail_capture = 1.2;  // MEASURE / TEST

module rounded_plate(w,d,h,r) {
    linear_extrude(h)
        offset(r=r)
            square([w-2*r,d-2*r],center=true);
}

difference() {
    union() {
        rounded_plate(plate_w, plate_d, plate_t, corner_r);

        // Placeholder rail jaws. Replace with imported/published rail profile.
        translate([-rail_width/2-rail_lip, -plate_d/2, plate_t])
            cube([rail_lip, plate_d, rail_capture]);
        translate([rail_width/2, -plate_d/2, plate_t])
            cube([rail_lip, plate_d, rail_capture]);
    }

    // Puck-side four-point mechanical grid.
    for (x=[-puck_grid_x/2,puck_grid_x/2])
        for (y=[-puck_grid_y/2,puck_grid_y/2])
            translate([x,y,-0.1]) cylinder(d=puck_hole_d,h=plate_t+0.2);

    // Optional magnet pockets.
    for (x=[-16,16])
        for (y=[-10,10])
            translate([x,y,-0.1]) cylinder(d=magnet_d,h=magnet_depth+0.1);
}
