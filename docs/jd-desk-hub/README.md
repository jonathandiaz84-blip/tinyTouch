# JD Desk Hub v1 engineering package

Start with `IMPLEMENTATION_PLAN.md`. It contains the codebase audit, threat model, BOM, wiring, firmware and macOS instructions, enclosure requirements, automation design, acceptance test, and roadmap.

Artifacts:

- `BOM.csv` - editable purchasing sheet.
- `wiring.mmd` - editable Mermaid wiring diagram.
- `architecture.mmd` - editable Mermaid system diagram.
- `../../cad/jd_desk_hub_v1.scad` - parametric enclosure concept.
- `../../cad/sensor_fit_coupon.scad` - sensor and insert test coupon.
- `../../cad/rail_adapter.scad` - parameterized Creator Rail interface plate.
- `../../firmware/tiny_touch_enroller/` - separate fingerprint enrollment utility.
- `../../automation/` - explicit, allowlisted macOS workflow runner.
- `../../scripts/build-smartcard.sh` - reproducible build manifest helper.
- `../../scripts/diagnose-macos.sh` - read-only smart-card diagnostics.

The generated DOCX and PDF packet are release artifacts; the Markdown, CSV, Mermaid, JSON, Python, and OpenSCAD sources remain the editable system of record.
