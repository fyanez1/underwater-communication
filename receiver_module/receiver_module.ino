  const int hydrophonePin = A0;     // Analog pin from hydrophone
  const int hydrophonePin2 = A1;     // Analog pin from hydrophone
  const int bitDuration = 30;       // Bit duration in milliseconds
  const int duration = (bit_duration/1000 * 16 + 1) * 2.       // total duration
  const int samplesPerBit = 3;      // Number of samples per bit
  const int sampleInterval = 10;  // Sample interval in microseconds (100 Hz)
  const int sampleRate = 2 * (3000 + 500)

  const int BUFFER_SIZE = int(duration * sampleRate);
  bool bitBuffer[BUFFER_SIZE];
  volatile int writeIndex = 0;
  volatile int readIndex = 0;

  // Preamble
  const uint8_t preamble = 0xAA;    // 10101010
  const int preambleLength = 8;     // 8 bits

  // Envelope detection parameters
  const int envelopeThreshold = 20; // Adjust experimentally

  // Helper: Read ADC and apply envelope detection
  int readEnvelope() {
    int val = abs(analogRead(hydrophonePin2) - analogRead(hydrophonePin)); // Center around 0
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

  void fillBuffer() {
    static unsigned long lastSampleTime = 0;
    if (micros() - lastSampleTime >= (bitDuration * 1000)) {
      lastSampleTime = micros();
      bool bit = readBit();
      bitBuffer[writeIndex] = bit;
      writeIndex = (writeIndex + 1) % BUFFER_SIZE;
    }
  }

  bool bufferAvailable() {
    return readIndex != writeIndex;
  }

  bool getBufferedBit() {
    if (!bufferAvailable()) return 0;  // or wait/spin
    bool bit = bitBuffer[readIndex];
    readIndex = (readIndex + 1) % BUFFER_SIZE;
    return bit;
  }

  uint16_t readBitsFromBuffer(int numBits) {
    uint16_t value = 0;
    for (int i = 0; i < numBits; i++) {
      value <<= 1;
      if (getBufferedBit()) value |= 1;
    }
    return value;
  }

  void setup() {
    Serial.begin(115200);
    pinMode(hydrophonePin, INPUT);
    Serial.println("Underwater acoustic receiver started");
  }

  void loop() {
    fillBuffer();  // keep filling buffer

    uint8_t window = 0;

    // 1. Look for preamble via correlation
    while (bufferAvailable()) {
      bool nextBit = getBufferedBit();
      window = (window << 1) | (nextBit ? 1 : 0);
      if (correlatePreamble(window)) {
        Serial.println("Preamble detected!");
        break;
      }
    }

    if (!bufferAvailable()) return;  // not enough data yet

    // 2. Read start delimiter
    uint8_t startDelimiter = readBitsFromBuffer(8);
    if (startDelimiter != 0xF0) {
      Serial.println("Start delimiter mismatch. Resyncing...");
      return; // Go back to listening
    }

    // 3. Read packet fields according to the sensor module protocol
    uint16_t tempReading = readBitsFromBuffer(16);
    uint16_t condReading = readBitsFromBuffer(16);
    uint16_t receivedChecksum = readBitsFromBuffer(16);

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