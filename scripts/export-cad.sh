#!/bin/zsh
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="${1:-$repo_dir/build/cad}"

if ! command -v openscad >/dev/null 2>&1; then
  print -u2 "OpenSCAD is required."
  exit 2
fi

mkdir -p "$output_dir"
openscad -o "$output_dir/jd_desk_hub_v1_base.stl" -D 'part="base"' "$repo_dir/cad/jd_desk_hub_v1.scad"
openscad -o "$output_dir/jd_desk_hub_v1_top.stl" -D 'part="top"' "$repo_dir/cad/jd_desk_hub_v1.scad"
openscad -o "$output_dir/jd_desk_hub_sensor_fit_coupon.stl" "$repo_dir/cad/sensor_fit_coupon.scad"
openscad -o "$output_dir/jd_desk_hub_rail_adapter.stl" "$repo_dir/cad/rail_adapter.scad"
print "Exported CAD to $output_dir"
