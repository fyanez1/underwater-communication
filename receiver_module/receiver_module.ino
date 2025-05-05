  #include <TimerOne.h>

  const int hydrophonePin = A0;     // Analog pin from hydrophone
  const int hydrophonePin2 = A1;     // Analog pin from hydrophone
  const int bitDuration = 30;       // Bit duration in milliseconds
  const int duration = ((bitDuration/1000 * 16 + 1) * 2);       // total duration
  const int sampleRate = 2 * (500 + 100);

  const int chunkSize = 66; // int(sampleRate * bitDuration/1000.0);
  // const int BUFFER_SIZE = int(duration * sampleRate);
  const int BUFFER_SIZE = 2000;   
  uint8_t sampleBuffer[2000]; 
  const int BIT_BUFFER_SIZE = int(BUFFER_SIZE / chunkSize);
  bool bitBuffer[99];
  volatile int writeIndex = 0;
  volatile int bitWriteIndex = 0;
  bool bufferFull = false;

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

  void sampleISR() {
    if (bufferFull) return;
    writeIndex += 1;
    sampleBuffer[writeIndex] = readEnvelope();

    if (writeIndex >= BUFFER_SIZE) {
      bufferFull = true;
      writeIndex = 0; 
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

  void insertionSort(int arr[], int n) {
    for (int i = 1; i < n; i++) {
      int key = arr[i];
      int j = i - 1;
      while (j >= 0 && arr[j] > key) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  void processChunks() {
    Serial.println("process chunks");
    // Serial.println(BUFFER_SIZE);
    // Serial.println(chunkSize);
    for (int i = 0; i + chunkSize <= BUFFER_SIZE; i += chunkSize) {
      Serial.println("inside first loop");
      int chunk[chunkSize];
  
      // Copy chunk from sampleBuffer
      for (int j = 0; j < chunkSize; j++) {
        // Serial.println(sampleBuffer[i + j]);
        chunk[j] = sampleBuffer[i + j];
      }
  
      // Sort the chunk
      // std::sort(chunk, chunk + chunkSize);
      insertionSort(chunk, chunkSize);
  
      // Compute median
      int median;
      if (chunkSize % 2 == 1) {
        median = chunk[chunkSize / 2];
      } else {
        median = (chunk[chunkSize / 2 - 1] + chunk[chunkSize / 2]) / 2;
      }

      if (median > envelopeThreshold) {
        Serial.println("TRUE");
        bitBuffer[bitWriteIndex++] = true; // 1
      } else {
        Serial.println("FALSE");
        bitBuffer[bitWriteIndex++] = false; // 0
      }
    }
    bitWriteIndex = 0; // Reset bitWriteIndex after processing
  }

  bool isOneBitAway(uint8_t a, uint8_t b) {
    uint8_t diff = a ^ b;  // XOR gives 1s where bits differ
    return diff && !(diff & (diff - 1));
  }
   

  void loop() {
    // for (int i = 0; i < BIT_BUFFER_SIZE; i++) {
    //   Serial.println(bitBuffer[i]);
    // }
    if (bufferFull) {
      noInterrupts();  // prevent update during copy
      
      processChunks();
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
