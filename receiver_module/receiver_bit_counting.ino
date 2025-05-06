#include <TimerOne.h>

const int hydrophonePin = A6;     // Analog pin from hydrophone
const int hydrophonePin2 = A7;     // Analog pin from hydrophone
const int bitDuration = 30;       // Bit duration in milliseconds
const int duration = ((bitDuration/1000 * 64 + 1) * 2);       // total duration
const int sampleRate = 4 * (500);
int numWrong = 0;
int numPacketsWrong = 0;
int total = 0;

const int chunkSize = 60; // int(sampleRate * bitDuration/1000.0);
const int BIT_BUFFER_SIZE = 390; // duration * sampleRate / chunkSize
bool bitBuffer[390];
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
  if (bufferFull) {
    return;
  }
  int val = analogRead(hydrophonePin2) - analogRead(hydrophonePin);
  if (val < 0) val = -val;

  if (val != 0) {
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

int numBitErrors(int a, int b) {
  unsigned long xorResult = a ^ b;
  int count = 0;
  while (xorResult > 0) {
    if (xorResult & 1) {
      count++;
    }
    xorResult >>= 1;
  }
  return count;
}

void setup() {
  Serial.begin(115200);
  pinMode(hydrophonePin, INPUT);
  pinMode(hydrophonePin2, INPUT);
  Timer1.initialize(500);
  Timer1.attachInterrupt(sampleISR);
  Serial.println("Underwater acoustic receiver started");
}

bool isOneBitAway(uint8_t a, uint8_t b) {
  uint8_t diff = a ^ b;  // XOR gives 1s where bits differ
  // return diff && !(diff & (diff - 1));
  return diff == 0 || !(diff & (diff - 1));
}
 

void loop() {
  if (bufferFull) {
    noInterrupts();  // prevent update during copy
    // Serial.println("buffer full");

    if (total > 5) {
      Serial.println("number wrong:");
      Serial.println(numWrong);
      Serial.println(numPacketsWrong);
    }

    // for (int i = 0; i < BIT_BUFFER_SIZE - 63; i++) {
    //   Serial.print(bitBuffer[i]);
    // }
    
    for (int i = 0; i < BIT_BUFFER_SIZE - 63; i++) {
      if (total > 5) {
        break;
      }
      if (isOneBitAway(readBitsFromBuffer(8, i), preamble)) {
        if (readBitsFromBuffer(8, i+8) == 0xF0) { // Check for start delimiter
          // Serial.println("Preamble detected!");
          uint16_t tempReading = readBitsFromBuffer(16, i + 16);
          uint16_t condReading = readBitsFromBuffer(16, i + 32);
          uint16_t receivedChecksum = readBitsFromBuffer(16, i + 48);
          
          uint16_t calculatedChecksum = tempReading ^ condReading;
          // Serial.println("checksums");
          // Serial.println(receivedChecksum);
          // Serial.println(calculatedChecksum);
          
          if (calculatedChecksum == receivedChecksum) {
            float temperature = tempReading / 100.0;
            float conductivity = condReading / 100.0;
            
            // Serial.println("Valid packet received!");
            // Serial.print("Temperature: ");
            // Serial.print(temperature);
            // Serial.println("°C");
            // Serial.print("Conductivity: ");
            // Serial.print(conductivity);
            // Serial.println(" ms/cm");
          }
          int sum = 0;
          sum += numBitErrors(readBitsFromBuffer(8, i + 8), 0xF0); // start delimiter reading
          sum += numBitErrors(tempReading, 0x834); // temp reading
          sum += numBitErrors(condReading, 0x190); // cond reading
          sum += numBitErrors(calculatedChecksum, 0x9A4); // checksum reading
          if (sum != 0) {
            numPacketsWrong += 1;
          }
          numWrong += sum;
          total += 1;
          Serial.println(numWrong);
          Serial.println("SUM");
          Serial.println(sum);
        }
      }
    }
    bufferFull = false;
    writeIndex = 0;
    interrupts();  // resume interrupts
  }
}
