#include <Arduino.h>
#include <ros.h>
#include <Motor.h>
#include <WiFi.h>
#include <move/Move.h>
#include <cstring>

#include <Pinout.h>

const uint CBTIMEOUT_INTERVAL = 1000000; // Timeout time to callback
unsigned long cbTimeout = 0; // Callback timemout timer

// WiFi
const char* SSID = "NERo-Arena";
const char* PASSWD = "BDPsystem10";

// Motor
Motor lmotor(AIN1, AIN2, PWMA);
Motor rmotor(BIN1, BIN2, PWMB);

// PWM value
float lpwm;
float rpwm;


// ROS variables and functions
IPAddress server(192,168,0,115); // MASTER IP
const uint16_t serverPort = 11411; // TCP CONNECTION PORT
ros::NodeHandle nh; // Node handle object
move::Move velocity;
void Move_cb(const move::Move &MSG);
void ROS_Setup();
ros::Subscriber<move::Move> Move("Move", &Move_cb);


// Function declarations
void WIFI_Setup(const IPAddress IPV4, const IPAddress GATEWAY, const IPAddress SUBNET);
void wait(int Time);


void setup() {
  
  Serial.begin(115200);
  delay(1000);

  // WiFi Setup

  // Network variables
  IPAddress my_IP(192, 168, 0, 206);
  IPAddress gateway(192, 168, 0, 1);
  IPAddress subnet(255, 255, 255, 0);
  WIFI_Setup(my_IP, gateway, subnet);

  // ROS setup
  ROS_Setup();
  
}

void loop() {

  if ((micros() - cbTimeout) >= CBTIMEOUT_INTERVAL) {

    lpwm = 0;
    rpwm = 0;
  }

  lmotor.setSpeed(lpwm);
  rmotor.setSpeed(rpwm);

  nh.spinOnce();
  wait(10);
}

void Move_cb(const move::Move &MSG) {
  Serial.printf("Callback executado\nDirection: %s, Power: %d\n", MSG.direction, MSG.power);

  // Calcula o valor PWM base
  float pwm_base = static_cast<float>(MSG.power * -10.23);

  if (strcmp(MSG.direction, "f") == 0) {       // Frente
    lpwm = -pwm_base;
    rpwm = pwm_base;
  } else if (strcmp(MSG.direction, "e") == 0) { // Esquerda
    lpwm = pwm_base;
    rpwm = pwm_base;
  } else if (strcmp(MSG.direction, "d") == 0) { // Direita
    lpwm = -pwm_base;
    rpwm = -pwm_base;
  } else if (strcmp(MSG.direction, "b") == 0) { // Trás
    lpwm = pwm_base;
    rpwm = -pwm_base;
  }

  // Limita valores de PWM
  lpwm = constrain(lpwm, -1023, 1023);
  rpwm = constrain(rpwm, -1023, 1023);

  Serial.printf("Mandando o sinal de pwm: %3.3f %3.3f\n", lpwm, rpwm);

  cbTimeout = micros();
}


// ROS setup function
void ROS_Setup() {

  nh.getHardware()->setConnection(server, serverPort);
  nh.initNode();
  nh.subscribe(Move);
  while (!nh.connected()) {
    nh.spinOnce();
    wait(800);
  }
}

void WIFI_Setup(const IPAddress IPV4, const IPAddress GATEWAY, const IPAddress SUBNET) {
   if (!WiFi.config(IPV4, GATEWAY, SUBNET)) {
    Serial.println("The static IP setup failed.");
  }
  WiFi.begin(SSID, PASSWD);
  WiFi.mode(WIFI_STA);
  Serial.println("Connecting to WIFI...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    wait(800);
  }
  Serial.printf("\nConnected to WIFI.\n");
}

// Delay function that doesn't engage sleep mode
void wait(int time) {
  int lasttime = millis();
  while ((millis() - lasttime) <= time) {
  }
}