# Water_Quality_Probe-

## Introduction

The development of open-source code and hardware instruments enables both the creation of new technologies and the redesign and adaptation of existing instruments to the user's specific needs. This allows free access to design and operational documentation, creating the possibility for the developed instruments to be replicated, assembled, studied, modified, shared, and collaboratively commercialized by anyone.

The current project involves the design of a low-cost multiparametric water quakity probe that enables in situ and remote sensing of physicochemical variables relevant to the environment, such as conductivity, dissolved oxygen, temperature, and pH in bodies of water. The first prototype based on Arduino is already available, and efforts are underway to refine it in order to achieve a more robust, economical, and efficient product. This project proposes integrating the microcontroller into a single printed circuit board (PCB) that facilitates data acquisition and storage over extended periods, reduces energy consumption, and enhances robustness, considering its predominantly outdoor operation.

<p>
<img align="center" src="https://github.com/FranciscoGBianco/SondaMultiP-UNSAM/blob/main/images/Sonda.jpg" width="250"  height="300">
</p>

### Hardware

The monitoring station consists of a sealed waterproof box that floats with the assistance of auxiliary buoys. Inside the box, there is an Arduino Mega microcontroller connected to an external clock, an SD memory module, a low-energy Bluetooth module, a solar-powered energy system, and signal processing and decoupling systems for each sensor. Submersible cables extend from this box to the probes, allowing sampling in the water.

Regarding energy aspects, a solar-powered system was designed. It includes a Li-Ion battery (or two arranged in parallel) that powers the microcontroller and sensors, connected to a 1 Watt solar panel, providing indefinite energy autonomy.

Additionally, it integrates a Bluetooth device using 4.0 BLE (Bluetooth Low Energy) technology. The Serial Bluetooth Terminal® app enables remote control of the probe, such as remote power on/off, selection of measurement intervals, sensor calibration, and data query, curing, and collection. It's worth noting that each measurement includes the exact date and time it was taken. These features make it easy to remotely monitor many relevant variables over extended periods with high sampling rates, allowing for detailed time-series data collection at the study site.

<p align="center">
<img align="center" src="https://github.com/FranciscoGBianco/SondaMultiP-UNSAM/blob/main/images/Schematic_V1.0.png" width="750"  height="500">
</p>

#### Components

* Solar Panel
* Double battery holder
* Arduino Mega 2560 Rev3
* Step Up Power Supply Xl6009 Dc Adjustable Dc 5v 35v 3a Max Arduino
* Lithium Battery Charger Micro USB Module Tp4056 5v
* HC-08 BLE Bluetooth Module
* Micro SD Memory Reader Module: hw-125
* DS3231 RTC Clock
* DS18B20 Submersible Stainless Steel Digital Temperature Sensor
* PH-4502C Liquid PH Sensor with E201-BNC Electrode
* Conductivity Sensor Conductivity K 1.0 Kit (Atlas Scientific)
* Gravity™ Analog Dissolved Oxygen Meter Dissolved Oxygen Sensor (Atlas Scientific)
* 4 Channels Relay Module Optocoupled 5v High and Low Hobb
* NPN and PNP BJT Transistors
* Resistors

### Software

The research team is continuosly working on and improving the code. It is written in c++ programming language inside the Arduino IDE as it is the default language for arduino microcontrollers. The system was design to enter sleep mode inside the loop function while the `measurement` option is disabled or in between measurements. It includes an interruption function which is activated once a message is received via Bluetooth. This function wakes the system, executes the corresponding command and once it is finished, it enters the loop again. The different commands include turning on/off the measurement cycle and setting its frequency, sensor calibration, data query and current state information.

#### Measurement cycles

Once the measurment is set to `On`, the interface will ask the user to identify the location with an ID (`locationID`) which must be a number. Once it is provided, the arduino will save the `On` state along with the location ID and the current frequency (default is 15 seconds), in a .txt file inside the SD Card. This feature acts as a reassurance in case of a sudden shutdown and restart of the system. In this case, during the setup function of the arduino, this file is checked to seek the last state in which the system was operating. In case the measurement was `On`, it sets the frequency and the location ID to their previous states and starts the measurement cycle, otherwise it keeps the default values and enters the loop. The frequency intervals available in the current version are 15 seconds and 1, 5, 15 or 30 minutes. Usually, for outdoor measurements, 30 minutes is a reasonable interval considering battery consumption, solar exposure and a relatively high sampling rate compared to other sampling methods.

During the measurement cycle, the arduino turns on and off each sensor in order to avoid energy shoratges and dead shorts. First it turns on the pH sensor (`pH`) and waits 3 minutes for it to energetically stabilize. This is due an induction generated by the relay module on this specific module, that does'nt allow precise measurements. Once the 3 minutes pass, it takes 10 measurements and keeps the average value, saves it into an auxiliary variable and turns the module off. Next is the temperature sensor (`T`), which replicates the 10 measurements procedure and turns it off. Third is the conductivity sensor (`EC`), which is one of the most accurate and precise ones, and which takes longer per measurement, so only one is taken and saved. The conductivity measurement is corrected for temperature, so it is necessary for it to go after the temperature is measured. Finally, the dissolved oxygen (`DO`) is measured using the 10 measurements procedure. Once the 4 parameters are measured, the actual time and date (`date`) are registered from the RTC clock and the 6 values are saved into a .txt file in a comma separated format. The order in which this are saved is: `date`;`DO`;`EC`;`pH`;`T`;`locationID`.

#### Data query

Data from measurement cycles is stored in the SD card with it's timestamp and a location id that is provided by the user during the measurement setup. 

The updated code is available [here](https://github.com/cepya2022/Water_Quality_Probe-/blob/main/Code_Water_Quality_Probe.ino). 
