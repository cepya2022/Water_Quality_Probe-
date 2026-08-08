#include <RTClib.h>
#include <LowPower.h>
#include <DallasTemperature.h>
#include <OneWire.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include "do_grav.h"

// Control de alimentacion: MOSFETs 2N7000 en low-side sobre el GND de cada modulo.
// Gate en HIGH -> conduce -> modulo alimentado. La placa V1.0 no lleva reles.
#define SensorTpin 5
#define bjtpH 57 // A3 o D57 son análogos
#define bjtOD 55 // A1 o D55 son análogos
#define bjtEC 15
#define bjtT 4
#define bjt_RTC 22
#define bjt_SD 48
#define SSpin 53

const unsigned long TIMEOUT_BT_MS = 300000UL; // 5 min de espera max por datos via BT antes de cancelar

// Modo de sueño entre mediciones. Ver dormirUnCiclo().
//   1 = idle      -> el reloj de I/O sigue activo, USART1 recibe mientras duerme:
//                    los comandos BT NO se pierden. Consume ~8-10 mA mas.
//   0 = powerDown -> consumo minimo, pero el USART queda sin reloj y se pierde
//                    todo byte que llegue durante el sueño.
#define SUENO_RECEPTIVO_BT 1

float volt, volt4, volt7; // medición y calibración de pH
float pendiente = -4.040; // nueva calibracion con boya 2.0
float ordenada = 22.600; // nueva calibracion con boya 2.0
unsigned long int avgval;
//int buffer_arr[10], temp;
float pH, T, OD; // guardan el valor de las variables FQ
// Variables escritas desde la interrupcion de BT y leidas en loop()/hacerAccion().
// Deben ser volatile para que el compilador no las cachee en registros: minutos es
// la via de escape del for de sueño y datobt corta los while de calibracion.
volatile char datobt;
volatile int minutos = 3; // frecuencia de medicion
int minprev;  // variable auxiliar
int contador = 0;
char ODon = 'b'; // prendido/apagado del sensor
char ECon = 'b'; // prendido/apagado del sensor
char pHon = 'b'; // prendido/apagado del sensor
char Ton = 'b'; // prendido/apagado del sensor
char eliminar = 'b'; // eliminar datos de la SD
volatile char medir = 'b';
char onprev = 'b';  // variable auxiliar
char calEC = 'b';  // calibración conductímetro
char calOD = 'b'; // calibración oxímetro
char calpH = 'b'; // calibración pH
char rectapH = 'b'; // variable auxiliar
char datosEC = 'b'; // enviar datos
char datosOD = 'b'; // enviar datos
char datospH = 'b'; // enviar datos
char datosT = 'b'; // enviar datos
char datosReloj = 'b'; // enviar datos
char enviar = 'b'; // enviar datos
volatile char cambioEstado = 'b'; // registra cambios en la configuracion
char consultarEstado = 'b'; // pide relectura/impresion del estado guardado en la SD
float punto1, punto2 = 0; // calibración conductímetro
float puntoStd = 12880; // calibración conductímetro
String fecha = ""; // valor de la fecha y hora actual
//float punto = 0; // pto de medición (nro. de estación, ubicación, id, etc)
String punto = ""; // pto de medición (nro. de estación, ubicación, id, etc)
String frecuencia = "";
volatile int pos;  // variable auxiliar
char titulo = 'b'; // variable auxiliar
char apagar = 'b';
String receivedString = ""; // variable auxiliar

String EC = "";                             //a string to hold the data from the Atlas Scientific product
String TDS = "";
String sensorstring = "";                             //a string to hold the data from the Atlas Scientific product

Gravity_DO DO = Gravity_DO(A0);
File datos;
File estadoprev;
RTC_DS3231 rtc;
DateTime dt (__DATE__, __TIME__);
OneWire oneWireObjeto(SensorTpin);
DallasTemperature sensorT(&oneWireObjeto); // para sensor DS18B20. Pasa referencia, no valor

void setup() {  
  apagarPines();
  delay(100);
  Serial1.begin(9600); //cambio a 9600 pq es un HC-06 (ORIGINAL 38400)
  delay(1000);
  attachInterrupt(digitalPinToInterrupt(19), interrupcionBT, RISING); // 19 xq en el mega Serial1 es 19 y 18 para TX y RX
  setearPines();
  delay(100);
  //Serial.begin(9600);
  //corregirReloj(); // COMENTAR UNA VEZ AJUSTADA Y VOLVER A SUBIR
  chequearEstado();
  delay(1000);
}

// Duerme un bloque de 4 s. Despierta antes si llega algo por BT.
void dormirUnCiclo(){
#if SUENO_RECEPTIVO_BT
  // SLEEP_MODE_IDLE: se detiene el CPU pero sigue el reloj de I/O, asi USART1
  // (Bluetooth, pines 18/19) recibe los bytes que lleguen durante el sueño.
  // IMPORTANTE: en modo idle CUALQUIER interrupcion habilitada despierta al MCU.
  // Por eso hay que apagar TODOS los timers: si TIMER0 queda encendido, su
  // desborde de ~1 ms (el de millis()) despertaria al equipo enseguida y esta
  // funcion volveria a los ~1 ms en lugar de a los 4 s, achicando el intervalo
  // de medicion unas 4000 veces. Asi solo despiertan el watchdog o el BT.
  LowPower.idle(SLEEP_4S, ADC_OFF,
                TIMER5_OFF, TIMER4_OFF, TIMER3_OFF, TIMER2_OFF, TIMER1_OFF, TIMER0_OFF,
                SPI_OFF,
                USART3_OFF, USART2_OFF, USART1_ON, USART0_OFF,
                TWI_OFF);
#else
  LowPower.powerDown(SLEEP_4S, ADC_OFF, BOD_OFF);
#endif
}

void loop() {
  if (cambioEstado == 'a'){
    guardarEstado();
  }
  delay(1000); // ver si puedo bajar este delay
  for (int i = 0; i < minutos; i++){
    dormirUnCiclo();
  }
  hacerAccion();
}

bool guardarPunto(){
  Serial1.flush();
  Serial1.println(F("Escribir punto de mediciones:"));
  delay(300);
  punto = "";
  delay(200);
  unsigned long t0 = millis();
  while (punto == "" || (int)punto[0] == 10){
    if (Serial1.available()){
      punto = Serial1.readStringUntil('\r');
    }
    if (millis() - t0 > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      medir = 'b';
      titulo = 'b';
      cambioEstado = 'a';
      return false;
    }
  }
  //delay(100);
  Serial1.print(F("Nuevo punto: "));
  Serial1.println(punto);
  delay(500);
  Serial1.println(F("Indique frecuencia de medición:"));
  frecuencia = "";
  //while (frecuencia[0] != 'n' || frecuencia[0] != 'h' || frecuencia[0] != 'q' || frecuencia[0] != 't' || frecuencia[0] != 'o'){
  t0 = millis();
  while (frecuencia == ""){
    //frecuencia = "";
    if (Serial1.available()){
      frecuencia = Serial1.readStringUntil('\r');
    }
    if (millis() - t0 > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      medir = 'b';
      titulo = 'b';
      cambioEstado = 'a';
      return false;
    }
  }
  delay(100);
  if (frecuencia[0] == 'n'){minprev = 3;}
  else if (frecuencia[0] == 'h'){minprev = 70;}
  else if (frecuencia[0] == 'q'){minprev = 216;}
  else if (frecuencia[0] == 'o'){minprev = 14;}
  else {minprev = 441;}
  delay(300);
  //Serial1.print(F("punto guardado: "));
  //Serial1.println(punto);
  Serial1.print(F("frecuencia de medición: "));
  Serial1.println(minprev/15);
  delay(200);
  guardarEstado();
  delay(100);
  //Serial1.println(F("a medir"));
  titulo = 'a';
  delay(100);
  return true;
}

void hacerTodo(){
  if (titulo == 'b'){
    if (!guardarPunto()){
      return;
    }
  }
  delay(500);
  Serial1.println(F("a medir"));
  delay(100);
  medirpH(0);
  delay(100);
  medirT();
  delay(100);
  medirEC();
  delay(100);
  medirOD();
  delay(100);
  obtenerFecha();
  delay(100);
  pegarDatosEnSD();
  //delay(100);
  //mostrarDatosEnSerial();
}

/*void mostrarDatosEnSerial(){
  Serial.print(fecha);
  Serial.print(';');
  Serial.print(OD);
  Serial.print(';');
  Serial.print(EC);
  Serial.print(';');
  Serial.print(pH);
  Serial.print(';');
  Serial.print(T);
  Serial.print(';');
  Serial.println(punto);
}*/

void medirOD(){
  digitalWrite(bjtOD, HIGH);
  delay(100);
  if(DO.begin()){
    //Serial.println(F("Loaded EEPROM"));
  }
  OD = DO.read_do_percentage(); 
  if (ODon == 'b'){
    digitalWrite(bjtOD, LOW);  
  }
}

void medirT(){
  digitalWrite(bjtT, HIGH);
  delay(100);
  sensorT.begin();
  sensorT.requestTemperatures();
  T = sensorT.getTempCByIndex(0);
  if (T == -127){
    Serial1.println(F("Error: sensor de T desconectado o fallo de lectura"));
  }
  delay(100);
  if (Ton == 'b'){
    digitalWrite(bjtT, LOW);
  }
}

void setearRectapH(){
  float pendienteAnterior = pendiente;
  float ordenadaAnterior = ordenada;
  Serial1.println(F("mandar valor de pendiente"));
  pendiente = 0;
  delay(100);
  unsigned long t0pH = millis();
  while (pendiente == 0){
    if (Serial1.available()){
      pendiente = Serial1.parseFloat();
    }
    if (millis() - t0pH > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      pendiente = pendienteAnterior;
      ordenada = ordenadaAnterior;
      minutos = minprev;
      medir = onprev;
      rectapH = 'b';
      return;
    }
  }
  delay(100);
  Serial1.println(F("mandar valor de ordenada"));
  ordenada = 0;
  delay(100);
  t0pH = millis();
  while (ordenada == 0){
    if (Serial1.available()){
      ordenada = Serial1.parseFloat();
    }
    if (millis() - t0pH > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      ordenada = ordenadaAnterior;
      minutos = minprev;
      medir = onprev;
      rectapH = 'b';
      return;
    }
  }
  delay(100);
  Serial1.println(F("recta de calibracion de pH seteada"));
  minutos = minprev;
  medir = onprev;
  rectapH = 'b';
  delay(100);
  guardarEstado();
  delay(200);
}

void calibrarPeachimetro(){
  digitalWrite(bjtpH, HIGH);
  delay(100);
  datobt = ' ';
  Serial1.println(F("poner sonda en sn standard 7 y apretar una vez boton OK"));
  delay(100);
  Serial1.println(F("recomendacion: esperar 3 min a que equilibre"));
  unsigned long t0 = millis();
  while(datobt != 'k'){
    if (Serial1.available()){
      datobt = Serial1.read();
      t0 = millis();
    }
    if (datobt == 'a'){
      break;
    }
    if (datobt == 'P'){
      mandarpH();
    }
    if (millis() - t0 > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      datobt = 'a';
      break;
    }
  }
  switch(datobt){
    case 'k':
    medirpH(7);
    datobt = ' ';
    Serial1.println(F("poner sonda en sn standrad 4 y apretar una vez boton OK"));
    t0 = millis();
    while(datobt != 'k'){ // cambiar aca por datobt?
      if (Serial1.available()){
        datobt = Serial1.read();
        t0 = millis();
      }
      if (datobt == 'a'){
        break;
      }
      if (datobt == 'P'){
        mandarpH();
      }
      if (millis() - t0 > TIMEOUT_BT_MS){
        Serial1.println(F("Tiempo de espera agotado, cancelando"));
        datobt = 'a';
        break;
      }
    }
    switch (datobt){
      case 'k':
      medirpH(4);
      Serial1.println(F("pH-metro calibrado"));
      break;      
    
      case 'a':
      Serial1.println(F("de baja la calibracion"));
      break;
    }
    break;
    
    case 'a':
    Serial1.println(F("de baja la calibracion"));
    break;
  }
  minutos = minprev;
  medir = onprev;
  calpH = 'b';
  datospH = 'b';
  delay(100);
  digitalWrite(bjtpH, LOW);

  guardarEstado();
  delay(200);
}

void medirpH(int p){
  digitalWrite(bjtpH, HIGH);
  for (int i = 0; i < 2; i++){ // para que este 3 sec hasta medir
    delay(1000);    
  }
  avgval = 0;
  for (int i = 0; i < 10; i++)
  {
    avgval += analogRead(A2);
    delay(10);
  }
  volt = (float)avgval * 4.941 / 1023 / 10; // cambiar aca el 4.96. 
  //pH = pendiente * volt + ordenada;
  switch(p){
    case 0:
    pH = pendiente * volt + ordenada;
    delay(100);
    if (pHon == 'b'){
      digitalWrite(bjtpH, LOW);
    }
    break;
    
    case 4:
    volt4 = volt;
    pendiente = 3 / (volt7 - volt4);
    ordenada = 7 - (pendiente * volt7);
    break;

    case 7:
    volt7 = volt;
    break;    
  }
}

void mandarOD(){
  char ODonAnterior = ODon;
  ODon = 'a'; // mantener encendido durante las 10 lecturas, evitar ciclar el rele
  for (int i = 0 ; i < 10 ; i++){
    medirOD();
    Serial1.print(F("OD = "));
    Serial1.println(OD);
    delay(100);
  }
  ODon = ODonAnterior;
  if (ODon == 'b'){
    digitalWrite(bjtOD, LOW);
  }
  minutos = minprev;
  medir = onprev;
  datosOD = 'b';
  //datospH = 'a';
}

void mandarpH(){
  char pHonAnterior = pHon;
  pHon = 'a'; // mantener encendido durante las 10 lecturas, evitar ciclar el rele
  for (int i = 0 ; i < 10 ; i++){
    medirpH(0);
    Serial1.print(F("pH = "));
    Serial1.println(pH);
    Serial1.print(F("volt = "));
    Serial1.println(volt);
    delay(100);
  }
  pHon = pHonAnterior;
  if (pHon == 'b'){
    digitalWrite(bjtpH, LOW);
  }
  minutos = minprev;
  medir = onprev;
  datospH = 'b';
}

void mandarEC(){
  medirT();
  //T = 28;
  medirEC();
  Serial1.print(F("EC = "));
  Serial1.println(EC);
  Serial1.print(F("TDS = "));
  Serial1.println(TDS);
  minutos = minprev;
  medir = onprev;
  datosEC = 'b';
  EC = "";
  TDS = "";
}

void mandarT(){
  char TonAnterior = Ton;
  Ton = 'a'; // mantener encendido durante las 10 lecturas, evitar ciclar el rele
  for (int i = 0 ; i < 10 ; i++){
    medirT();
    Serial1.print(F("T = "));
    Serial1.println(T);
    delay(100);
  }
  Ton = TonAnterior;
  if (Ton == 'b'){
    digitalWrite(bjtT, LOW);
  }
  minutos = minprev;
  medir = onprev;
  datosT = 'b';
}

void mandarReloj(){
  obtenerFecha();
  Serial1.print(F("fecha: "));
  Serial1.println(fecha);  
  minutos = minprev;
  medir = onprev;
  datosReloj = 'b';
  // obtenerFecha() ya deja el RTC apagado
}

void pegarDatosEnSD(){
  digitalWrite(bjt_SD, HIGH); // alimentar la SD antes de escribir (MOSFET low-side: HIGH = encendido)
  delay(1000);
  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial1.println(F("memoria encontrada !"));
  }else{
    Serial1.println(F("Memoria no encontrada!"));
  }
  datos = SD.open("mega.txt", FILE_WRITE);
  if (datos){
    //Serial1.println(F("abrio el archivo"));
    datos.print(fecha);
    datos.print(';');
    datos.print(OD);
    datos.print(';');
    datos.print(EC);
    datos.print(';');
    datos.print(TDS);
    datos.print(';');
    datos.print(pH);
    datos.print(';');
    datos.print(T);
    datos.print(';');
    datos.println(punto);
    datos.close();
  }else{
    Serial1.println(F("No abrio el archivo"));
  }

  digitalWrite(bjt_SD, LOW);
  delay(100);

  EC = "";
  TDS = "";
}

void chequearEstado(){
  Serial1.println(F("Voy a mirar los datos"));
  delay(200);
  //delay(1000);
  digitalWrite(bjt_SD, HIGH);
  delay(1000);
  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial.println(F("memoria encontrada !"));
  }else{
    //digitalWrite(LedPin, HIGH);
    Serial1.println(F("memoria no encontrada !"));
    //Serial1.println(F("no encontro la memoria"));
    //digitalWrite(13, HIGH);
  }
  estadoprev = SD.open("estado.txt");
  if (estadoprev){
    estadoprev.seek(0);
    delay(500);
    receivedString = estadoprev.readStringUntil('\n');
    delay(500);
    
    delay(100);
    estadoprev.close();
    delay(100);

  }else{
    Serial1.println(F("No hay estado previo"));
  }
  delay(100);
  digitalWrite(bjt_SD, LOW);
  delay(100);

  int posi = receivedString.indexOf(';');
      if (posi != -1) {
        String token1 = receivedString.substring(0, posi);
        receivedString = receivedString.substring(posi + 1);

        posi = receivedString.indexOf(';');
        if (posi != -1) {
          String token2 = receivedString.substring(0, posi);
          receivedString = receivedString.substring(posi + 1);
        
          posi = receivedString.indexOf(';');
          if (posi != -1) {
            String token3 = receivedString.substring(0, posi);
            receivedString = receivedString.substring(posi + 1);

            posi = receivedString.indexOf(';');
            if (posi != -1) {
              String token4 = receivedString.substring(0, posi);
              receivedString = receivedString.substring(posi + 1);
            
              posi = receivedString.indexOf(';');
              if (posi != -1) {
                String token5 = receivedString.substring(0, posi);
                receivedString = receivedString.substring(posi + 1);

                pendiente = token1.toFloat();
                ordenada = token2.toFloat();
                medir = token3.charAt(0);
                minprev = token4.toInt(); // restaurar tambien minprev: guardarEstado() hace minutos = minprev
                minutos = minprev;
                punto = token5;
                contador = receivedString.toInt();
                if (medir == 'b'){
                  titulo = 'b';
                  minprev = 0; // sin medicion no se duerme, para no quedar sordo al BT
                  minutos = 0;
                }
                else {
                  titulo = 'a';
                  contador += 1;
                }
              }
            }
          }
        }
      }

  Serial1.print(F("m = "));
  Serial1.println(pendiente);
  Serial1.print(F("O.O. = "));
  Serial1.println(ordenada);
  Serial1.print(F("Medir: "));
  Serial1.println(medir);
  Serial1.print(F("Frecuencia (minutos): "));
  Serial1.println(minutos/15);
  Serial1.print(F("Punto: "));
  Serial1.println(punto);
  Serial1.print(F("Reinicios: "));
  Serial1.println(contador);
}

void guardarEstado(){
  delay(1000);
  digitalWrite(bjt_SD, HIGH);
  delay(1000);

  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial.println(F("memoria encontrada !"));
  }else{
    //digitalWrite(LedPin, HIGH);
    Serial1.println(F("memoria no encontrada !"));
    //Serial1.println(F("no encontro la memoria"));
    //digitalWrite(13, HIGH);
  }
  
  estadoprev = SD.open("estado.txt", FILE_WRITE | O_TRUNC);
  if (estadoprev){

    estadoprev.print(pendiente);
    estadoprev.print(';');
    estadoprev.print(ordenada);
    estadoprev.print(';');
    estadoprev.print(medir);
    estadoprev.print(';');
    estadoprev.print(minprev);
    estadoprev.print(';');
    estadoprev.print(punto);
    estadoprev.print(';');
    estadoprev.print(contador);
    delay(100);
    estadoprev.close();
    delay(100);

    Serial1.println(F("Cambios guardados"));
  }else{
    Serial1.println(F("Cambios no guardados"));
  }

  digitalWrite(bjt_SD, LOW);
  delay(100);
  delay(100);

  cambioEstado = 'b';
  minutos = minprev;
}

void mandarDatos(){
  delay(1000);
  digitalWrite(bjt_SD, HIGH);
  delay(1000);
  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial.println(F("memoria encontrada !"));
  }else{
    Serial1.println(F("Memoria no encontrada!"));
  }
  datos = SD.open("mega.txt");
  if (datos){
    //Serial.println(F("abrio el archivo"));
    datos.seek(pos);
    while (datos.available()){
    //while (pos<10){
      Serial1.write(datos.read());
      pos++;
    }
    datos.close();
    Serial1.println(F("Datos enviados."));
  }
  else{
    //digitalWrite(LedPin, HIGH);
    //Serial1.println(F("no pudo abrir el archivo"));
    //digitalWrite(13, HIGH);
    Serial1.println(F("No abrio el archivo"));  
  }
  minutos = minprev;
  medir = onprev;
  enviar = 'b';
  delay(100);
  digitalWrite(bjt_SD, LOW);
  delay(100);
  delay(100);
}

void eliminarArchivo(){
  char e = ' ';
  while (e == ' '){
    if (Serial1.available()){
      e = Serial1.read();
    }
  }
  switch (e){
    case 'k':
    digitalWrite(bjt_SD, HIGH);
    delay(100);
    delay(100);
    if (SD.begin(SSpin)){
      if (SD.exists("mega.txt")){
       SD.remove("mega.txt");
       Serial1.println(F("Archivo eliminado"));
      }else{
        Serial1.println(F("El archivo no existe"));
        //digitalWrite(13, HIGH);
     }
    }else{
     Serial1.println(F("No pudo eliminar el archivo"));
      //digitalWrite(13, HIGH);
    }
    delay(100);
    digitalWrite(bjt_SD, LOW);
    delay(100);
    minutos = minprev;
    medir = onprev;
    eliminar = 'b';
    break;

    case 'a':
    //Serial1.println(F("aaasa te asustaste"));
    Serial1.println(F("Cancelado"));
    break;
  }
}

void obtenerFecha(){
  delay(100);
  digitalWrite(bjt_RTC, HIGH);
  delay(100);
  if (rtc.begin()){
    dt = rtc.now();
  }else{
    Serial1.println(F("Error: no se pudo leer el reloj"));
  }
  fecha = String(dt.day()) + "/" + String(dt.month()) + "/" + String(dt.year()) + ";" + String(dt.hour()) + ":" + String(dt.minute()) + ":" + String(dt.second());
  delay(100);
  digitalWrite(bjt_RTC, LOW); // el DS3231 mantiene la hora con su pila de respaldo
}

void corregirReloj(){
  delay(100);
  digitalWrite(bjt_RTC, HIGH);
  delay(100);
  if (rtc.begin()){
    Serial.println(F("reloj bien"));
  }else{
    Serial.println(F("reloj mal"));
  }  
  rtc.adjust(dt); 
  obtenerFecha();
  Serial.print(fecha);
  delay(100);
  digitalWrite(bjt_RTC, LOW);
  delay(100);
}
  
void medirEC(){
  char sensorstring_array[30]; 
  EC = "";
  digitalWrite(bjtEC, HIGH);
  delay(1500);
  Serial2.begin(9600); // Serial2 en el Mega es TX2 (D16) y RX2 (D17), cableado al modulo de conductividad
  delay(1500);
  //Serial2.print(F("O,TDS,1"));
  //Serial2.print('\r');
  //EC = Serial2.readStringUntil(13);
  //Serial1.println(EC);
  //Serial2.listen();  
  /*while (Serial2.available() > 0) {                     //if we see that the Atlas Scientific product has sent a character
    char inchar = (char)Serial2.read();              //get the char we just received
    if (isdigit(inchar) || inchar == '.'){
      EC += inchar;  // aca esta leyendo lo del sensor                         //add the char to the var called sensorstring
    }
    if (inchar == '\r') {                             //if the incoming character is a <CR>
      break;
    }
  }*/
  Serial2.print(F("RT,"));
  Serial2.print(T);  // chequear que esto funcione
  Serial2.print('\r');
  delay(1200);
  sensorstring = Serial2.readStringUntil(13);
  sensorstring.toCharArray(sensorstring_array, 30);   //convert the string to a char array
  char* tokEC = strtok(sensorstring_array, ",");      //let's pars the array at each comma
  char* tokTDS = strtok(NULL, ",");
  EC = (tokEC != NULL) ? String(tokEC) : "";          // respuesta inesperada del sensor: no sobreescribir con basura
  TDS = (tokTDS != NULL) ? String(tokTDS) : "";
  delay(100);
  Serial2.end();
  if (ECon == 'b'){
    digitalWrite(bjtEC, LOW); 
  }
}

// calibrar EC con 1 o 2 puntos que quiera

void calibrarEC(){
  delay(100);
  Serial1.println(F("Enviar 'OK' para 2 puntos o 'EC 1 pto' para 1"));
  delay(100);
  unsigned long t0EC = millis();
  while(datobt != 'k'){ // esto lo podria cambiar, y poner simplemente en vez de datobt, un char nuevo vacio y que el while sea mientras siga valiendo '', y cuando recibe algo sale
    if (Serial1.available()){
      datobt = Serial1.read(); // ver si aca puede recibir una palabra
      t0EC = millis();
    }
    if (datobt == 'a' || datobt == 'S' || datobt == 'D'){
      break;
    }
    if (millis() - t0EC > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      datobt = 'a';
      break;
    }
  }
  char c = ' ';
  switch(datobt){
    case 'D': // para 1 punto
    Serial1.println(F("mandar valor de punto"));
    punto1 = 0;
    delay(100);
    t0EC = millis();
    while (punto1 == 0){
      if (Serial1.available()){
        punto1 = Serial1.parseFloat();
        c = Serial1.read(); // ver si funciona esto para dar de baja la calibracion del EC en el medio
        if (c == 'a'){
          break;
        }
      }
      if (millis() - t0EC > TIMEOUT_BT_MS){
        Serial1.println(F("Tiempo de espera agotado, cancelando"));
        c = 'a';
        break;
      }
    }
    switch (c){
      case 'a':
      Serial1.println(F("de baja la calibracion"));
      break;

      default:
      digitalWrite(bjtEC, HIGH);
      delay(1200);
      Serial2.begin(9600);
      delay(1200);
      Serial2.print(F("cal,"));
      Serial2.print(punto1);  // chequear que esto funcione
      Serial2.print('\r');                             //add a <CR> to the end of the string
      delay(100);
      Serial1.println(Serial2.readStringUntil(13));
      delay(100);
      Serial2.end();
      digitalWrite(bjtEC, LOW);
      Serial1.println(F("EC cal"));
      delay(100);
      break;
    }
    break;
    /*digitalWrite(bjtEC, HIGH);
    delay(1200);
    Serial2.begin(9600);
    delay(1200);
    Serial2.print(F("cal,"));
    Serial2.print(punto1);  // chequear que esto funcione
    Serial2.print('\r');                             //add a <CR> to the end of the string
    delay(100);
    Serial1.println(Serial2.readStringUntil(13));
    delay(100);
    Serial2.end();
    digitalWrite(bjtEC, LOW);
    Serial1.println(F("EC cal"));
    delay(100);
    break;*/
    
    case 'k': // para 2 puntos
    Serial1.println(F("mandar valor de 1er punto (menor)"));
    punto1 = 0;
    delay(100);
    t0EC = millis();
    while (punto1 == 0){
      if (Serial1.available()){
        punto1 = Serial1.parseFloat();
        c = Serial1.read(); // ver si funciona esto para dar de baja la calibracion del EC en el medio
        if (c == 'a'){
          break;
        }
      }
      if (millis() - t0EC > TIMEOUT_BT_MS){
        Serial1.println(F("Tiempo de espera agotado, cancelando"));
        c = 'a';
        break;
      }
    }
    switch (c){
      case 'a':
      Serial1.println(F("de baja la calibracion"));
      break;

      default:
      digitalWrite(bjtEC, HIGH);
      delay(1200);
      Serial2.begin(9600);
      delay(1200);
      Serial2.print(F("cal,low,"));
      Serial2.print(punto1);  // chequear que esto funcione
      Serial2.print('\r');                             //add a <CR> to the end of the string
      delay(100);
      Serial1.println(Serial2.readStringUntil(13));
      Serial2.end();
      digitalWrite(bjtEC, LOW);
      Serial1.println(F("mandar valor de 2do punto (mayor)"));
      punto2 = 0;
      delay(100);
      t0EC = millis();
      while (punto2 == 0){
        if (Serial1.available()){
          punto2 = Serial1.parseFloat();
        }
        c = Serial1.read(); // ver si funciona esto para dar de baja la calibracion del EC en el medio
        if (c == 'a'){
          break;
        }
        if (millis() - t0EC > TIMEOUT_BT_MS){
          Serial1.println(F("Tiempo de espera agotado, cancelando"));
          c = 'a';
          break;
        }
      }
      switch (c){
        case 'a':
        Serial1.println(F("de baja la calibracion"));
        break;                
        
        default:
        digitalWrite(bjtEC, HIGH);
        delay(1200);
        Serial2.begin(9600);
        delay(1200);
        Serial2.print(F("cal,high,"));
        Serial2.print(punto2);  // chequear que esto funcione
        Serial2.print('\r');                             //add a <CR> to the end of the string
        delay(100);
        Serial1.println(Serial2.readStringUntil(13));
        delay(100);
        Serial2.end();
        digitalWrite(bjtEC, LOW);
        Serial1.println(F("EC cal"));
        break;
      }
    }
    break;

    case 'S':
    Serial1.println(F("calibrando con punto Std"));
    digitalWrite(bjtEC, HIGH);
    delay(1200);
    Serial2.begin(9600);
    delay(1200);
    Serial2.print(F("cal,"));
    Serial2.print(puntoStd);  // chequear que esto funcione
    Serial2.print('\r');                             //add a <CR> to the end of the string
    delay(100);
    Serial2.end();
    digitalWrite(bjtEC, LOW);
    Serial1.println(F("EC cal"));
    break;

    case 'a':
    Serial1.println(F("de baja la calibracion"));
    break;
  }
  delay(100);
  minutos = minprev;
  medir = onprev;
  calEC = 'b';
}

void calibrarOD(){
  digitalWrite(bjtOD, HIGH);
  delay(100);
  if(DO.begin()){
    //Serial.println(F("Loaded EEPROM"));
  }
  Serial1.println(F("sn sat 100 y OK"));
  unsigned long t0OD = millis();
  while(datobt != 'k'){
    if (Serial1.available()){
      datobt = Serial1.read();
      t0OD = millis();
      //Serial1.println(DO.read_do_percentage()); --> se manda solo cuando apreto algo, raro. Y no se si me deja cancelar
    }
    if (datobt == 'a'){
      break;
    }
    if (millis() - t0OD > TIMEOUT_BT_MS){
      Serial1.println(F("Tiempo de espera agotado, cancelando"));
      datobt = 'a';
      break;
    }
    //Serial1.println(DO.read_do_percentage()); --> aca se manda perfecto siempre pero tarda mucho en cancelar (dar ok no probe)
  }
  switch(datobt){
    case 'k':
    DO.cal();
    Serial1.println(F("OD cal a 100"));  
    break;

    case 'a':
    Serial1.println(F("de baja la calibracion"));
    break;
  }
  digitalWrite(bjtOD, LOW);
  delay(100);
  minutos = minprev;
  medir = onprev;
  calOD = 'b';
}

void interrupcionBT(){
  //if (Serial1.available()){
    datobt = Serial1.read();
  //}
  switch(datobt){
    case 'v':
    Serial1.print(F("m = "));
    Serial1.println(pendiente);
    Serial1.print(F("O.O. = "));
    Serial1.println(ordenada);
    break;
    
    case 'o':
    minprev = 14; // tendría 1 seg más de delay con los 3200
    minutos = 0;
    //msdelay = 2200;
    Serial1.println(F("1 min"));
    cambioEstado = 'a';
    //guardarEstado();
    break;

    case 'q':
    minprev = 216; // 
    minutos = 0;
    //msdelay = 2200;
    Serial1.println(F("15 min"));
    cambioEstado = 'a';
    //guardarEstado();
    break;

    case 't':
    minprev = 441; // tendría 2 seg más de delay con los 3200 (en realidad eran 26 o 27 seg, no 30 --> puse 443 en vez de 442) --> 1er prueba: +8 seg, pongo en 441
    minutos = 0;
    //msdelay = 1200;
    Serial1.println(F("30 min"));
    cambioEstado = 'a';
    //guardarEstado();
    break;

    case 'h':
    minprev = 70; // 
    minutos = 0;
    //msdelay = 1200;
    Serial1.println(F("5 min"));
    cambioEstado = 'a';
    //guardarEstado();
    break;

    /*case '6':
    minutos = 887; // tendría 1 seg menos de delay con los 3200 (si lo dejaba en 884, pero lo puse en 885 y msdelay = 200) --> eran 51 seg, no 60 --> puse 887 y 1200 en vez de 885 y 200
    //msdelay = 1200;
    BLT.println(F("1 hora"));
    break;*/

    case 'n':
    minprev = 3;
    minutos = 0;
    Serial1.println(F("15 seg"));
    cambioEstado = 'a';
    //guardarEstado();
    break;

    case 'g': 
    medir = 'a';
    //guardarEstado();
    //Serial1.println(F("a medir"));
    Serial1.println(F("Configurar medición"));
    break;
      
    case 'r':
    medir = 'b';
    titulo = 'b';
    //punto = "";
    // Con la medicion apagada NO se duerme: minprev = 0 hace que el for de loop()
    // no se ejecute y el equipo quede siempre despierto y receptivo al BT.
    // (Al dormir, el USART no tiene reloj y se pierden los bytes que llegan.)
    minprev = 0;
    minutos = 0;
    Serial1.println(F("apagando..."));
    cambioEstado = 'a';
    //guardarEstado();
    //Serial1.println(F("off"));
    break;

    case 'y': 
    Serial1.println(F("ahi te mando"));
    enviar = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'w': 
    Serial1.println(F("ahi te mando"));
    pos = 0;
    enviar = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'X': 
    Serial1.println(F("datos OD"));
    datosOD = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;
    
    case 'P': 
    Serial1.println(F("datos pH"));
    datospH = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'Z': 
    Serial1.println(F("datos EC"));
    datosEC = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'R': 
    Serial1.println(F("reloj"));
    datosReloj = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;
    
    case 'T': 
    Serial1.println(F("datos T"));
    datosT = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case '%':
    rectapH = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case '#': // dejar prendido EC
    ECon = 'a';
    Serial1.println(F("mantener EC on"));
    break;

    case '@': // dejar prendido OD
    ODon = 'a';
    Serial1.println(F("mantener OD on"));
    break;

    case '-': // dejar prendido pH
    pHon = 'a';
    Serial1.println(F("mantener pH on"));
    break;

    case '&':
    apagar = 'a';
    ECon = 'b';
    ODon = 'b';
    pHon = 'b';
    Serial1.println(F("mantener todos apagados"));
    break;

    case '?':
    Serial1.print(F("cada "));
    Serial1.print(minutos/15); 
    Serial1.print(F(" minutos ; estado = "));
    Serial1.println(medir);
    break;

    case 'd':
    Serial1.println(F("cal EC"));
    calEC = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'c':
    Serial1.println(F("cal pH"));
    calpH = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'e':
    Serial1.println(F("eliminar archivo? seguro?"));
    //Serial1.println(F("eliminando..."));
    eliminar = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;
    
    case 'O':
    Serial1.println(F("cal OD"));
    calOD = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 's':
    digitalWrite(bjtpH, !digitalRead(bjtpH));
    break;

    case 'b':
    consultarEstado = 'a';
    minutos = 0;
    break;

    case 'm':
    cambioEstado = 'a';
    minutos = 0;
    break;
  }
}

void hacerAccion(){
  if (cambioEstado == 'a'){
    guardarEstado();
  }
  if (consultarEstado == 'a'){
    chequearEstado();
    consultarEstado = 'b';
  }
  if (medir == 'a'){
    hacerTodo();
  }
  if (enviar == 'a'){
    mandarDatos();
  }
  if (eliminar == 'a'){
    eliminarArchivo();
  }
  if (calEC == 'a'){
    calibrarEC();
  }
  if (calOD == 'a'){
    calibrarOD();
  }
  if (calpH == 'a'){
    calibrarPeachimetro();
  }
  if (datosOD == 'a'){
    mandarOD();
  }
  if (datospH == 'a'){
    mandarpH();
  }
  if (datosEC == 'a'){
    mandarEC();
  }
  if (datosT == 'a'){
    mandarT();
  }
  if (datosReloj == 'a'){
    mandarReloj();
  }
  if (rectapH == 'a'){
    setearRectapH();
  }
  if (apagar == 'a'){
    setearPines();
    apagar = 'b';
  }
}

void setearPines(){
  pinMode(bjtT, OUTPUT);
  digitalWrite(bjtT, LOW);
  pinMode(bjtpH, OUTPUT);
  digitalWrite(bjtpH, LOW);
  pinMode(bjtEC, OUTPUT);
  digitalWrite(bjtEC, LOW);
  pinMode(bjtOD, OUTPUT);
  digitalWrite(bjtOD, LOW);
  pinMode(bjt_RTC, OUTPUT);
  digitalWrite(bjt_RTC, LOW);
  pinMode(bjt_SD, OUTPUT);
  digitalWrite(bjt_SD, LOW);
}

void apagarPines(){
  //pinMode(A0, OUTPUT);
  //pinMode(A1, OUTPUT);
  //pinMode(A2, OUTPUT);
  //pinMode(A3, OUTPUT);
  pinMode(A4, OUTPUT);
  pinMode(A5, OUTPUT);
  pinMode(A6, OUTPUT);
  pinMode(A7, OUTPUT);
  pinMode(A8, OUTPUT);
  pinMode(A9, OUTPUT);
  pinMode(A10, OUTPUT);
  pinMode(A11, OUTPUT);
  pinMode(A12, OUTPUT);
  pinMode(A13, OUTPUT);
  pinMode(A14, OUTPUT); 
  pinMode(A15, OUTPUT);

  //digitalWrite(A0, LOW);
  //digitalWrite(A1, LOW);
  //digitalWrite(A2, LOW);
  //digitalWrite(A3, LOW);
  digitalWrite(A4, LOW);
  digitalWrite(A5, LOW);
  digitalWrite(A6, LOW);
  digitalWrite(A7, LOW);
  digitalWrite(A8, LOW);
  digitalWrite(A9, LOW);
  digitalWrite(A10, LOW);
  digitalWrite(A11, LOW);
  digitalWrite(A12, LOW);
  digitalWrite(A13, LOW);
  digitalWrite(A14, LOW);
  digitalWrite(A15, LOW);
  /*for (int i = 0; i <= 53; i++) {
    if (i == 4 || i == 5 || i == 6 || i == 7 || i == 8 || i == 9 || i == 10 || i == 11 || i == 12 || i == 14 || i == 15 || i == 16 || i == 17 || i == 18 || i == 19 || i == 20 || i == 22 || i == 48 || i == 49 || i == 50 || i == 51 || i == 52 || i == 53|| i == 55 || i == 57){
      
    }else{
      pinMode(i, OUTPUT);
      digitalWrite(i, LOW);
    }
  }*/
}

