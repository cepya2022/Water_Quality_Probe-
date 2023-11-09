# Water_Quality_Probe-

## Introduction

The development of open-source code and hardware instruments enables both the creation of new technologies and the redesign and adaptation of existing instruments to the user's specific needs. This allows free access to design and operational documentation, creating the possibility for the developed instruments to be replicated, assembled, studied, modified, shared, and collaboratively commercialized by anyone.

The current project involves the design of a low-cost multiparametric water quakity probe that enables in situ and remote sensing of physicochemical variables relevant to the environment, such as conductivity, dissolved oxygen, temperature, and pH in bodies of water. The first prototype based on Arduino is already available, and efforts are underway to refine it in order to achieve a more robust, economical, and efficient product. This project proposes integrating the microcontroller into a single printed circuit board (PCB) that facilitates data acquisition and storage over extended periods, reduces energy consumption, and enhances robustness, considering its predominantly outdoor operation.


### Hardware

The monitoring station consists of a sealed waterproof box that floats with the assistance of auxiliary buoys. Inside the box, there is an Arduino Mega microcontroller connected to an external clock, an SD memory module, a low-energy Bluetooth module, a solar-powered energy system, and signal processing and decoupling systems for each sensor. Submersible cables extend from this box to the probes, allowing sampling in the water.

Regarding energy aspects, a solar-powered system was designed. It includes a Li-Ion battery (or two arranged in parallel) that powers the microcontroller and sensors, connected to a 1 Watt solar panel, providing indefinite energy autonomy.

Additionally, it integrates a Bluetooth device using 4.0 BLE (Bluetooth Low Energy) technology. The Serial Bluetooth Terminal® app enables remote control of the probe, such as remote power on/off, selection of measurement intervals, sensor calibration, and data query, curing, and collection. It's worth noting that each measurement includes the exact date and time it was taken. These features make it easy to remotely monitor many relevant variables over extended periods with high sampling rates, allowing for detailed time-series data collection at the study site.
