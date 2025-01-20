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
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

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

// Function to initialize the sensor and display
void initializeSensor()
{
    Serial.begin(9600);
    if (sensor.begin() && sensor.setSamplingRate(kSamplingRate))
    {
        Serial.println("Sensor initialized");
    }
    else
    {
        Serial.println("Sensor not found");
        while (1)
            ; // Halt if sensor is not found
    }

    // Initialize the SSD1306 display
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C))
    {
        Serial.println(F("SSD1306 allocation failed"));
        for (;;)
            ; // Halt if display initialization fails
    }

    // Show startup message
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("Device On");
    display.display();
    delay(1500);

    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("Ready to  Scan!");
    display.display();
    delay(1500);
}

// Function to calculate Hb
float calculateHb()
{
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("Place Finger");
    display.display();

    while (true)
    {
        auto sample = sensor.readSample(1000);
        float current_value_red = sample.red;
        float current_value_ir = sample.ir;

        // Detect Finger
        if (sample.red > kFingerThreshold)
        {
            if (millis() - finger_timestamp > kFingerCooldownMs)
            {
                finger_detected = true;
                display.clearDisplay();
                display.setTextSize(2);
                display.setCursor(0, 10);
                display.println("Measuring...");
                display.display();
            }
        }
        else
        {
            // Reset values if the finger is removed
            differentiator.reset();
            low_pass_filter_red.reset();
            low_pass_filter_ir.reset();
            high_pass_filter.reset();
            stat_red.reset();
            stat_ir.reset();

            finger_detected = false;
            finger_timestamp = millis();

            display.clearDisplay();
            display.setTextSize(2);
            display.setCursor(0, 10);
            display.println("Place Finger");
            display.display();
            continue;
        }

        if (finger_detected)
        {
            current_value_red = low_pass_filter_red.process(current_value_red);
            current_value_ir = low_pass_filter_ir.process(current_value_ir);
            stat_red.process(current_value_red);
            stat_ir.process(current_value_ir);

            float current_value = high_pass_filter.process(current_value_red);
            float current_diff = differentiator.process(current_value);

            if (!isnan(current_diff) && !isnan(last_diff))
            {
                if (last_diff > 0 && current_diff < 0)
                {
                    crossed = true;
                    crossed_time = millis();
                }
                if (current_diff > 0)
                {
                    crossed = false;
                }

                if (crossed && current_diff < kEdgeThreshold)
                {
                    if (last_heartbeat != 0 && crossed_time - last_heartbeat > 300)
                    {
                        int bpm = 60000 / (crossed_time - last_heartbeat);
                        float rred = (stat_red.maximum() - stat_red.minimum()) / stat_red.average();
                        float rir = (stat_ir.maximum() - stat_ir.minimum()) / stat_ir.average();
                        float r = rred / rir;
                        float spo2 = kSpO2_A * r * r + kSpO2_B * r + kSpO2_C;

                        if (bpm > 50 && bpm < 250)
                        {
                            int POCT = (15 - (0.1 * spo2));
                            return 7.5 + (0.69 * POCT);
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

void setup()
{
    // Initialize Bluetooth
    SerialBT.begin("BIO-Device2"); // Device name for Bluetooth
    Serial.println("Bluetooth device ready to pair!");

    // Initialize the sensor and display
    initializeSensor();
}
void loop()
{
    // Check Bluetooth connection status
    if (SerialBT.hasClient())
    {
        // If connected, display message
        display.clearDisplay();
        display.setTextSize(2);
        display.setTextColor(SSD1306_WHITE);
        display.setCursor(0, 10);
        display.println("Bluetooth Connected");
        display.display();

        // Handle Bluetooth commands
        if (SerialBT.available())
        {
            String command = SerialBT.readString();
            command.trim();
            if (command == "get-data")
            {
                display.clearDisplay();
                display.setTextSize(2);
                display.setCursor(0, 10);
                display.display();
                double Hb = calculateHb();
                SerialBT.println(String(Hb));
                display.clearDisplay();
                display.setTextSize(2);
                display.setCursor(0, 10);
                display.println("Hemoglobin");
                display.println(String(Hb) + " g/dL");
                display.display();
                delay(5000);
            }
        }
    }
    else
    {
        // If not connected, operate in standalone mode
        display.setTextSize(2);
        display.setTextColor(SSD1306_WHITE);
        display.setCursor(0, 10);
        display.display();

        // Detect finger and measure hemoglobin
        if (sensor.readSample(1000).red > kFingerThreshold)
        {
            display.setTextSize(2);
            display.setCursor(0, 10);
            display.display();
            double Hb = calculateHb();
            display.clearDisplay();
            display.setTextSize(2);
            display.setCursor(0, 10);
            display.println("Hemoglobin");
            display.println(String(Hb) + " g/dL");
            display.display();

            delay(5000);
        }
    }

    delay(100);
}
