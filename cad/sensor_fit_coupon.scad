/* ZW101 bore and M2.5 heat-set insert fit coupon. Units: mm. */
$fn = 96;

sensor_od = 21.0;
clearances = [0.10, 0.15, 0.20, 0.25, 0.30]; // radial clearance
insert_bores = [3.4, 3.5, 3.6, 3.7, 3.8];
plate_t = 3.0;
cell = 28;

difference() {
    cube([cell*len(clearances), 38, plate_t]);
    for (i=[0:len(clearances)-1]) {
        translate([cell*(i+0.5), 14, -0.1])
            cylinder(d=sensor_od+2*clearances[i], h=plate_t+0.2);
        translate([cell*(i+0.5), 31, -0.1])
            cylinder(d=insert_bores[i], h=plate_t+0.2);
    }
}

for (i=[0:len(clearances)-1]) {
    translate([cell*(i+0.5), 2.5, plate_t])
        linear_extrude(0.5)
            text(str("c", clearances[i], " b", insert_bores[i]), size=3,
                 halign="center", font="Arial:style=Bold");
}
