#include <ArduinoBLE.h>

BLEService customService("180C"); // Custom service UUID
BLECharacteristic stringCharacteristic("2A1C", BLERead | BLENotify, 100); // Max 100 bytes

void setup() {
  Serial.begin(115200);
  Serial1.begin(115200);
  if (!BLE.begin()) {
    Serial.println("BLE initialization failed!");
    while (1);
  }

  BLE.setLocalName("Nano33IoT");
  BLE.setAdvertisedService(customService);

  customService.addCharacteristic(stringCharacteristic);
  BLE.addService(customService);

  // stringCharacteristic.writeValue("Starting up...");

  BLE.advertise();
  Serial.println("BLE device is now advertising");
}

bool isValidNumber(String s) {
  if (s.length() == 0) return false;

  int start = 0;
  if (s[0] == '-') {
    if (s.length() == 1) return false; // just "-"
    start = 1;
  }

  bool hasDot = false;
  for (int i = start; i < s.length(); i++) {
    if (s[i] == '.') {
      if (hasDot) return false; // second dot → invalid
      hasDot = true;
    } else if (!isDigit(s[i])) {
      return false;
    }
  }

  // Dot cannot be first or last
  if (s[0] == '.' || s[s.length() - 1] == '.') return false;
  if (s == "-.") return false;

  return true;
}

bool checkData(String val) {
  int sepIndex = val.indexOf('|');
  
  if (sepIndex <= 0 || sepIndex >= val.length() - 1) return false;

  String left = val.substring(0, sepIndex);
  String right = val.substring(sepIndex + 1);

  return isValidNumber(left) && isValidNumber(right);
}

void loop() {
  if (Serial1.available()) {
    Serial.println("Serial available");
    String msg = Serial1.readStringUntil('\n');
    
    if (checkData(msg)) {
      stringCharacteristic.writeValue(msg.c_str());
      BLE.advertise();

      Serial.println("Sent: " + msg);
    } else {
      Serial.println("Invalid " + msg);
    }
  }
}

