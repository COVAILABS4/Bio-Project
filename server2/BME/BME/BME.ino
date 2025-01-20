#include <MAX3010x.h>
#include "filters.h"
#include "BluetoothSerial.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// Sensor and Constants
MAX30105 sensor;
const auto kSamplingRate = sensor.SAMPLING_RATE_400SPS;
const float kSamplingFrequency = 400.0;
const unsigned long kFingerThreshold = 10000;
const unsigned int kFingerCooldownMs = 500;
const float kEdgeThreshold = -2000.0;
const float kLowPassCutoff = 5.0;
const float kHighPassCutoff = 0.5;

// Define the screen dimensions
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64


// Create an SSD1306 object
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1); // -1 for no reset pin



// Calibration Factors
const float kSpO2_A = 1.5958422;
const float kSpO2_B = -34.6596622;
const float kSpO2_C = 112.6898759;

// Filter Instances
LowPassFilter low_pass_filter_red(kLowPassCutoff, kSamplingFrequency);
LowPassFilter low_pass_filter_ir(kLowPassCutoff, kSamplingFrequency);
HighPassFilter high_pass_filter(kHighPassCutoff, kSamplingFrequency);
Differentiator differentiator(kSamplingFrequency);
MinMaxAvgStatistic stat_red;
MinMaxAvgStatistic stat_ir;

// Variables for finger detection and heartbeat
long last_heartbeat = 0;
long finger_timestamp = 0;
float last_diff = NAN;
bool finger_detected = false;
bool crossed = false;
long crossed_time = 0;

// Bluetooth Serial
BluetoothSerial SerialBT;

// Function to initialize the sensor
void initializeSensor() {
  Serial.begin(9600);
  if (sensor.begin() && sensor.setSamplingRate(kSamplingRate)) {
    Serial.println("Sensor initialized");
  } else {
    Serial.println("Sensor not found");
    while (1);  // Halt if sensor is not found
  }

  // Initialize the SSD1306 display
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;); // Don't proceed, loop forever
  }
}


// Function to calculate Hb, waits until valid Hb value is available
double calculateHb() {
  while (true) {
    auto sample = sensor.readSample(1000);
    float current_value_red = sample.red;
    float current_value_ir = sample.ir;

    // Detect Finger using raw sensor value
    if (sample.red > kFingerThreshold) {
      if (millis() - finger_timestamp > kFingerCooldownMs) {
        finger_detected = true;
      }
    } else {
      // Reset values if the finger is removed
      differentiator.reset();
      low_pass_filter_red.reset();
      low_pass_filter_ir.reset();
      high_pass_filter.reset();
      stat_red.reset();
      stat_ir.reset();

      finger_detected = false;
      finger_timestamp = millis();
      continue;  // Restart the loop if finger is not detected
    }

    if (finger_detected) {
      current_value_red = low_pass_filter_red.process(current_value_red);
      current_value_ir = low_pass_filter_ir.process(current_value_ir);
      stat_red.process(current_value_red);
      stat_ir.process(current_value_ir);

      float current_value = high_pass_filter.process(current_value_red);
      float current_diff = differentiator.process(current_value);

      if (!isnan(current_diff) && !isnan(last_diff)) {
        if (last_diff > 0 && current_diff < 0) {
          crossed = true;
          crossed_time = millis();
        }
        if (current_diff > 0) {
          crossed = false;
        }

        if (crossed && current_diff < kEdgeThreshold) {
          if (last_heartbeat != 0 && crossed_time - last_heartbeat > 300) {
            int bpm = 60000 / (crossed_time - last_heartbeat);
            float rred = (stat_red.maximum() - stat_red.minimum()) / stat_red.average();
            float rir = (stat_ir.maximum() - stat_ir.minimum()) / stat_ir.average();
            float r = rred / rir;
            float spo2 = kSpO2_A * r * r + kSpO2_B * r + kSpO2_C;

            if (bpm > 50 && bpm < 250) {
              int POCT = (15 - (0.1 * spo2));
              double Hb = 7.5 + (0.69 * POCT);
              return Hb;  // Return the Hb value once available
            }
            stat_red.reset();
            stat_ir.reset();
          }
          crossed = false;
          last_heartbeat = crossed_time;
        }
      }
      last_diff = current_diff;
    }
  }
}


void setup() {
  initializeSensor();
  SerialBT.begin("BIO-Device"); // Initialize Bluetooth with device name
  Serial.println("The device started, now you can pair it with Bluetooth!");
}

void loop() {
  // Check for Bluetooth input
  if (SerialBT.available()) {
    String command = SerialBT.readString();
    command.trim();
    
    if (command == "get-data") {
      double Hb = calculateHb();
      if (Hb != -1) {

        SerialBT.println(String(Hb));
        Serial.print("Hb (current, %): ");
        Serial.println(Hb);

   display.clearDisplay();  // Clear the buffer

    // Set text size and color
    display.setTextSize(2);         // Normal 1:1 pixel scale
    display.setTextColor(SSD1306_WHITE); // Draw white text
    display.setCursor(0, 10); 
    
    display.println("Hemoglobin"); // Print Hello, World!

    
    
    display.println(String(Hb)+" g/dL"); // Print Hello, World!
   
   
    display.display(); // Show the display buffer on the screen


      } else {
        SerialBT.println("Unable to calculate Hb");
      }
    }
  }

  // For testing, also check if something is available on Serial
  if (Serial.available()) {
    SerialBT.write(Serial.read());
  }
  delay(20);
}
