/*
JD Desk Hub v1 - parametric enclosure concept

This is a fit-first starting model, not a production drawing. Measure the actual
ZW101, harness, XIAO, solder joints, and Creator Rail before final printing.

part = "top", "base", "assembly", or "all"
Units: millimeters
*/

$fn = 96;
part = "all";

body_w = 52;
body_d = 44;
base_h = 8;
top_h = 10;
corner_r = 5;
wall = 2.0;
floor = 2.0;
top_skin = 2.0;
seam_clearance = 0.25;

// ZW101 nominal outer diameter is 21.0 mm. Start with 0.20 mm radial clearance.
sensor_od = 21.0;
sensor_clearance = 0.20;
sensor_bore = sensor_od + 2 * sensor_clearance;
sensor_center = [0, -5];
sensor_reveal_lip = 0.45;

// XIAO nominal plan dimensions are 21 x 17.8 mm.
xiao_w = 21.0;
xiao_d = 17.8;
xiao_clearance = 0.35;
xiao_center = [0, 9];

usb_opening_w = 11.0;
usb_opening_h = 5.0;
usb_center_x = 0;

// Select an insert first, then set this from its supplier drawing and coupon.
insert_bore = 3.7;
insert_depth = 4.6;
boss_od = 7.0;
screw_clearance = 2.9;
screw_head_d = 5.2;
screw_head_h = 1.8;
screw_xy = [[-19,-15],[19,-15],[-19,15],[19,15]];

magnet_d = 10.2;
magnet_depth = 3.0;
magnet_xy = [[-17,-12],[17,-12],[-17,12],[17,12]];

module rounded_prism(w, d, h, r) {
    linear_extrude(height=h)
        offset(r=r)
            square([w - 2*r, d - 2*r], center=true);
}

module shell_cavity(w, d, h, r, side_wall) {
    rounded_prism(w - 2*side_wall, d - 2*side_wall, h, max(r-side_wall, 0.8));
}

module base_part() {
    difference() {
        union() {
            rounded_prism(body_w, body_d, base_h, corner_r);

            // Low standoffs locate the XIAO without gripping the RF shield.
            for (x=[-xiao_w/2-1.2, xiao_w/2+1.2])
                for (y=[xiao_center[1]-xiao_d/2+1.8, xiao_center[1]+xiao_d/2-1.8])
                    translate([x, y, floor]) cylinder(d=3.0, h=2.0);
        }

        // Main electronics cavity.
        translate([0,0,floor])
            shell_cavity(body_w, body_d, base_h-floor+0.2, corner_r, wall);

        // Re-add localized board clearance by removing a shallow pocket.
        translate([xiao_center[0], xiao_center[1], floor-0.01])
            cube([xiao_w+2*xiao_clearance, xiao_d+2*xiao_clearance, 3.2], center=true);

        // Rear USB-C access and insertion lead-in.
        translate([usb_center_x, body_d/2-wall/2, floor+usb_opening_h/2])
            cube([usb_opening_w, wall+1.0, usb_opening_h], center=true);
        translate([usb_center_x, body_d/2+0.01, floor+usb_opening_h/2])
            rotate([90,0,0]) cylinder(h=1.0, r1=usb_opening_w/2+1.0, r2=usb_opening_w/2, center=false);

        // Underside screw and head clearances.
        for (p=screw_xy) {
            translate([p[0],p[1],-0.1]) cylinder(d=screw_head_d, h=screw_head_h+0.2);
            translate([p[0],p[1],screw_head_h-0.1]) cylinder(d=screw_clearance, h=base_h+0.3);
        }

        // Optional open magnet pockets. Use the rail plate instead for a non-magnetic build.
        for (p=magnet_xy)
            translate([p[0],p[1],-0.1]) cylinder(d=magnet_d, h=magnet_depth+0.1);
    }
}

module top_part() {
    difference() {
        union() {
            rounded_prism(body_w, body_d, top_h, corner_r);

            // Insert bosses descend from the top skin into the cavity.
            for (p=screw_xy)
                translate([p[0],p[1],0]) cylinder(d=boss_od, h=top_h-top_skin);
        }

        // Hollow from the seam side, leaving the top skin.
        translate([0,0,-0.1])
            shell_cavity(body_w-2*seam_clearance, body_d-2*seam_clearance,
                         top_h-top_skin+0.1, corner_r, wall);

        // Sensor opening with a shallow lead-in at the touch face.
        translate([sensor_center[0],sensor_center[1],-0.1])
            cylinder(d=sensor_bore, h=top_h+0.2);
        translate([sensor_center[0],sensor_center[1],top_h-sensor_reveal_lip])
            cylinder(d1=sensor_bore, d2=sensor_bore+1.2, h=sensor_reveal_lip+0.1);

        // Insert bores. Heat-set from the seam side before assembly.
        for (p=screw_xy)
            translate([p[0],p[1],-0.1]) cylinder(d=insert_bore, h=insert_depth+0.1);

        // Quiet underside maker mark; replace text only after fit validation.
        translate([0, 14, top_h-0.45])
            linear_extrude(height=0.5)
                text("JD", size=4.0, halign="center", valign="center",
                     font="Arial:style=Bold");
    }
}

module assembly_view() {
    color([0.08,0.08,0.09]) base_part();
    color([0.12,0.12,0.13]) translate([0,0,base_h]) top_part();
    color([0.18,0.18,0.18])
        translate([sensor_center[0],sensor_center[1],base_h+top_h-0.8])
            cylinder(d=sensor_od, h=0.9);
}

if (part == "base") base_part();
else if (part == "top") top_part();
else if (part == "assembly") assembly_view();
else {
    translate([-body_w/2-4,0,0]) base_part();
    translate([ body_w/2+4,0,0]) top_part();
}
