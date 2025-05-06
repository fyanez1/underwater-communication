#include <TimerOne.h>

const int hydrophonePin = A6;     // Analog pin from hydrophone
const int hydrophonePin2 = A7;     // Analog pin from hydrophone
const int bitDuration = 30;       // Bit duration in milliseconds
const int duration = ((bitDuration/1000 * 16 + 1) * 2);       // total duration
const int sampleRate = 2 * (500 + 100);

const int chunkSize = 66; // int(sampleRate * bitDuration/1000.0);
const int BIT_BUFFER_SIZE = 99;
bool bitBuffer[99];
volatile int writeIndex = 0;
bool bufferFull = false;

volatile int ones = 0;
volatile int zeros = 0;
volatile int chunkRead = 0;

// Preamble
const uint8_t preamble = 0xAA;    // 10101010
const int preambleLength = 8;     // 8 bits

// Envelope detection parameters
const int envelopeThreshold = 20; // Adjust experimentally

// Helper: Read ADC and apply envelope detection
bool readEnvelope() {
  int val = abs(analogRead(hydrophonePin2) - analogRead(hydrophonePin)); // Center around 0
  // return abs(val); // Simple envelope: absolute value
  return abs(val) > envelopeThreshold;
}

void sampleISR() {
  // Inline envelope detection
  int val = analogRead(hydrophonePin2) - analogRead(hydrophonePin);
  if (val < 0) val = -val;

  if (val > envelopeThreshold) {
    ones++;
  } else {
    zeros++;
  }

  if (++chunkRead == chunkSize) {
    bitBuffer[writeIndex++] = ones > zeros;
    chunkRead = 0;
    ones = 0;
    zeros = 0;

    if (writeIndex == BIT_BUFFER_SIZE) {
      bufferFull = true;
    }
  }
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

uint64_t readBitsFromBuffer(int numBits, int startIndex) {
  uint64_t value = 0;
  for (int i = 0; i < numBits; i++) {
    value <<= 1;
    if (bitBuffer[startIndex + i]) {
      value |= 1;
    }
  }
  return value;
}

void setup() {
  Serial.begin(115200);
  pinMode(hydrophonePin, INPUT);
  pinMode(hydrophonePin2, INPUT);
  Timer1.initialize(sampleRate);
  Timer1.attachInterrupt(sampleISR);
  Serial.println("Underwater acoustic receiver started");
}

bool isOneBitAway(uint8_t a, uint8_t b) {
  uint8_t diff = a ^ b;  // XOR gives 1s where bits differ
  return diff && !(diff & (diff - 1));
}
 

void loop() {
  if (bufferFull) {
    noInterrupts();  // prevent update during copy
    
    for (int i = 0; i < BIT_BUFFER_SIZE - 63; i++) {
      if (isOneBitAway(readBitsFromBuffer(8, i), preamble)) {
        if (readBitsFromBuffer(8, i+8) == 0xF0) { // Check for start delimiter
          Serial.println("Preamble detected!");
          uint16_t tempReading = readBitsFromBuffer(16, i + 16);
          uint16_t condReading = readBitsFromBuffer(16, i + 32);
          uint16_t receivedChecksum = readBitsFromBuffer(16, i + 48);
          
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
          }
        }
      }
    }
    bufferFull = false;
    writeIndex = 0;
    interrupts();  // resume interrupts
  }
}
