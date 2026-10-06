// TEST TEENSY HARDWARE

#define TRIAL_SWITCH 36
#define RESP_SWITCH 35

#define TRIAL_LED 38
#define RESP_LED 37 

#define SOLENOID 41
#define LIGHTS 22

void setup() {
  Serial.begin(115200);
}

void loop() {
  test_switch_leds();
  test_switches();
  test_solenoids();
  test_lights();
}

void test_switches() {
  Serial.println("initiating switch testing; should be HIGH when blocked and LOW when unblocked");
  pinMode(RESP_SWITCH, INPUT);
  pinMode(TRIAL_SWITCH, INPUT);
  Serial.read();
  delay(1000);
  int trl_val = 0;
  int resp_val = 0;
  while(Serial.available() == 0) {
    Serial.println("trial switch:");
    trl_val = digitalRead(TRIAL_SWITCH);
    Serial.println(trl_val);


    Serial.println("resp switch:");
    resp_val = digitalRead(RESP_SWITCH);
    Serial.println(resp_val);

    Serial.println("type anything in the terminal to move on");
    delay(100);
  }
  Serial.flush();
  Serial.read();
}

void test_switch_leds() {
  Serial.println("iniating swtich LED testing; should flicker");
  delay(3000);
  pinMode(TRIAL_LED, OUTPUT);
  pinMode(RESP_LED, OUTPUT);
  while(Serial.available() == 0) {
    digitalWrite(TRIAL_LED, HIGH);
    digitalWrite(RESP_LED, HIGH);
    Serial.println("type anything in the terminal to move on");
  }
  Serial.flush();
  Serial.read();
}

void test_solenoids() {
  Serial.read();
  pinMode(SOLENOID, OUTPUT);
  digitalWrite(SOLENOID, LOW);
  Serial.println("initiating solenoid testing; should open and close");
  delay(3000);
  while(Serial.available() == 0) {
    digitalWrite(SOLENOID, HIGH);
    Serial.println("open");
    delay(1000);
    digitalWrite(SOLENOID, LOW);
    Serial.println("close");
    delay(1000);
    Serial.println("type anything in the terminal to move on");
  }
  Serial.flush();
  Serial.read();
}

void test_lights() {
  Serial.read();
  pinMode(LIGHTS, OUTPUT);
  digitalWrite(LIGHTS, LOW);
  Serial.println("initiating lights testing; should flicker");
  delay(3000);
  while(Serial.available() == 0) {
    digitalWrite(LIGHTS, HIGH);
    Serial.println("off");
    delay(1000);
    digitalWrite(LIGHTS, LOW);
    Serial.println("on");
    delay(1000);
    Serial.println("type anything in the terminal to move on");
  }
  Serial.flush();
  Serial.read();
}