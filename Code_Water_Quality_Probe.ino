#include <RTClib.h>
#include <LowPower.h>
#include <SoftwareSerial.h>
#include <DallasTemperature.h>
#include <OneWire.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include "do_grav.h"

#define SSpin 4
#define SensorTpin 5
#define bjtT 12
#define bjtpH 11
#define bjtSD_RTC 10 
#define bjtEC 9 
#define bjtOD 8 

//float analogValBat, voltBat = 0;
float volt, volt4, volt7;
float pendiente = -4.64; // nueva calibracion con boya 2.0
float ordenada = 22.08; // nueva calibracion con boya 2.0
unsigned long int avgval;
//int buffer_arr[10], temp;
float pH, T, OD;
char datobt;
int minutos = 5;
int minprev;
char ODon = 'b';
char ECon = 'b';
char pHon = 'b';
char bateria, enviar, eliminar, medir, onprev, calEC, calOD, calpH, rectapH, datosEC, datosOD, datospH, datosT, datosReloj = 'b';
float punto1, punto2 = 0;
float puntoStd = 12880;
String fecha;
volatile int pos;

String EC = "";                             //a string to hold the data from the Atlas Scientific product
String sensorstring = "";                             //a string to hold the data from the Atlas Scientific product
boolean sensor_string_complete = false;               //have we received all the data from the Atlas Scientific product

Gravity_DO DO = Gravity_DO(A0);
File datos;
RTC_DS3231 rtc;
DateTime dt (_DATE, __TIME_);
OneWire oneWireObjeto(SensorTpin);
DallasTemperature sensorT(&oneWireObjeto); // para sensor DS18B20. Pasa referencia, no valor

void setup() {  
  //apagarPines();
  attachInterrupt(digitalPinToInterrupt(19), interrupcionBT, RISING); // 19 xq en el mega Serial1 es 19 y 18 para TX y RX
  setearPines();
  //Serial.begin(9600);
