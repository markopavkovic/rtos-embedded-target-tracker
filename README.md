# STM32 FreeRTOS Embedded Radar System

Advanced multi-mode embedded radar and target tracking system developed for the STM32 Blue Pill microcontroller using **FreeRTOS**, featuring deterministic preemptive task scheduling, hardware MOSFET power gating, and real-time Java GUI telemetry.

---

## 🚀 Key Features & Operational Modes
- **Mode A (Autonomous Sweep):** Continuous servo scanning ($0^\circ - 180^\circ$) with real-time distance tracking handled via dedicated preemptive tasks.
- **Mode B (Step Control):** Precise manual stepping and angular adjustment via a $4 \times 4$ Matrix Keypad input buffer.
- **Mode C (High-Speed GUI Telemetry):** Real-time polar-to-Cartesian data stream transmitted over UART to a companion Processing GUI.
- **Mode D (Manual Target Lock):** Direct coordinate locking from user keypad entry with instant visual and hardware feedback.

---

## 🛠️ Protocols & Hardware Peripherals
- **UART (115200 Baud):** Transmits high-speed angle and distance telemetry frames to the companion Processing 2D GUI.
- **SPI:** Interfaces with the **MCP2515 CAN Controller** for robust bus telemetry communication.
- **I²C:** Drives the **SSD1306 OLED** screen for real-time status, distance, and active mode rendering.
- **Actuation & Energy Saving:** **SG90 Micro Servo** driven via PWM with hardware **MOSFET power gating** to completely eliminate idle holding-current consumption.
- **Sensing:** **HC-SR04** ultrasonic sensor operating with non-blocking timing logic inside a dedicated task.

---

## 📂 Repository Structure
- `Firmware/` - STM32 C/C++ embedded source code, FreeRTOS task definitions, and peripheral drivers.
- `GUI/` - Processing Java source code for the 2D visual radar scope.
- `Media/` - Project photos, schematics, and demo footage.

---

## 📹 Video Demonstrations

| Operational Mode | Description | Video Link |
| :--- | :--- | :--- |
| **Mode A** | Autonomous Sweep ($0^\circ - 180^\circ$) | [▶️ Watch Mode A](https://youtube.com/shorts/9sdVJw8njcU) |
| **Mode B** | Step-by-Step Keypad Control | [▶️ Watch Mode B](https://youtube.com/shorts/gOGl8Tvk9H8) |
| **Mode C** | High-Speed GUI Telemetry (Processing) | [▶️ Watch Mode C](https://youtube.com/shorts/Cr46Me-nSyM) |
| **Mode D** | Manual Target Lock | [▶️ Watch Mode D](https://youtube.com/shorts/MLeYCm_7FFA) |

---

## 📍 Hardware Topology & Signal Mapping

To prevent hardware conflicts with the **ST-Link/V2 SWD debugger (Port A)**, UI peripherals and non-critical I/Os are assigned to **Port B**, reserving core high-speed peripherals (CAN CS, Servo PWM, Buzzer, UART) for Port A.

```text
+-------------------------------------------------------------------------+
|                         STM32F103C8T6 (Blue Pill)                       |
+-------------------+-------------------+-------------------+-------------+
| I²C OLED (SSD1306)| Ultrasonic Sensor | Actuators & Audio | Keypad 4x4  |
|  - SCL: PB6       |  - TRIG: PB0      |  - Servo PWM: PA0 |  - Rows:    |
|  - SDA: PB7       |  - ECHO: PB1      |  - MOSFET Gate:PA1|    PB12-PB15|
|                   |                   |  - Buzzer: PA3    |  - Columns: |
|                   |                   |  - CAN CS: PA4    |    PB8,9,3,4|
+-------------------+-------------------+-------------------+-------------+
                                   |
                                   +---> [ CAN Bus Protocol (MCP2515) ]
                                   |
                                   v (USART1 @ 115200 Baud)
                       [ PC Laptop / Workstation ]
                                   |
                                   v (Real-Time FreeRTOS Telemetry)
                   [ Processing 2D Desktop Radar GUI ]
