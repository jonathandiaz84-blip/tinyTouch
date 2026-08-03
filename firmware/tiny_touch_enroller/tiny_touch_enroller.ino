#include <Arduino.h>

static const uint32_t FP_BAUD = 57600;
static const int FP_TX_PIN = 43; // XIAO D6 -> sensor RX
static const int FP_RX_PIN = 44; // XIAO D7 <- sensor TX
static const int FP_INT_PIN = 2; // XIAO D1 <- sensor TOUCH_OUT
static const uint16_t START_SLOT = 1;
static const uint16_t END_SLOT = 5;

HardwareSerial Finger(1);

static uint16_t checksum(uint8_t packetId, const uint8_t *payload, size_t payloadLen) {
  uint16_t length = payloadLen + 2;
  uint32_t total = packetId + (length >> 8) + (length & 0xff);
  for (size_t i = 0; i < payloadLen; ++i) total += payload[i];
  return (uint16_t)total;
}

static bool command(uint8_t instruction, const uint8_t *params, size_t paramLen,
                    uint8_t *confirm, uint8_t *data = nullptr,
                    size_t *dataLen = nullptr, uint32_t timeoutMs = 2500) {
  while (Finger.available()) Finger.read();
  const size_t capacity = (data && dataLen) ? *dataLen : 0;
  if (dataLen) *dataLen = 0;

  uint8_t payload[32];
  if (paramLen + 1 > sizeof(payload)) return false;
  payload[0] = instruction;
  if (paramLen) memcpy(payload + 1, params, paramLen);
  const size_t payloadLen = paramLen + 1;
  const uint16_t length = payloadLen + 2;
  const uint16_t sum = checksum(0x01, payload, payloadLen);

  const uint8_t header[] = {
    0xef, 0x01, 0xff, 0xff, 0xff, 0xff, 0x01,
    (uint8_t)(length >> 8), (uint8_t)(length & 0xff)
  };
  Finger.write(header, sizeof(header));
  Finger.write(payload, payloadLen);
  Finger.write((uint8_t)(sum >> 8));
  Finger.write((uint8_t)(sum & 0xff));

  uint8_t response[96];
  size_t pos = 0;
  uint32_t started = millis();
  while (millis() - started < timeoutMs) {
    while (Finger.available() && pos < sizeof(response)) response[pos++] = Finger.read();
    while (pos >= 2 && !(response[0] == 0xef && response[1] == 0x01)) {
      memmove(response, response + 1, --pos);
    }
    if (pos >= 9) {
      const uint16_t responseLength = ((uint16_t)response[7] << 8) | response[8];
      const size_t expected = 9 + responseLength;
      if (pos >= expected) {
        if (response[6] != 0x07 || responseLength < 3) return false;
        *confirm = response[9];
        const size_t actual = responseLength - 3;
        if (data && dataLen && actual) {
          const size_t copyLen = min(actual, capacity);
          memcpy(data, response + 10, copyLen);
          *dataLen = copyLen;
        }
        return true;
      }
    }
    delay(5);
  }
  return false;
}

static bool verifySensor() {
  uint8_t params[] = {0, 0, 0, 0};
  uint8_t confirm = 0xff;
  return command(0x13, params, sizeof(params), &confirm) && confirm == 0x00;
}

static bool captureToBuffer(uint8_t bufferId) {
  uint8_t confirm = 0xff;
  Serial.println("Place finger flat on sensor...");
  uint32_t deadline = millis() + 15000;
  while ((int32_t)(deadline - millis()) > 0) {
    if (command(0x01, nullptr, 0, &confirm, nullptr, nullptr, 1000) && confirm == 0x00) {
      uint8_t params[] = {bufferId};
      if (command(0x02, params, sizeof(params), &confirm) && confirm == 0x00) return true;
      Serial.printf("Image conversion failed: 0x%02x\n", confirm);
      return false;
    }
    delay(180);
  }
  Serial.println("Timed out waiting for finger.");
  return false;
}

static void waitForRemoval() {
  uint8_t confirm = 0xff;
  Serial.println("Remove finger...");
  uint32_t deadline = millis() + 10000;
  while ((int32_t)(deadline - millis()) > 0) {
    if (command(0x01, nullptr, 0, &confirm, nullptr, nullptr, 700) && confirm != 0x00) {
      delay(500);
      return;
    }
    delay(150);
  }
}

static bool enroll(uint16_t slot) {
  if (slot < START_SLOT || slot > END_SLOT) {
    Serial.println("Slot must be 1-5.");
    return false;
  }
  if (!captureToBuffer(0x01)) return false;
  waitForRemoval();
  Serial.println("Place the same finger again at a slightly different angle.");
  if (!captureToBuffer(0x02)) return false;

  uint8_t confirm = 0xff;
  if (!command(0x05, nullptr, 0, &confirm) || confirm != 0x00) {
    Serial.printf("Template merge failed: 0x%02x\n", confirm);
    return false;
  }
  uint8_t storeParams[] = {0x01, (uint8_t)(slot >> 8), (uint8_t)(slot & 0xff)};
  if (!command(0x06, storeParams, sizeof(storeParams), &confirm) || confirm != 0x00) {
    Serial.printf("Template store failed: 0x%02x\n", confirm);
    return false;
  }
  Serial.printf("Enrollment complete in slot %u.\n", slot);
  return true;
}

static bool deleteSlot(uint16_t slot) {
  if (slot < START_SLOT || slot > END_SLOT) return false;
  uint8_t params[] = {
    (uint8_t)(slot >> 8), (uint8_t)(slot & 0xff), 0x00, 0x01
  };
  uint8_t confirm = 0xff;
  const bool ok = command(0x0c, params, sizeof(params), &confirm) && confirm == 0x00;
  Serial.printf(ok ? "Deleted slot %u.\n" : "Delete failed for slot %u (0x%02x).\n",
                slot, confirm);
  return ok;
}

static bool verifyMatch() {
  if (!captureToBuffer(0x01)) return false;
  const uint16_t count = END_SLOT - START_SLOT + 1;
  uint8_t params[] = {
    0x01,
    (uint8_t)(START_SLOT >> 8), (uint8_t)(START_SLOT & 0xff),
    (uint8_t)(count >> 8), (uint8_t)(count & 0xff)
  };
  uint8_t data[4];
  size_t dataLen = sizeof(data);
  uint8_t confirm = 0xff;
  if (!command(0x04, params, sizeof(params), &confirm, data, &dataLen) ||
      confirm != 0x00 || dataLen != 4) {
    Serial.printf("No match (confirm=0x%02x).\n", confirm);
    return false;
  }
  uint16_t slot = ((uint16_t)data[0] << 8) | data[1];
  uint16_t score = ((uint16_t)data[2] << 8) | data[3];
  Serial.printf("Match: slot=%u score=%u\n", slot, score);
  return score > 0;
}

static void help() {
  Serial.println("Commands: e 1..5 enroll | v verify | d 1..5 delete | h help");
}

void setup() {
  Serial.begin(115200);
  Finger.begin(FP_BAUD, SERIAL_8N1, FP_RX_PIN, FP_TX_PIN);
  pinMode(FP_INT_PIN, INPUT_PULLDOWN);
  delay(1800);
  Serial.println("JD Desk Hub / tinyTouch enrollment utility");
  Serial.println(verifySensor() ? "Sensor verified." : "SENSOR VERIFY FAILED - check 3.3 V wiring and model.");
  help();
}

void loop() {
  if (!Serial.available()) return;
  String line = Serial.readStringUntil('\n');
  line.trim();
  if (!line.length()) return;
  char op = tolower(line[0]);
  uint16_t slot = line.length() > 1 ? (uint16_t)line.substring(1).toInt() : 0;
  if (op == 'e') enroll(slot);
  else if (op == 'd') deleteSlot(slot);
  else if (op == 'v') verifyMatch();
  else help();
}
