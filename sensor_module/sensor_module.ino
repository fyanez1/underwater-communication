// --- CONFIG ---
const int speakerPin = 9;       // Use PWM-capable pin or DAC output
const int bitDuration = 20;     // in milliseconds
const int toneFreq = 500;      // Hz for bit '1'

// Sensor types
#define TEMP_TYPE 0b00
#define COND_TYPE 0b01
#define PRES_TYPE 0b10

int sensorType = TEMP_TYPE;     // For testing

#include "DFRobot_EC.h"
#include <EEPROM.h>

#define COND_PIN A1
float voltage,ecValue,temperature = 25;
DFRobot_EC ec;


#include <OneWire.h>
#include <DallasTemperature.h>

// Red connects to 3-5V, 
// Blue/Black connects to ground 
// Yellow/White is data

// Data wire plugged into digital pin 2
#define TEMP_PIN 2

OneWire oneWire(TEMP_PIN);	

DallasTemperature sensors(&oneWire);

const int buttonPin = 12;  // the number of the pushbutton pin
int buttonState = 0;  // variable for reading the pushbutton status


// --- FUNCTIONS ---
void sendBit(bool bit) {
  if (bit) {
    tone(speakerPin, toneFreq); // Send tone for 1
  } else {
    noTone(speakerPin);         // Silence for 0
  }
  delay(bitDuration);
}

void sendBits(int byte, int numBits) {
  for (int i = numBits - 1; i >= 0; i--) {
    sendBit((byte >> i) & 0x1);
  }
}

void sendPacket(uint16_t tempReading, uint16_t condReading) {
  uint16_t checksum = tempReading ^ condReading;
  Serial.println("PRE-AMBLE: 10101010");
  Serial.println("DELIM: 11110000");
  Serial.print("TEMP: ");
  Serial.println(tempReading, BIN);
  Serial.print("COND: ");
  Serial.println(condReading, BIN);
  Serial.print("CHECKSUM: ");
  Serial.println(checksum, BIN);
  Serial.println(checksum);

  // sendBits(1, 1);


  // Send packet: [Preamble, Start, Type + Data, Checksum]
  sendBits(0xAA, 8);                // Preamble: 10101010
  sendBits(0xF0, 8);                // Start Delimiter: 11110000
  sendBits(tempReading, 16);
  sendBits(condReading, 16);
  sendBits(checksum, 16);           // Checksum
}

float readTemperature()
{
  sensors.requestTemperatures(); 
  return sensors.getTempCByIndex(0);
}

// --- MAIN LOOP ---
void setup() {
  pinMode(speakerPin, OUTPUT);

  pinMode(buttonPin, INPUT_PULLUP);

  sensors.begin();
  Serial.begin(115200);  
  ec.begin();
}

void loop() {
  // buttonState = digitalRead(buttonPin);

  // // if pressed:
  // if (buttonState == HIGH) { // change to LOW
  //   static unsigned long timepoint = millis();
  //   if(millis()-timepoint>1000U)  //time interval: 1s
  //   {
  //     timepoint = millis();
  //     voltage = analogRead(COND_PIN)/1024.0*5000;   // read the voltage
  //     temperature = readTemperature();          // read your temperature sensor to execute temperature compensation
  //     ecValue =  ec.readEC(voltage,temperature);  // convert voltage to EC with temperature compensation
  //     Serial.print("temperature:");
  //     Serial.print(temperature,1);
  //     Serial.print("^C  EC:");
  //     Serial.print(ecValue,2);
  //     Serial.println("ms/cm");
  //   }
  //   ec.calibration(voltage,temperature);          // calibration process by Serail CMD

    
    uint16_t tempScaled = 21 * 100;//temperature * 100;                // Scale to 14-bit range (0–16368)
    uint16_t condScaled = 4 * 100;//ecValue * 100;                // Scale to 14-bit range (0–16368)

    sendPacket(tempScaled, condScaled);                        // Transmit packet
  //   // delay(3000);                               // 1 reading every 3 seconds
  // } else {
  // }
}


