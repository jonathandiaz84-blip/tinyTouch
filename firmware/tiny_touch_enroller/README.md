# tinyTouch fingerprint enrollment utility

The production HID and PIV firmwares search fingerprint template slots 1-5 but do not enroll them. Flash this temporary Arduino sketch first, enroll templates, verify them, then replace it with the PIV firmware.

XIAO ESP32-S3 wiring is identical to the production firmware:

- D6 / GPIO43 -> sensor RX
- D7 / GPIO44 <- sensor TX
- D1 / GPIO2 <- sensor TOUCH_OUT
- 3V3 -> sensor V_SENSOR and VCC
- GND -> sensor GND

Open Serial Monitor at 115200 baud. Commands:

```text
e 1   enroll slot 1
e 2   enroll slot 2
v     scan and verify against slots 1-5
d 3   delete slot 3
h     help
```

Enroll the primary finger twice at natural desk angles in slots 1 and 2 and a backup finger in slot 3. This utility uses the common ZW101 `0xEF01` protocol commands. Marketplace variants can differ; stop if the sensor does not pass verification.

This sketch has been source-reviewed with the upstream packet implementation but cannot be hardware-validated without the physical sensor.
