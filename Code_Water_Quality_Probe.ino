#include <RTClib.h>
#include <LowPower.h>
#include <SoftwareSerial.h>
#include <DallasTemperature.h>
#include <OneWire.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>
#include "do_grav.h"

#define SensorTpin 5
#define relepH 6
#define bjtpH 7
#define bjtOD 8
#define releOD 9
#define releEC 10
#define bjtEC 11 
#define releT 12
#define bjtT 13
#define bjtSD_RTC 49
#define releSD_RTC 48
#define SSpin 53

//float analogValBat, voltBat = 0;
float volt, volt4, volt7; // medición y calibración de pH
float pendiente = -4.040; // nueva calibracion con boya 2.0
float ordenada = 22.600; // nueva calibracion con boya 2.0
unsigned long int avgval;
//int buffer_arr[10], temp;
float pH, T, OD; // guardan el valor de las variables FQ
char datobt;
int minutos = 3; // frecuencia de medicion
int minprev;  // variable auxiliar
char ODon = 'b'; // prendido/apagado del sensor
char ECon = 'b'; // prendido/apagado del sensor
char pHon = 'b'; // prendido/apagado del sensor
char bateria = 'b';
char eliminar = 'b'; // eliminar datos de la SD
char medir = 'b';
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
float punto1, punto2 = 0; // calibración conductímetro
float puntoStd = 12880; // calibración conductímetro
String fecha = ""; // valor de la fecha y hora actual
float punto = 0; // pto de medición (nro. de estación, ubicación, id, etc)
volatile int pos;  // variable auxiliar
char titulo = 'b'; // variable auxiliar
char apagar = 'b';
String receivedString = ""; // variable auxiliar

String EC = "";                             //a string to hold the data from the Atlas Scientific product
String sensorstring = "";                             //a string to hold the data from the Atlas Scientific product
boolean sensor_string_complete = false;               //have we received all the data from the Atlas Scientific product

Gravity_DO DO = Gravity_DO(A0);
File datos;
File estadoprev;
RTC_DS3231 rtc;
DateTime dt (__DATE__, __TIME__);
OneWire oneWireObjeto(SensorTpin);
DallasTemperature sensorT(&oneWireObjeto); // para sensor DS18B20. Pasa referencia, no valor

void setup() {  
  //apagarPines();
  //delay(100);
  //Serial.begin(9600); //cambio a 9600 pq es un HC-06 (ORIGINAL 38400)
  //delay(100);
  //Serial3.begin(9600);
  delay(100);
  Serial1.begin(9600); //cambio a 9600 pq es un HC-06 (ORIGINAL 38400)
  delay(1000);
  attachInterrupt(digitalPinToInterrupt(19), interrupcionBT, RISING); // 19 xq en el mega Serial1 es 19 y 18 para TX y RX
  setearPines();
  //Serial.begin(9600);
  //corregirReloj(); // COMENTAR UNA VEZ AJUSTADA Y VOLVER A SUBIR
  chequearEstado();
  delay(1000);
}

void loop() { 
  delay(1000); // ver si puedo bajar este delay
  for (int i = 0; i < minutos; i++){
    LowPower.powerDown(SLEEP_4S, ADC_OFF, BOD_OFF);     
  }
  hacerAccion();
}

void guardarPunto(){
  punto = 0;
  while (punto == 0){
    if (Serial1.available()){
      punto = Serial1.parseFloat();
    }
  }
  //String punto = " ";
  //punto = Serial1.readStringUntil('\r');
  delay(100);
  Serial1.print("punto guardado: ");
  Serial1.println(punto);
  Serial1.println("a medir");
  titulo = 'a';
  delay(100);
  guardarEstado();
}

void hacerTodo(){
  if (titulo == 'b'){
    guardarPunto();
  }
  Serial1.println("a medir");
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
  Serial.print(";");
  Serial.print(OD);
  Serial.print(";");
  Serial.print(EC);
  Serial.print(";");
  Serial.print(pH);
  Serial.print(";");
  Serial.print(T);
  Serial.print(";");
  Serial.println(punto);
}*/

void medirOD(){
  digitalWrite(bjtOD, HIGH);
  delay(100);
  digitalWrite(releOD, HIGH);
  delay(100);
  if(DO.begin()){
    //Serial.println("Loaded EEPROM");
  }
  OD = DO.read_do_percentage(); 
  if (ODon == 'b'){
    digitalWrite(bjtOD, LOW);  
    delay(100);
    digitalWrite(releOD, LOW);  
  }
}

void medirT(){
  digitalWrite(releT, HIGH);
  delay(100);
  digitalWrite(bjtT, HIGH);
  delay(100);
  sensorT.begin();
  sensorT.requestTemperatures();
  T = sensorT.getTempCByIndex(0);
  //if (T == -127){
    //digitalWrite(LedPin, HIGH);
    //BLT.print("midio mal el sensor de T");
  //}
  delay(100);
  digitalWrite(bjtT, LOW);
  digitalWrite(releT, LOW);
}

void setearRectapH(){
  Serial1.println("mandar valor de pendiente");
  pendiente = 0;
  delay(100);
  while (pendiente == 0){
    if (Serial1.available()){
      pendiente = Serial1.parseFloat();
    }
  }
  delay(100);
  Serial1.println("mandar valor de ordenada");
  ordenada = 0;
  delay(100);
  while (ordenada == 0){
    if (Serial1.available()){
      ordenada = Serial1.parseFloat();
    }
  }
  delay(100);
  Serial1.println("recta de calibracion de pH seteada");
  minutos = minprev;
  medir = onprev;
  rectapH = 'b';
  delay(100);
  guardarEstado();
}

void calibrarPeachimetro(){
  digitalWrite(bjtpH, HIGH);
  delay(100);
  digitalWrite(relepH, HIGH);
  delay(100);
  datobt = ' ';
  Serial1.println("poner sonda en sn standard 7 y apretar una vez boton OK");
  delay(100);
  Serial1.println("recomendacion: esperar 3 min a que equilibre");
  while(datobt != 'k'){
    if (Serial1.available()){
      datobt = Serial1.read();
    }
    if (datobt == 'a'){
      break;
    }
    if (datobt == 'P'){
      mandarpH();
    }
  }
  switch(datobt){
    case 'k':
    medirpH(7);
    datobt = ' ';
    Serial1.println("poner sonda en sn standrad 4 y apretar una vez boton OK");
    while(datobt != 'k'){ // cambiar aca por datobt?
      if (Serial1.available()){
        datobt = Serial1.read();
      }
      if (datobt == 'a'){
        break;
      }
      if (datobt == 'P'){
        mandarpH();
      }
    }
    switch (datobt){
      case 'k':
      medirpH(4);
      Serial1.println("pH-metro calibrado");
      break;      
    
      case 'a':
      Serial1.println("de baja la calibracion");
      break;
    }
    break;
    
    case 'a':
    Serial1.println("de baja la calibracion");
    break;
  }
  minutos = minprev;
  medir = onprev;
  calpH = 'b';
  datospH = 'b';
  delay(100);
  digitalWrite(bjtpH, LOW);
  delay(100);
  digitalWrite(relepH, LOW);

  guardarEstado();
}

void medirpH(int p){
  digitalWrite(relepH, HIGH);
  delay(100);
  digitalWrite(bjtpH, HIGH);
  for (int i = 0; i < 179; i++){ // para que este 3 min hasta medir
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
      delay(100);
      digitalWrite(relepH, LOW);
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
  for (int i = 0 ; i < 10 ; i++){
    medirOD();
    Serial1.print("OD = ");
    Serial1.println(OD); 
    delay(100);
  }
  minutos = minprev;
  medir = onprev;
  datosOD = 'b';
  //datospH = 'a';
}

void mandarpH(){
  for (int i = 0 ; i < 1 ; i++){
    medirpH(0);
    Serial1.print("pH = ");
    Serial1.println(pH);
    Serial1.print("volt = ");
    Serial1.println(volt);
    delay(100);
  }  
  minutos = minprev;
  medir = onprev;
  datospH = 'b';
}

void mandarEC(){
  medirT();
  medirEC();
  Serial1.print("EC = ");
  Serial1.println(EC);
  minutos = minprev;
  medir = onprev;
  datosEC = 'b';
  EC = "";
}

void mandarT(){
  for (int i = 0 ; i < 10 ; i++){
    medirT();
    Serial1.print("T = ");
    Serial1.println(T);
    delay(100);
  }  
  minutos = minprev;
  medir = onprev;
  datosT = 'b';
}

void mandarReloj(){
  obtenerFecha();
  Serial1.print("fecha: ");
  Serial1.println(fecha);  
  minutos = minprev;
  medir = onprev;
  datosReloj = 'b';
  digitalWrite(bjtSD_RTC, LOW);
  delay(100);
  digitalWrite(releSD_RTC, HIGH);
  delay(100);
}

/*void mandarBateria(){
  analogValBat = analogRead(A3);
  voltBat = 5.00 * analogValBat / 1024.00; // Calculamos el voltBat. Es una simple regla de 3. Si 5V es 1024, con dividir 5 entre 1024 y multiplicarlo por el valor que nos da el pin analógico, ya tenemos el voltBat. Así de sencillo
  Serial1.print("voltBat: ");
  Serial1.println(voltBat);  
  minutos = minprev;
  medir = onprev;
  datosBateria = 'b';
}*/

void pegarDatosEnSD(){  
  //digitalWrite(bjtSD_RTC, HIGH);
  //delay(100);
  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial1.println("memoria encontrada !");
  }else{
    //Serial1.println("memoria no encontrada !");
    //BLT.print("no encontro la memoria");
    //digitalWrite(LedPin, HIGH);
    //digitalWrite(13, HIGH);
  }
  datos = SD.open("mega.txt", FILE_WRITE);
  if (datos){
    //Serial1.println("abrio el archivo");  
    datos.print(fecha);
    datos.print(";");
    datos.print(OD);
    datos.print(";");
    datos.print(EC);
    datos.print(";");
    datos.print(pH);
    datos.print(";");
    datos.print(T);
    datos.print(";");
    datos.println(String(punto));
    //datos.print(";");
    //analogValBat = analogRead(A3);
    //voltBat = 4.04 * analogValBat / 1024.00;
    //datos.println(voltBat);
    datos.close();
  }else{
    //digitalWrite(13, HIGH);
    //Serial1.println("no abrio el archivo");  
    //BLT.print("no pudo abrir el archivo");
    //digitalWrite(LedPin, HIGH);
  }

  digitalWrite(bjtSD_RTC, LOW);
  delay(100);
  digitalWrite(releSD_RTC, HIGH);
  delay(100);

  Serial3.begin(9600);
  delay(100);
  Serial3.print(fecha);
  Serial3.print(";");
  Serial3.print(OD);
  Serial3.print(";");
  Serial3.print(EC);
  Serial3.print(";");
  Serial3.print(pH);
  Serial3.print(";");
  Serial3.print(T);
  Serial3.print(";");
  Serial3.println(punto);
  delay(100);
  Serial3.end();
  EC = "";
}

void chequearEstado(){
  Serial1.println("Voy a mirar los datos");
  digitalWrite(releSD_RTC, LOW);
  delay(1000);
  digitalWrite(bjtSD_RTC, HIGH);
  delay(1000);
  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial.println("memoria encontrada !");
  }else{
    //digitalWrite(LedPin, HIGH);
    Serial1.println("memoria no encontrada !");
    //Serial1.println("no encontro la memoria");
    //digitalWrite(13, HIGH);
  }
  estadoprev = SD.open("estado.txt");
  if (estadoprev){
    //delay(500);
    //Serial.println("abri el archivo"); 
    estadoprev.seek(0);
    //BLT.print("*G");
    /*while (estadoprev.available()){
      Serial.write(estadoprev.read());
      //pos++;
      //delay(10);
    }*/
    delay(500);
    receivedString = estadoprev.readStringUntil('\n');
    delay(500);

    //Serial.print("receivedString: ");
    //Serial.println(receivedString);
    
    delay(100);
    estadoprev.close();
    delay(100);

  }else{
    Serial1.println("no hay estado previo");
  }
  delay(100);
  digitalWrite(bjtSD_RTC, LOW);
  delay(100);
  digitalWrite(releSD_RTC, HIGH);

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
            
              pendiente = token1.toFloat();
              ordenada = token2.toFloat();
              medir = token3.charAt(0);
              minutos = token4.toInt();
              punto = receivedString.toFloat();
              if (punto != 0){
                titulo = 'a';
              }
            }
          }
        }
      }

  Serial1.print("m = ");
  Serial1.println(pendiente);
  Serial1.print("O.O. = ");
  Serial1.println(ordenada);
  Serial1.print("medir: ");
  Serial1.println(medir);
  Serial1.print("frecuencia (minutos): ");
  Serial1.println(minutos/15);
  Serial1.print("punto: ");
  Serial1.println(punto);
}

void guardarEstado(){
  digitalWrite(releSD_RTC, LOW);
  delay(1000);
  digitalWrite(bjtSD_RTC, HIGH);
  delay(1000);

  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial.println("memoria encontrada !");
  }else{
    //digitalWrite(LedPin, HIGH);
    Serial1.println("memoria no encontrada !");
    //Serial1.println("no encontro la memoria");
    //digitalWrite(13, HIGH);
  }
  
  estadoprev = SD.open("estado.txt", FILE_WRITE | O_TRUNC);
  if (estadoprev){

    estadoprev.print(pendiente);
    estadoprev.print(";");
    estadoprev.print(ordenada);
    estadoprev.print(";");
    estadoprev.print(medir);
    estadoprev.print(";");
    estadoprev.print(minutos);
    estadoprev.print(";");
    estadoprev.print(punto);
    //estadoprev.println("nueva linea");
    Serial1.println("Cambios guardados");

    estadoprev.close();
  }else{
    Serial1.println("Cambios no guardados");
  }

  digitalWrite(bjtSD_RTC, LOW);
  delay(100);
  digitalWrite(releSD_RTC, HIGH);
  delay(100);
}

void mandarDatos(){
  digitalWrite(releSD_RTC, LOW);
  delay(1000);
  digitalWrite(bjtSD_RTC, HIGH);
  delay(1000);
  if (SD.begin(SSpin)){ //tarjeta sd conectada al canals SS vía pin 4
    //Serial.println("memoria encontrada !");
  }else{
    //digitalWrite(LedPin, HIGH);
    Serial1.println("memoria no encontrada !");
    //Serial1.println("no encontro la memoria");
    //digitalWrite(13, HIGH);
  }
  datos = SD.open("mega.txt");
  if (datos){
    //Serial.println("abrio el archivo");
    datos.seek(pos);
    //BLT.print("*G");
    while (datos.available()){
      Serial1.write(datos.read());
      pos++;
      //delay(10);
    }
    //BLT.print("*");  
    datos.close();
  }
  else{
    //digitalWrite(LedPin, HIGH);
    //Serial1.println("no pudo abrir el archivo");
    //digitalWrite(13, HIGH);
    Serial1.println("no abrio el archivo");  
  }
  minutos = minprev;
  medir = onprev;
  enviar = 'b';
  delay(100);
  digitalWrite(bjtSD_RTC, LOW);
  delay(100);
  digitalWrite(releSD_RTC, HIGH);
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
    digitalWrite(bjtSD_RTC, HIGH);
    delay(100);
    digitalWrite(releSD_RTC, LOW);
    delay(100);
    if (SD.begin(SSpin)){
      if (SD.exists("mega.txt")){
       SD.remove("mega.txt");
       Serial1.println("archivo eliminado");
      }else{
        Serial1.println("el archivo no existe");
        //digitalWrite(13, HIGH);
     }
    }else{
     Serial1.println("no pudo eliminar el archivo");
      //digitalWrite(13, HIGH);
    }
    delay(100);
    digitalWrite(bjtSD_RTC, LOW);
    delay(100);
    digitalWrite(releSD_RTC, HIGH);
    minutos = minprev;
    medir = onprev;
    eliminar = 'b';
    break;

    case 'a':
    Serial1.println("aaasa te asustaste");
    break;
  }
  /*digitalWrite(bjtSD_RTC, HIGH);
  delay(100);
  if (SD.begin(SSpin)){
    if (SD.exists("mega.txt")){
      SD.remove("mega.txt");
      Serial1.println("archivo eliminado");
    }else{
      Serial1.println("el archivo no existe");
      //digitalWrite(13, HIGH);
    }
  }else{
    Serial1.println("no pudo eliminar el archivo");
    //digitalWrite(13, HIGH);
  }
  delay(100);
  digitalWrite(bjtSD_RTC, LOW);
  minutos = minprev;
  medir = onprev;
  eliminar = 'b';*/
}

void obtenerFecha(){
  digitalWrite(releSD_RTC, LOW);
  delay(100);
  digitalWrite(bjtSD_RTC, HIGH);
  delay(100);
  if (rtc.begin()){
    dt = rtc.now();
  }
  fecha = String(dt.day()) + "/" + String(dt.month()) + "/" + String(dt.year()) + ";" + String(dt.hour()) + ":" + String(dt.minute()) + ":" + String(dt.second());
  //if (dt.day() > 31 || dt.month() > 12 || dt.year() > 2100 || dt.day() < 0 || dt.month() < 0 || dt.year() < 2020){
    //digitalWrite(13, HIGH);
    //Serial1.print("midio mal el reloj");
  //}
  //digitalWrite(bjtSD_RTC, LOW);
}

void corregirReloj(){
  digitalWrite(releSD_RTC, LOW);
  delay(100);
  digitalWrite(bjtSD_RTC, HIGH);
  delay(100);
  if (rtc.begin()){
    Serial.println("reloj bien");
  }else{
    Serial.println("reloj mal");
  }  
  rtc.adjust(dt); 
  obtenerFecha();
  Serial.print(fecha);
  delay(100);
  digitalWrite(bjtSD_RTC, LOW);
  delay(100);
  digitalWrite(releSD_RTC, HIGH);
}
  
void medirEC(){
  EC = "";
  digitalWrite(releEC, HIGH);
  delay(100);
  digitalWrite(bjtEC, HIGH);
  delay(1500);
  Serial2.begin(9600); // Serial2 es RX3 (15) a SDA y TX3 (14) a SCL
  delay(1500);
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
  Serial2.print("RT," + String(T));  // chequear que esto funcione
  Serial2.print('\r');
  delay(1200);
  EC = Serial2.readStringUntil(13);
  /*int a = 0;
  while (Serial2.available() > 0) {                     //if we see that the Atlas Scientific product has sent a character
    //Serial2.print("T," + String(T));  // chequear que esto funcione
    char inchar = (char)Serial2.read();              //get the char we just received
    if (isdigit(inchar) || inchar == '.' || inchar == ','){
      EC += inchar;  // aca esta leyendo lo del sensor                         //add the char to the var called sensorstring
    }
    if (inchar == '\r') {                             //if the incoming character is a <CR>
      //a++;
      //if (a > 1){
        break;
      //}
    }
  }*/
  delay(100);
  Serial2.end();
  if (ECon == 'b'){
    digitalWrite(bjtEC, LOW); 
    delay(100);
    digitalWrite(releEC, LOW); 
  }
}

// calibrar EC con 1 o 2 puntos que quiera

void calibrarEC(){
  delay(100);
  Serial1.println("por ahora seria OK para 2 puntos y EC 1 pto para 1");
  delay(100);
  while(datobt != 'k'){ // esto lo podria cambiar, y poner simplemente en vez de datobt, un char nuevo vacio y que el while sea mientras siga valiendo '', y cuando recibe algo sale
    if (Serial1.available()){
      datobt = Serial1.read(); // ver si aca puede recibir una palabra
    }
    if (datobt == 'a' || datobt == 'S' || datobt == 'D'){
      break;
    }
  }
  switch(datobt){
    char c = ' ';
    case 'D': // para 1 punto
    Serial1.println("mandar valor de punto");
    punto1 = 0;
    delay(100);
    while (punto1 == 0){
      if (Serial1.available()){
        punto1 = Serial1.parseFloat();
        c = Serial1.read(); // ver si funciona esto para dar de baja la calibracion del EC en el medio
        if (c == 'a'){
          break;
        }
      }
    }
    switch (c){
      case 'a':
      Serial1.println("de baja la calibracion");
      break;

      default:
      digitalWrite(releEC, HIGH);
      delay(100);
      digitalWrite(bjtEC, HIGH);
      delay(1200);
      Serial2.begin(9600);
      delay(1200);
      Serial2.print("cal," + String(punto1));  // chequear que esto funcione
      Serial2.print('\r');                             //add a <CR> to the end of the string
      delay(100);
      Serial1.println(Serial2.readStringUntil(13));
      delay(100);
      Serial2.end();
      digitalWrite(releEC, LOW);
      delay(100);
      digitalWrite(bjtEC, LOW);
      Serial1.println("EC cal");
      delay(100);
      break;
    }
    /*digitalWrite(bjtEC, HIGH);
    delay(1200);
    Serial2.begin(9600);
    delay(1200);
    Serial2.print("cal," + String(punto1));  // chequear que esto funcione
    Serial2.print('\r');                             //add a <CR> to the end of the string
    delay(100);
    Serial1.println(Serial2.readStringUntil(13));
    delay(100);
    Serial2.end();
    digitalWrite(bjtEC, LOW);
    Serial1.println("EC cal");
    delay(100);
    break;*/
    
    case 'k': // para 2 puntos
    Serial1.println("mandar valor de 1er punto (menor)");
    punto1 = 0;
    delay(100);
    while (punto1 == 0){
      if (Serial1.available()){
        punto1 = Serial1.parseFloat();
        c = Serial1.read(); // ver si funciona esto para dar de baja la calibracion del EC en el medio
        if (c == 'a'){
          break;
        }
      }
    }
    switch (c){
      case 'a':
      Serial1.println("de baja la calibracion");
      break;
      
      default:
      digitalWrite(releEC, HIGH);
      delay(100);
      digitalWrite(bjtEC, HIGH);
      delay(1200);
      Serial2.begin(9600);
      delay(1200);
      Serial2.print("cal,low," + String(punto1));  // chequear que esto funcione
      Serial2.print('\r');                             //add a <CR> to the end of the string
      delay(100);
      Serial1.println(Serial2.readStringUntil(13));
      Serial2.end();
      digitalWrite(releEC, LOW);
      delay(100);
      digitalWrite(bjtEC, LOW);
      Serial1.println("mandar valor de 2do punto (mayor)");
      punto2 = 0;
      delay(100);
      while (punto2 == 0){
        if (Serial1.available()){
          punto2 = Serial1.parseFloat();
        }
        c = Serial1.read(); // ver si funciona esto para dar de baja la calibracion del EC en el medio
        if (c == 'a'){
          break;
        }
      }
      switch (c){
        case 'a':
        Serial1.println("de baja la calibracion");
        break;                
        
        default:
        digitalWrite(releEC, HIGH);
        delay(100);
        digitalWrite(bjtEC, HIGH);
        delay(1200);
        Serial2.begin(9600);
        delay(1200);
        Serial2.print("cal,high," + String(punto2));  // chequear que esto funcione
        Serial2.print('\r');                             //add a <CR> to the end of the string
        delay(100);
        Serial1.println(Serial2.readStringUntil(13));
        delay(100);
        Serial2.end();
        digitalWrite(releEC, LOW);
        delay(100);
        digitalWrite(bjtEC, LOW);
        Serial1.println("EC cal");
        break;  
      }
    }

    case 'S':
    Serial1.println("calibrando con punto Std");
    digitalWrite(releEC, HIGH);
    delay(100);
    digitalWrite(bjtEC, HIGH);
    delay(1200);
    Serial2.begin(9600);
    delay(1200);
    Serial2.print("cal," + String(puntoStd));  // chequear que esto funcione
    Serial2.print('\r');                             //add a <CR> to the end of the string
    delay(100);
    Serial2.end();
    digitalWrite(releEC, LOW);
    delay(100);
    digitalWrite(bjtEC, LOW);
    Serial1.println("EC cal");
    break;

    case 'a':
    Serial1.println("de baja la calibracion");
    break;
  }
  delay(100);
  minutos = minprev;
  medir = onprev;
  calEC = 'b';
}

void calibrarOD(){
  digitalWrite(releOD, HIGH);
  delay(100);
  digitalWrite(bjtOD, HIGH);
  delay(100);
  if(DO.begin()){
    //Serial.println("Loaded EEPROM");
  }
  Serial1.println("sn sat 100 y OK");
  while(datobt != 'k'){
    if (Serial1.available()){
      datobt = Serial1.read();
      //Serial1.println(DO.read_do_percentage()); --> se manda solo cuando apreto algo, raro. Y no se si me deja cancelar
    }
    if (datobt == 'a'){
      break;
    }
    //Serial1.println(DO.read_do_percentage()); --> aca se manda perfecto siempre pero tarda mucho en cancelar (dar ok no probe)
  }  
  switch(datobt){
    case 'k':
    DO.cal();
    Serial1.println("OD cal a 100");  
    break;

    case 'a':
    Serial1.println("de baja la calibracion");
    break;
  }
  digitalWrite(releOD, LOW);
  delay(100);
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
    Serial1.print("m = ");
    Serial1.println(pendiente);
    Serial1.print("O.O. = ");
    Serial1.println(ordenada);
    break;
    
    case 'o':
    minutos = 14; // tendría 1 seg más de delay con los 3200
    //msdelay = 2200;
    Serial1.println("1 min");
    guardarEstado();
    break;

    case 'q':
    minutos = 216; // 
    //msdelay = 2200;
    Serial1.println("15 min");
    guardarEstado();
    break;

    case 't':
    minutos = 441; // tendría 2 seg más de delay con los 3200 (en realidad eran 26 o 27 seg, no 30 --> puse 443 en vez de 442) --> 1er prueba: +8 seg, pongo en 441
    //msdelay = 1200;
    Serial1.println("30 min");
    guardarEstado();
    break;

    case 'h':
    minutos = 70; // 
    //msdelay = 1200;
    Serial1.println("5 min");
    guardarEstado();
    break;

    /*case '6':
    minutos = 887; // tendría 1 seg menos de delay con los 3200 (si lo dejaba en 884, pero lo puse en 885 y msdelay = 200) --> eran 51 seg, no 60 --> puse 887 y 1200 en vez de 885 y 200
    //msdelay = 1200;
    BLT.println("1 hora");
    break;*/

    case 'n':
    minutos = 3;
    Serial1.println("15 seg");
    guardarEstado();
    break;

    case 'g': 
    medir = 'a';
    //guardarEstado();
    //Serial1.println("a medir");
    Serial1.println("escribir punto de mediciones (solo numeros)");
    break;
      
    case 'r':
    medir = 'b';
    titulo = 'b';
    punto = 0;
    Serial1.println("apagando...");
    guardarEstado();
    Serial1.println("off");
    break;

    case 'y': 
    Serial1.println("ahi te mando");
    enviar = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'w': 
    Serial1.println("ahi te mando");
    pos = 0;
    enviar = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'X': 
    Serial1.println("datos OD");
    datosOD = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;
    
    case 'P': 
    Serial1.println("datos pH");
    datospH = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'Z': 
    Serial1.println("datos EC");
    datosEC = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'R': 
    Serial1.println("reloj");
    datosReloj = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;
    
    case 'T': 
    Serial1.println("datos T");
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

    /*case '%': 
    analogValBat = analogRead(A3);
    voltBat = 4.04 * analogValBat / 1024.00; // Calculamos el voltBat. Es una simple regla de 3. Si 5V es 1024, con dividir 5 entre 1024 y multiplicarlo por el valor que nos da el pin analógico, ya tenemos el voltBat. Así de sencillo
    Serial1.print("voltBat: ");
    Serial1.println(voltBat);    
    break;*/

    case '#': // dejar prendido EC
    ECon = 'a';
    Serial1.println("mantener EC on");
    break;

    case '@': // dejar prendido OD
    ODon = 'a';
    Serial1.println("mantener OD on");
    break;

    case '-': // dejar prendido pH
    pHon = 'a';
    Serial1.println("mantener pH on");
    break;

    case '&':
    apagar = 'a';
    ECon = 'b';
    ODon = 'b';
    pHon = 'b';
    Serial1.println("mantener todos apagados");
    break;

    case '?':
    Serial1.print("cada ");
    Serial1.print(minutos/15); 
    Serial1.print(" minutos ; estado = ");
    Serial1.println(medir);
    break;

    case 'd':
    Serial1.println("cal EC");
    calEC = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'c':
    Serial1.println("cal pH");
    calpH = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;

    case 'e':
    Serial1.println("eliminar archivo? seguro?");
    //Serial1.println("eliminando...");
    eliminar = 'a';
    onprev = medir;
    medir = 'b';
    minprev = minutos;
    minutos = 0;
    break;
    
    case 'O':
    Serial1.println("cal OD");
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
    chequearEstado();
    break;

    case 'm':
    guardarEstado();
    break;
  }
}

void hacerAccion(){
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
  /*if (bateria == 'a'){
    mandarBateria();
  }*/
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
  pinMode(bjtSD_RTC, OUTPUT);
  digitalWrite(bjtSD_RTC, LOW);
  pinMode(releOD, OUTPUT);
  digitalWrite(releOD, LOW); 
  pinMode(relepH, OUTPUT);
  digitalWrite(relepH, LOW);
  pinMode(releEC, OUTPUT);
  digitalWrite(releEC, LOW);
  pinMode(releT, OUTPUT);
  digitalWrite(releT, LOW);
  pinMode(releSD_RTC, OUTPUT);
  digitalWrite(releSD_RTC, HIGH);
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
  for (int i = 0; i <= 53; i++) {
    if (i == 4 || i == 5 || i == 6 || i == 7 || i == 8 || i == 9 || i == 10 || i == 11 || i == 12 || i == 13 || i == 14 || i == 15 || i == 16 || i == 17 || i == 18 || i == 19 || i == 20 || i == 21 || i == 48 || i == 49 || i == 50 || i == 51 || i == 52 || i == 53){
      
    }else{
      pinMode(i, OUTPUT);
      digitalWrite(i, LOW);
    }
  }
}

/*void probarMemoria(){
  digitalWrite(bjtSD_RTC, HIGH);
  delay(100);
  rtc.adjust(dt); // COMENTAR UNA VEZ AJUSTADA Y VOLVER A SUBIR
  delay(100);
  digitalWrite(bjtSD_RTC, LOW);*/
  /*digitalWrite(bjtSD_RTC, HIGH);
  delay(100);
  if (SD.begin(SSpin)){ 
    Serial.println("abrio la memoria");
  }else{
    Serial.println("no");
    digitalWrite(13, HIGH);
  }
  datos = SD.open("mega.txt");//abrimos  el archivo 
  if (datos) {
    Serial.println("abrio");
    datos.close(); //cerramos el archivo
  } else {
    Serial.println("Error al abrir el archivo");
  }
  delay(100);
  digitalWrite(bjtSD_RTC, LOW);
}
*/
