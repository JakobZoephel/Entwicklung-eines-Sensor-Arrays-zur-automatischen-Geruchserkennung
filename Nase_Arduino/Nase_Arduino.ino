// Übersicht, welche Stoffe die Sensoren messen
// https://tutorials-raspberrypi.de/raspberry-pi-gas-sensor-mq2-konfigurieren-und-auslesen/

/*
    MQ-2: Methan, Butan, LPG (Autogas), Rauch
    MQ-3: Alkohol, Ethanol, Rauch
    MQ-4: Methan, CNG Gas (komprimiertes Erdgas)
    MQ-5: Erdgas, LPG (Autogas)
    MQ-6: LPG (Autogas), Butan
    MQ-7: Kohlenmonoxid
    MQ-8: Wasserstoffgas
    MQ-9: Kohlenmonoxid, entflammbare Gase
    MQ131: Ozon Gas
    MQ135: Luft Qualität (Benzol, Alkohol, Rauch)
    MQ136: Schwefelwasserstoffgas
    MQ137: Ammoniak
    MQ138: Benzol, Steinkohlenteeröl (Toluol), Aceton, Propan, Formaldehyd, Wasserstoffgas
    MQ214: Methan, Erdgas
    MQ216: Erdgas, Kohlegas
    MQ303A: Alkohol, Ethanol, Rauch
    MQ306A: LPG (Autogas), Butan
    MQ307A: Kohlenmonoxid
    MQ309A: Kohlenmonoxid, entflammbare Gase
    MG811: Kohlendioxid (CO2)
    AQ-104: Luftqualität
    AQ-2: entflammbare Gase, Rauch
    AQ-3: Alkohol, Benzin
    AQ-7: Kohlenmonoxid
*/

// viele Datenblätter:
// https://www.roboter-bausatz.de/p/mq-serie-9er-set-sensoren


#include <DFRobot_DHT11.h>
#include <DFRobot_SGP40.h>
#include "SdsDustSensor.h"
#include "DFRobot_MultiGasSensor.h"

#define I2C_COMMUNICATION

#ifdef I2C_COMMUNICATION
#define I2C_ADDRESS 0x74
DFRobot_GAS_I2C gas(&Wire, I2C_ADDRESS);
#else
#if (!defined ARDUINO_ESP32_DEV) && (!defined __SAMD21G18A__)

SoftwareSerial mySerial(2, 3);
DFRobot_GAS_SoftWareUart gas(&mySerial);
#else
DFRobot_GAS_HardWareUart gas(&Serial2);
#endif
#endif

SdsDustSensor sds(Serial1);

#define COLLECT_NUMBER 10  // 1-100.
#define oxygen_IICAddress ADDRESS_3

#define DHTPIN A0
#define CO2Pin 7

#define ppmrange 5000
unsigned long pwmtime;
unsigned long PPM = 0;
float pulsepercent = 0;

#define GAS_SENSORS 13
// Durchschnitt aus ITERATIONS Sensor-Werten
#define ITERATIONS 50
// damit Processing auch Zeit hat die Werte zu empfangen
#define PRINT_DELAY 150
int kaliDurchgaenge = -1;

const int PINS[] = {
  A12,  // MQ2PIN
  A14,  // MQ3PIN
  A11,  // MQ4PIN
  A10,  // MQ5PIN
  A9,   // MQ6PIN
  A13,  // MQ7PIN
  A2,   // MQ8PIN
  A3,   // MQ9PIN
  A15,  // MQ131PIN
  A4,   // MQ135PIN
  A6,   // MQ136PIN
  A5,   // MQ137PIN
  A7,   // MQ138PIN
};

const String NAMES[] = {
  "MQ2",
  "MQ3",
  "MQ4",
  "MQ5",
  "MQ6",
  "MQ7",
  "MQ8",
  "MQ9",
  "MQ131",
  "MQ135",
  "MQ136",
  "MQ137",
  "MQ138",
  /*
  "VOC",
  "O2",
  "CO2",
  "PM2.5",
  "PM10",
  "Luftfeuchtigkeit",
  "Temperatur",
  */
};

// Sensor-Werte der Gas-Sensoren
/*
  unsigned int ist 0 bis 65,535, also maximal
  65,535/1024= maximale 63.9990234375 iterations
  alternativ unsigned long, was aber langsamer ist
*/
unsigned int werte[GAS_SENSORS];
// um sicherzugehen, dass alles synchron ist
unsigned long loopCounter = 0;

DFRobot_DHT11 dht;
DFRobot_SGP40 vocSensor;

void setup() {

  Serial.begin(19200);
  Serial.println("\n----------------------------------------------");
  Serial.println("initializing serial...");
  sds.begin();

  while (!Serial) {
    delay(10);
  }
  Serial.println("initializing serial completed...");

  // Status LEDs
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
  digitalWrite(7, LOW);
  digitalWrite(8, HIGH);

  pinMode(CO2Pin, INPUT);
  delay(100);

  Serial.println("initializing VOC sensor...");
  // dauert 10 Sekunden
  while (vocSensor.begin() != true) {
    Serial.println("failed to init VOC");
  }
  Serial.println("initializing VOC completed...");

  Wire.begin();
  Serial.println("initializing O2 sensor...");

  while (!gas.begin()) {
    Serial.println("could not find O2");
    delay(1000);
  }
  gas.changeAcquireMode(gas.PASSIVITY);
  delay(1000);
  gas.setTempCompensation(gas.OFF);

  Serial.println("initializing O2 completed...");

  Serial.println("----------------------------------------------");
  Serial.println("Starting reading of sensors");
  Serial.println("----------------------------------------------");

  dht.read(DHTPIN);
  float hum = dht.humidity;
  float temp = dht.temperature;

  //solange der DHT Sensor noch nicht bereict ist
  while (hum != hum || temp != temp) {
    dht.read(DHTPIN);
    hum = dht.humidity;
    temp = dht.temperature;
    delay(500);
  }
}

void loop() {

//   // Info, wann die Kalibrierung zuende ist
//   if (kaliDurchgaenge == -1 && Serial.available()) {
//     kaliDurchgaenge = Serial.read();
//   } else if (loopCounter == kaliDurchgaenge) {
//     digitalWrite(7, HIGH);
//     digitalWrite(8, LOW);
//   }

  for (int i = 0; i < GAS_SENSORS; i++) {
    werte[i] = 0;
  }

  for (int i = 0; i < ITERATIONS; i++) {
    for (int j = 0; j < GAS_SENSORS; j++) {
      werte[j] += analogRead(PINS[j]);
      delay(5);
    }
  }

  for (int i = 0; i < GAS_SENSORS; i++) {
    werte[i] /= ITERATIONS;
  }

  for (int i = 0; i < GAS_SENSORS; i++) {
    Serial.println(NAMES[i] + " " + String(werte[i]));
    delay(PRINT_DELAY);
  }

  dht.read(DHTPIN);
  vocSensor.setRhT(dht.humidity, dht.temperature);
  Serial.println("VOC " + String(vocSensor.getVoclndex()));
  delay(PRINT_DELAY);
  // int temp = gas.readTempC();
  Serial.println("O2 " + String(gas.readGasConcentrationPPM()));
  delay(PRINT_DELAY);

  pwmtime = pulseIn(CO2Pin, HIGH, 2000000) / 1000;
  float pulsepercent = pwmtime / 1004.0;
  PPM = ppmrange * pulsepercent;
  Serial.println("CO2 " + String(PPM));
  delay(PRINT_DELAY);

  sds.wakeup();
  PmResult pm = sds.queryPm();
  if (pm.isOk()) {
    Serial.println("PM2.5 " + String(pm.pm25));
    delay(PRINT_DELAY);
    Serial.println("PM10 " + String(pm.pm10));
    delay(PRINT_DELAY);
    // Serial.println(pm.toString());
  } else {
    Serial.println("PM2.5 0");
    delay(PRINT_DELAY);
    Serial.println("PM10 0");
    delay(PRINT_DELAY);
    // Serial.print("Could not read values from sensor, reason: ");
    // Serial.println(pm.statusToString());
  }

  Serial.println("Luftfeuchtigkeit " + String(dht.humidity));
  delay(PRINT_DELAY);

  Serial.println("Temperatur " + String(dht.temperature));
  delay(PRINT_DELAY);

  // "ist" nur damit in Processing split("  ").length == 3 == true
  loopCounter++;
  // Synchronisierung in Processing
  Serial.println("loopCounter ist " + String(loopCounter));
}
