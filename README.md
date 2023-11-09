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

The research team is continuosly working on and improving the code. It it written in 
The updated code is available [here](https://github.com/cepya2022/Water_Quality_Probe-/blob/main/Code_Water_Quality_Probe.ino). 
