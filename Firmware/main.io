#include <STM32FreeRTOS.h>

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include <Keypad.h>

#include <Servo.h>
//BUZZER
const uint8_t BUZZ_PIN=PA4; 

//SERVO
const uint8_t SERVO_PIN=PA0;
const uint8_t MOSFET_PIN=PA1;
Servo my_servo;

//ULTRASONIC SENSOR
const uint8_t TRIG_PIN=PB0;
const uint8_t ECHO_PIN=PB1;

//OLED DISPLAY
const uint8_t OLED_SDA=PB7;
const uint8_t OLED_SCL=PB6;
const uint8_t OLED_RESET=-1;
const uint16_t SCREEN_WIDTH=128;
const uint16_t SCREEN_HEIGHT=32;
Adafruit_SSD1306 display(SCREEN_WIDTH,SCREEN_HEIGHT,&Wire,OLED_RESET);

//Keypad
const byte ROWS=4;
const byte COLS=4;
char keys[ROWS][COLS]={
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};
byte rowPins[ROWS]={PB12,PB13,PB14,PB15};
byte colPins[COLS]={PB8,PB9,PB3,PB4};
Keypad input_keypad = Keypad(makeKeymap(keys),rowPins,colPins,ROWS,COLS);

const uint16_t TASK_STACK_SIZE=256;
const UBaseType_t TASK_PRIORITY=1;
const unsigned long SENSOR_TIMEOUT=25000;
const int OBSTACLE_THRESHOLD_CM=20;

char current_mode='B';
volatile int current_angle=90;
volatile int current_distance=0;
volatile int target_angle=90;
int scan_direction=1;

String input_angle_str="";

void vTaskBuzzer(void*pvParameters);
void vTaskSensor(void*pvParameters);
void vTaskDisplay(void*pvParameters);
void updateDisplay(int distance);
void vTaskKeypad(void*pvParameters);
void vTaskServo(void*pvParameters);
void moveServo(int target_angle);

void setup(){
  pinMode(BUZZ_PIN,OUTPUT);

  Wire.setSDA(OLED_SDA);
  Wire.setSCL(OLED_SCL);
  Wire.begin();

  pinMode(TRIG_PIN,OUTPUT);
  pinMode(ECHO_PIN,INPUT);

  digitalWrite(BUZZ_PIN,HIGH);
  delay(200);
  digitalWrite(BUZZ_PIN,LOW);

  pinMode(MOSFET_PIN,OUTPUT);
  digitalWrite(MOSFET_PIN,LOW);
  my_servo.attach(SERVO_PIN);
  
  Serial1.begin(115200);

  if(display.begin(SSD1306_SWITCHCAPVCC,0x3C)){
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(10,10);
    display.print("System Ready");
    display.display();
    delay(1000);
  }
  input_keypad.setDebounceTime(100);
 
  xTaskCreate(
    vTaskBuzzer,   
    "BuzzerTask", 
    TASK_STACK_SIZE,          
    NULL,         
    TASK_PRIORITY,            
    NULL          
  );
  xTaskCreate(
    vTaskSensor,
    "SensorTask",
    TASK_STACK_SIZE,
    NULL,
    TASK_PRIORITY,
    NULL  
  );
  xTaskCreate(
    vTaskDisplay,
    "DisplayTask",
    TASK_STACK_SIZE,
    NULL,
    TASK_PRIORITY,
    NULL
  );
  xTaskCreate(
    vTaskKeypad,
    "KeypadTask",
    TASK_STACK_SIZE,
    NULL,
    TASK_PRIORITY,
    NULL
  );
  xTaskCreate(
    vTaskServo,
    "ServoTask",
    TASK_STACK_SIZE,
    NULL,
    TASK_PRIORITY,
    NULL
  );
vTaskStartScheduler();
}

void loop(){
  
}

void vTaskBuzzer(void*pvParameters){
  while(1){
    if(current_distance>0 && current_distance<=OBSTACLE_THRESHOLD_CM){
      digitalWrite(BUZZ_PIN,HIGH);
      vTaskDelay(pdMS_TO_TICKS(50));
      digitalWrite(BUZZ_PIN,LOW);
      vTaskDelay(pdMS_TO_TICKS(50));
    }else{
      digitalWrite(BUZZ_PIN,LOW);
      vTaskDelay(pdMS_TO_TICKS(50));
    }
  }
}

void vTaskSensor(void*pvParameters){
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  while(1){
    digitalWrite(TRIG_PIN,LOW);
    delayMicroseconds(2);
    digitalWrite(TRIG_PIN,HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN,LOW);

    long duration=pulseIn(ECHO_PIN,HIGH,SENSOR_TIMEOUT);

    if(duration>0){
      int dist=duration*0.034/2;
      if(dist>0 && dist<400){
        current_distance=dist;
      }else{
        current_distance=999;
      }
      }else{
      current_distance=999; 
      }
    vTaskDelay(pdMS_TO_TICKS(50));
  }
}

void vTaskDisplay(void*pvParameters){
  while(1){
    updateDisplay(current_distance,current_angle);
    vTaskDelay(pdMS_TO_TICKS(200));
  }
}

void updateDisplay(int distance,int angle){
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  display.drawLine(0,10,128,10,SSD1306_WHITE);

  display.setTextSize(1);
  display.setCursor(0,0);
  display.print("Target Tracked Mode ");
  display.print(current_mode);
  if(current_mode!='D'){
  display.setCursor(0,14);
  display.print("Distance:");
  if(current_distance<=OBSTACLE_THRESHOLD_CM){
    display.print(current_distance);
    display.print(" cm");
  }else{
    display.print("Out of range");
  }
  display.setCursor(0,24);
  display.print("Angle:");
  display.print(current_angle);
  display.print((char)247);
  }else if(current_mode=='D'){
    display.setCursor(0,14);
    display.print("Input: ");
    display.print(input_angle_str);
    display.print("_");
    display.setCursor(0,24);
    display.print("Target: ");
    display.print(target_angle);
    display.print((char)247);
    display.print(" | ");
  }
  display.display();
}

void vTaskKeypad(void*pvParameters){
  while(1){
    char pressed_key=input_keypad.getKey();
    if(pressed_key){
      if(pressed_key=='A'){
        current_mode=pressed_key;
      }
      else if(pressed_key=='B'){
        current_mode=pressed_key;
      }
      else if(pressed_key=='C'){
        current_mode=pressed_key;
      }
      else if(pressed_key=='D'){
        current_mode=pressed_key;
      }
      else if(current_mode=='B'){
        if(pressed_key=='7'){
          target_angle+=15;
          moveServo(target_angle);
        }
        else if(pressed_key=='5'){
          target_angle=90;
          moveServo(target_angle);
        }
        else if(pressed_key=='9'){
          target_angle-=15;
          moveServo(target_angle);
        }
      }
      else if(current_mode=='D'){
        if(pressed_key>='0' && pressed_key<='9'){
          if(input_angle_str.length()<3){
            input_angle_str+=pressed_key;

          }
        }else if(pressed_key=='*'){
          input_angle_str="";

        }else if(pressed_key=='#'){
          if(input_angle_str.length()>0){
            int parsed_angle=input_angle_str.toInt();
            if(parsed_angle>=0 && parsed_angle<=180){
              target_angle=parsed_angle;
              moveServo(target_angle);            
            }
            input_angle_str="";
          }
        }
      }
    }
    vTaskDelay(pdMS_TO_TICKS(50));
  }
}
void vTaskServo(void*pvParameters){
  while(1){
    if(current_mode=='A'){
      if(current_distance>0 && current_distance<=OBSTACLE_THRESHOLD_CM){

    }else{
      int next_angle=current_angle+(5*scan_direction);
      if(next_angle>=180){
        next_angle=180;
        scan_direction=-1;
      }else if(next_angle<=0){
        next_angle=0;
        scan_direction=1;
      }
      moveServo(next_angle);
    }
    }else if(current_mode=='C'){
      int next_angle=current_angle+(scan_direction*2);
      if(next_angle>=180){
        next_angle=180;
        scan_direction=-1;
      }else if(next_angle<=0){
        next_angle=0;
        scan_direction=1;
      }
      moveServo(next_angle);

      Serial1.print(current_angle);
      Serial1.print(",");
      Serial1.print(current_distance);
      Serial1.println("."); 
    }
    vTaskDelay(pdMS_TO_TICKS(50));
  }
}
void moveServo(int angle){
  int destination=constrain(angle,0,180);
  digitalWrite(MOSFET_PIN,HIGH);
  delay(20);
  if(destination>current_angle){
    for(int angle=current_angle;angle<=destination;angle++){
      my_servo.write(angle);
      delay(10);
    }
  }else{
    for(int angle=current_angle;angle>=destination;angle--){
      my_servo.write(angle);
      delay(10);
    }
  }
  current_angle=destination;
  target_angle=destination;  
  digitalWrite(MOSFET_PIN,LOW);  
}

