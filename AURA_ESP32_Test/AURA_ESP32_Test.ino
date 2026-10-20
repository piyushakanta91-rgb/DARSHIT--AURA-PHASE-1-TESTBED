#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>

#include <Wire.h>
#include <Adafruit_SHT31.h>

#include <OneWire.h>
#include <DallasTemperature.h>


// =====================================================
// AURA MASTER ESP32-S3
// OWN WIFI + REAL SENSORS + SIMULATED DEMO DATA
// =====================================================


// =====================================================
// AURA WIFI ACCESS POINT
// =====================================================

const char* AP_SSID     = "AURA-ESP32 S3";
const char* AP_PASSWORD = "AURA@12345";


// =====================================================
// FIXED ESP32 WIFI ADDRESS
// =====================================================

IPAddress local_IP(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);


// =====================================================
// SENSOR PINS
// =====================================================

// MQ-135
#define MQ135_PIN 2

// DS18B20
#define DS18B20_PIN 4

// SHT31
#define SHT31_SDA 8
#define SHT31_SCL 9


// =====================================================
// SENSOR OBJECTS
// =====================================================

Adafruit_SHT31 sht31 = Adafruit_SHT31();

OneWire oneWire(DS18B20_PIN);

DallasTemperature ds18b20(&oneWire);


// =====================================================
// WEB SERVER
// =====================================================

WebServer server(80);


// =====================================================
// REAL SENSOR DATA
// =====================================================

float airTemperature = NAN;
float humidity = NAN;
float waterTemperature = NAN;

float mq135Raw = 0;


// =====================================================
// SIMULATED / DEMO DATA
//
// PM2.5 IN  -> PM2.5 before purification
// PM2.5 OUT -> PM2.5 after purification
//
// PM10 IN   -> PM10 before purification
// PM10 OUT  -> PM10 after purification
//
// pH        -> simulated because pH sensor is not connected
// =====================================================

float simulatedPM25In  = 27.0;
float simulatedPM25Out = 17.0;

float simulatedPM10In  = 50.0;
float simulatedPM10Out = 32.0;

float simulatedPH = 8.10;


// =====================================================
// TIMING
// =====================================================

unsigned long lastSensorRead = 0;

const unsigned long SENSOR_INTERVAL = 2000;


unsigned long lastSimulationUpdate = 0;

const unsigned long SIMULATION_INTERVAL = 5000;


// =====================================================
// NUMBER OR NULL
//
// Sends a valid JSON number if the value exists.
// Sends null if the value is NAN.
// =====================================================

String numberOrNull(float value, int decimals) {

  if (isnan(value)) {

    return "null";

  }

  return String(value, decimals);
}


// =====================================================
// UPDATE SIMULATED DATA
// =====================================================

void updateSimulatedData() {

  if (
    millis() - lastSimulationUpdate <
    SIMULATION_INTERVAL
  ) {

    return;
  }

  lastSimulationUpdate = millis();


  // ---------------------------------------------------
  // PM2.5 INPUT
  // ---------------------------------------------------

  simulatedPM25In =
    27.0 +
    ((float)random(-20, 21) / 10.0);


  // ---------------------------------------------------
  // PM2.5 OUTPUT
  // About 37% lower for demonstration
  // ---------------------------------------------------

  simulatedPM25Out =
    simulatedPM25In * 0.63;


  // ---------------------------------------------------
  // PM10 INPUT
  // ---------------------------------------------------

  simulatedPM10In =
    50.0 +
    ((float)random(-30, 31) / 10.0);


  // ---------------------------------------------------
  // PM10 OUTPUT
  // About 36% lower for demonstration
  // ---------------------------------------------------

  simulatedPM10Out =
    simulatedPM10In * 0.64;


  // ---------------------------------------------------
  // pH
  // ---------------------------------------------------

  simulatedPH = 8.10;
}


// =====================================================
// READ MQ-135
// =====================================================

void readMQ135() {

  long total = 0;


  for (
    int i = 0;
    i < 20;
    i++
  ) {

    total += analogRead(MQ135_PIN);

    delay(2);
  }


  mq135Raw =
    total / 20.0;
}


// =====================================================
// READ DS18B20
// =====================================================

void readDS18B20() {

  ds18b20.requestTemperatures();


  float temperature =
    ds18b20.getTempCByIndex(0);


  if (
    temperature !=
    DEVICE_DISCONNECTED_C
  ) {

    waterTemperature =
      temperature;
  }
}


// =====================================================
// READ SHT31
// =====================================================

void readSHT31() {

  float temperature =
    sht31.readTemperature();

  float rh =
    sht31.readHumidity();


  if (!isnan(temperature)) {

    airTemperature =
      temperature;
  }


  if (!isnan(rh)) {

    humidity =
      rh;
  }
}


// =====================================================
// READ ALL DATA
// =====================================================

void readAllSensors() {

  // Real sensors

  readSHT31();

  readDS18B20();

  readMQ135();


  // Simulated/demo sensors

  updateSimulatedData();


  // ===================================================
  // SERIAL MONITOR
  // ===================================================

  Serial.println();

  Serial.println(
    "=========================================="
  );


  // ---------------------------------------------------
  // AIR TEMPERATURE
  // ---------------------------------------------------

  Serial.print(
    "Air Temperature : "
  );

  if (isnan(airTemperature)) {

    Serial.println("ERROR");

  } else {

    Serial.print(
      airTemperature,
      2
    );

    Serial.println(" C");
  }


  // ---------------------------------------------------
  // HUMIDITY
  // ---------------------------------------------------

  Serial.print(
    "Humidity        : "
  );

  if (isnan(humidity)) {

    Serial.println("ERROR");

  } else {

    Serial.print(
      humidity,
      2
    );

    Serial.println(" %");
  }


  // ---------------------------------------------------
  // WATER TEMPERATURE
  // ---------------------------------------------------

  Serial.print(
    "Water Temp      : "
  );

  if (isnan(waterTemperature)) {

    Serial.println("ERROR");

  } else {

    Serial.print(
      waterTemperature,
      2
    );

    Serial.println(" C");
  }


  // ---------------------------------------------------
  // MQ-135
  // ---------------------------------------------------

  Serial.print(
    "MQ-135 RAW      : "
  );

  Serial.println(
    mq135Raw,
    1
  );


  // ---------------------------------------------------
  // PM2.5 INPUT
  // ---------------------------------------------------

  Serial.print(
    "PM2.5 IN        : "
  );

  Serial.print(
    simulatedPM25In,
    1
  );

  Serial.println(
    " ug/m3"
  );


  // ---------------------------------------------------
  // PM2.5 OUTPUT
  // ---------------------------------------------------

  Serial.print(
    "PM2.5 OUT       : "
  );

  Serial.print(
    simulatedPM25Out,
    1
  );

  Serial.println(
    " ug/m3"
  );


  // ---------------------------------------------------
  // PM10 INPUT
  // ---------------------------------------------------

  Serial.print(
    "PM10 IN         : "
  );

  Serial.print(
    simulatedPM10In,
    1
  );

  Serial.println(
    " ug/m3"
  );


  // ---------------------------------------------------
  // PM10 OUTPUT
  // ---------------------------------------------------

  Serial.print(
    "PM10 OUT        : "
  );

  Serial.print(
    simulatedPM10Out,
    1
  );

  Serial.println(
    " ug/m3"
  );


  // ---------------------------------------------------
  // pH
  // ---------------------------------------------------

  Serial.print(
    "pH              : "
  );

  Serial.println(
    simulatedPH,
    2
  );


  Serial.println(
    "=========================================="
  );
}


// =====================================================
// SENSOR JSON API
// =====================================================
//
// Phone/app requests:
//
// http://192.168.4.1/api/sensors
//
// =====================================================

void handleSensors() {

  String json = "{";


  // ---------------------------------------------------
  // SYSTEM STATUS
  // ---------------------------------------------------

  json += "\"status\":\"online\",";


  // ---------------------------------------------------
  // REAL SHT31 DATA
  // ---------------------------------------------------

  json += "\"airTemperature\":";

  json += numberOrNull(
    airTemperature,
    2
  );

  json += ",";


  json += "\"humidity\":";

  json += numberOrNull(
    humidity,
    2
  );

  json += ",";


  // ---------------------------------------------------
  // REAL DS18B20 DATA
  // ---------------------------------------------------

  json += "\"waterTemperature\":";

  json += numberOrNull(
    waterTemperature,
    2
  );

  json += ",";


  // ---------------------------------------------------
  // REAL MQ-135 DATA
  // ---------------------------------------------------

  json += "\"mq135Raw\":";

  json += String(
    mq135Raw,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM2.5 INPUT
  // ---------------------------------------------------

  json += "\"pm25In\":";

  json += String(
    simulatedPM25In,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM2.5 OUTPUT
  // ---------------------------------------------------

  json += "\"pm25Out\":";

  json += String(
    simulatedPM25Out,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM10 INPUT
  // ---------------------------------------------------

  json += "\"pm10In\":";

  json += String(
    simulatedPM10In,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM10 OUTPUT
  // ---------------------------------------------------

  json += "\"pm10Out\":";

  json += String(
    simulatedPM10Out,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // pH
  // ---------------------------------------------------

  json += "\"ph\":";

  json += String(
    simulatedPH,
    2
  );


  // ---------------------------------------------------
  // CLOSE JSON
  // ---------------------------------------------------

  json += "}";


  // ---------------------------------------------------
  // SEND JSON
  // ---------------------------------------------------

  server.send(
    200,
    "application/json",
    json
  );
}


// =====================================================
// DEBUG API
// =====================================================
//
// http://192.168.4.1/api/debug
//
// This keeps the simulation status separate from the
// normal app sensor endpoint.
// =====================================================

void handleDebug() {

  String json = "{";


  // ---------------------------------------------------
  // SIMULATION FLAGS
  // ---------------------------------------------------

  json += "\"pm25Simulated\":true,";

  json += "\"pm10Simulated\":true,";

  json += "\"phSimulated\":true,";


  // ---------------------------------------------------
  // PM2.5 IN
  // ---------------------------------------------------

  json += "\"pm25In\":";

  json += String(
    simulatedPM25In,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM2.5 OUT
  // ---------------------------------------------------

  json += "\"pm25Out\":";

  json += String(
    simulatedPM25Out,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM10 IN
  // ---------------------------------------------------

  json += "\"pm10In\":";

  json += String(
    simulatedPM10In,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // PM10 OUT
  // ---------------------------------------------------

  json += "\"pm10Out\":";

  json += String(
    simulatedPM10Out,
    1
  );

  json += ",";


  // ---------------------------------------------------
  // pH
  // ---------------------------------------------------

  json += "\"ph\":";

  json += String(
    simulatedPH,
    2
  );


  // ---------------------------------------------------
  // CLOSE JSON
  // ---------------------------------------------------

  json += "}";


  server.send(
    200,
    "application/json",
    json
  );
}


// =====================================================
// ROOT PAGE
// =====================================================

void handleRoot() {

  String page;


  page +=
    "AURA ESP32-S3\n";

  page +=
    "SYSTEM: ONLINE\n\n";


  page +=
    "WiFi: AURA-ESP32 S3\n";

  page +=
    "IP: 192.168.4.1\n\n";


  page +=
    "API:\n";

  page +=
    "/api/sensors\n";

  page +=
    "/api/debug\n";


  server.send(
    200,
    "text/plain",
    page
  );
}


// =====================================================
// 404
// =====================================================

void handleNotFound() {

  server.send(
    404,
    "text/plain",
    "AURA API: endpoint not found"
  );
}


// =====================================================
// START ESP32 OWN WIFI
// =====================================================

void startAURAWiFi() {

  Serial.println();

  Serial.println(
    "Starting AURA WiFi..."
  );


  // ---------------------------------------------------
  // ACCESS POINT MODE
  // ---------------------------------------------------

  WiFi.mode(
    WIFI_AP
  );


  // ---------------------------------------------------
  // FIXED IP
  // ---------------------------------------------------

  bool configOK =
    WiFi.softAPConfig(
      local_IP,
      gateway,
      subnet
    );


  if (configOK) {

    Serial.println(
      "Static IP configured"
    );

  } else {

    Serial.println(
      "Static IP configuration FAILED"
    );
  }


  // ---------------------------------------------------
  // START ACCESS POINT
  // ---------------------------------------------------

  bool success =
    WiFi.softAP(
      AP_SSID,
      AP_PASSWORD,
      6,
      0,
      4
    );


  if (success) {

    Serial.println(
      "AURA WiFi STARTED"
    );

  } else {

    Serial.println(
      "AURA WiFi FAILED"
    );
  }


  // ---------------------------------------------------
  // WIFI INFORMATION
  // ---------------------------------------------------

  Serial.print(
    "WiFi Name: "
  );

  Serial.println(
    AP_SSID
  );


  Serial.print(
    "WiFi Password: "
  );

  Serial.println(
    AP_PASSWORD
  );


  Serial.print(
    "ESP32 IP: "
  );

  Serial.println(
    WiFi.softAPIP()
  );
}


// =====================================================
// SETUP
// =====================================================

void setup() {

  // ---------------------------------------------------
  // SERIAL
  // ---------------------------------------------------

  Serial.begin(
    115200
  );


  delay(
    2000
  );


  Serial.println();

  Serial.println(
    "================================================"
  );

  Serial.println(
    "          AURA MASTER CONTROLLER"
  );

  Serial.println(
    "             ESP32-S3"
  );

  Serial.println(
    "       OWN WIFI ACCESS POINT"
  );

  Serial.println(
    "================================================"
  );


  // ---------------------------------------------------
  // RANDOM SEED
  // ---------------------------------------------------

  randomSeed(
    analogRead(
      MQ135_PIN
    )
  );


  // ---------------------------------------------------
  // ADC
  // ---------------------------------------------------

  analogReadResolution(
    12
  );


  analogSetPinAttenuation(
    MQ135_PIN,
    ADC_11db
  );


  // ---------------------------------------------------
  // I2C
  // ---------------------------------------------------

  Wire.begin(
    SHT31_SDA,
    SHT31_SCL
  );


  // ---------------------------------------------------
  // SHT31
  // ---------------------------------------------------

  Serial.print(
    "SHT31: "
  );


  if (
    sht31.begin(0x44)
  ) {

    Serial.println(
      "CONNECTED"
    );

  } else {

    Serial.println(
      "NOT FOUND"
    );
  }


  // ---------------------------------------------------
  // DS18B20
  // ---------------------------------------------------

  ds18b20.begin();


  Serial.print(
    "DS18B20 devices: "
  );


  Serial.println(
    ds18b20.getDeviceCount()
  );


  // ---------------------------------------------------
  // MQ-135
  // ---------------------------------------------------

  Serial.println(
    "MQ-135: GPIO2 READY"
  );


  // ---------------------------------------------------
  // START OWN WIFI
  // ---------------------------------------------------

  startAURAWiFi();


  // ---------------------------------------------------
  // API ROUTES
  // ---------------------------------------------------

  server.on(
    "/",
    HTTP_GET,
    handleRoot
  );


  server.on(
    "/api/sensors",
    HTTP_GET,
    handleSensors
  );


  server.on(
    "/api/debug",
    HTTP_GET,
    handleDebug
  );


  server.onNotFound(
    handleNotFound
  );


  // ---------------------------------------------------
  // CORS
  // ---------------------------------------------------

  server.enableCORS(
    true
  );


  // ---------------------------------------------------
  // START HTTP SERVER
  // ---------------------------------------------------

  server.begin();


  Serial.println(
    "HTTP SERVER STARTED"
  );


  // ---------------------------------------------------
  // FIRST SENSOR READING
  // ---------------------------------------------------

  readAllSensors();


  // ---------------------------------------------------
  // READY
  // ---------------------------------------------------

  Serial.println();

  Serial.println(
    "================================================"
  );

  Serial.println(
    "             AURA SYSTEM READY"
  );

  Serial.println(
    "================================================"
  );

  Serial.println();

  Serial.println(
    "Connect phone to:"
  );

  Serial.println(
    "AURA-ESP32 S3"
  );

  Serial.println();

  Serial.println(
    "Open:"
  );

  Serial.println(
    "http://192.168.4.1/api/sensors"
  );

  Serial.println();
}


// =====================================================
// LOOP
// =====================================================

void loop() {

  // ---------------------------------------------------
  // HANDLE WEB REQUESTS
  // ---------------------------------------------------

  server.handleClient();


  // ---------------------------------------------------
  // SENSOR UPDATE
  // ---------------------------------------------------

  if (
    millis() - lastSensorRead >=
    SENSOR_INTERVAL
  ) {

    lastSensorRead =
      millis();

    readAllSensors();
  }


  delay(2);
}