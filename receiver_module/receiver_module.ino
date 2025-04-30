const int hydrophonePin = A0;     // Analog pin from hydrophone
const int bitDuration = 10;       // Bit duration in milliseconds
const int samplesPerBit = 3;      // Number of samples per bit
const int sampleInterval = 3000;  // Sample interval in microseconds (~333 Hz)

// Preamble
const uint8_t preamble = 0xAA;    // 10101010
const int preambleLength = 8;     // 8 bits

// Envelope detection parameters
const int envelopeThreshold = 20; // Adjust experimentally

// Helper: Read ADC and apply envelope detection
int readEnvelope() {
  int val = analogRead(hydrophonePin) - 512; // Center around 0
  return abs(val); // Simple envelope: absolute value
}

// Read one bit by majority voting
bool readBit() {
  int ones = 0;
  for (int i = 0; i < samplesPerBit; i++) {
    int env = readEnvelope();
    if (env > envelopeThreshold) ones++;
    delayMicroseconds(sampleInterval);
  }
  return (ones >= (samplesPerBit + 1) / 2); // Majority
}

// Correlate last N bits with preamble
bool correlatePreamble(uint8_t window) {
  uint8_t diff = window ^ preamble;
  int bitErrors = 0;
  for (int i = 0; i < preambleLength; i++) {
    if (diff & (1 << i)) bitErrors++;
  }
  return bitErrors <= 1; // Allow 1 bit error
}

// Read multiple bits as unsigned integer
uint16_t readBits(int numBits) {
  uint16_t value = 0;
  for (int i = 0; i < numBits; i++) {
    value <<= 1;
    if (readBit()) value |= 1;
  }
  return value;
}

void setup() {
  Serial.begin(115200);
  pinMode(hydrophonePin, INPUT);
  Serial.println("Underwater acoustic receiver started");
}

void loop() {
  uint8_t window = 0;

  // 1. Look for preamble via correlation
  while (true) {
    window = (window << 1) | (readBit() ? 1 : 0);
    if (correlatePreamble(window)) {
      Serial.println("Preamble detected!");
      break;
    }
  }

  // 2. Read start delimiter
  uint8_t startDelimiter = readBits(8);
  if (startDelimiter != 0xF0) {
    Serial.println("Start delimiter mismatch. Resyncing...");
    return; // Go back to listening
  }

  // 3. Read packet fields according to the sensor module protocol
  uint16_t tempReading = readBits(16);
  uint16_t condReading = readBits(16);
  uint16_t receivedChecksum = readBits(16);

  // 4. Calculate and validate checksum
  uint16_t calculatedChecksum = tempReading ^ condReading;
  
  if (calculatedChecksum == receivedChecksum) {
    float temperature = tempReading / 100.0;
    float conductivity = condReading / 100.0;
    
    Serial.println("Valid packet received!");
    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println("°C");
    Serial.print("Conductivity: ");
    Serial.print(conductivity);
    Serial.println(" ms/cm");
  } else {
    Serial.println("Checksum failed. Resyncing...");
    Serial.print("Received: 0x");
    Serial.print(receivedChecksum, HEX);
    Serial.print(", Calculated: 0x");
    Serial.println(calculatedChecksum, HEX);
    return; // Go back to listening
  }
}