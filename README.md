# 🍹 Embedded Drinks Machine – Final Exam Project (Mekatronik A)

![Drinks Machine Photo](assets/DrinkMachine.jpg)  
*Final hardware prototype (steel frame, rotating top, valves, and LCD interface)*

---

## 🧠 Project Summary

This was my final exam project for *Mekatronik A*, built in a team. The goal was to create a fully embedded **automated drinks machine** that:

- Rotates a platform with various liquor and soda bottles
- Dispenses custom drink combinations into a glass using valves
- Lets the user select a drink via a **rotary interface with LCD**
- Uses **two microcontrollers**: an Arduino for the user interface, and a **PIC16F873** for executing drink logic

We were required to write all PIC logic in **Assembly**, as our professor did not allow C for embedded development. The Arduino interface was written in C++ using the Arduino IDE. Communication between the two was at the core of the system — and where the biggest lessons came from.

---

## ⚙️ Project Architecture

- **PIC16F873**
  - Controls stepper motor to rotate drink platform
  - Opens/Closes magnetic valves
  - Receives data from Arduino (via USART or analog)
  - Entirely coded in `.asm` Assembly

- **Arduino Uno**
  - User interface with LCD and rotary selection
  - Sends drink selection to PIC
  - Used `Serial.write()` for USART or analog output via DAC + resistor

---

## 🧩 Key Challenges & Learning

### 1. **USART Communication (Failed Attempt)**

Our first implementation used serial communication. The Arduino sent a `Serial.write(drinkIndex)` over USART, and the PIC was supposed to receive it.

We couldn’t figure out why the PIC activated all the wrong outputs — until later I realized a major mistake:  
We wrote the value `10` to the `SPBRG` register instead of `1`, resulting in a **baud rate of ~22,000bps instead of the expected 115,200bps**.

Because of this, the PIC received garbage data. Unfortunately, we discovered this too late.

**File involved:**  
- `USART.asm` – Original PIC USART implementation  
- `LCDController.ino` – Send the selected data from the LCD to the PIC via USART data

---

### 2. **Analog Communication (Second Attempt)**

Since serial failed, we moved to analog. The Arduino output analog voltages mapped from 0–255. Each drink had a "center value" divisible by 32, so drink 0 might be 16, drink 1 would be 48, etc. This allowed ±16 tolerance to ensure stable input.

On the PIC, we read the analog value and used Assembly to subtract 32. If the result wrapped around (i.e., Carry bit was set), we considered it a match.

We even added filtering capacitors and tried to stabilize the signal. But it **still didn’t work**.

Why? I had assumed the PIC16F873 had an 8-bit ADC because it's an 8-bit MCU. **But the ADC is 10-bit**, giving values from 0–1023, not 0–255. So the threshold logic failed, and inputs were never recognized.

**Files involved:**  
- `analog.asm` – ADC handling and drink detection  
- `LCDControllerAnalog.ino` – Send the selected data from the LCD to the PIC via analog

---

### 3. **Fallback: Full Arduino Control**

As a last resort (with time running out), I wrote a full Arduino implementation that handled everything: UI, rotation, valve control, and timing. This worked, but it was a disappointment because the goal was to master Assembly and embedded logic.

**File involved:**  
- `ArduinoFullControl.ino` – Complete working version in Arduino (not used in final grading)

---

## 🧪 What I Learned

- How to debug serial protocols and why baud rate calculation matters
- How 10-bit vs 8-bit ADCs impact signal mapping
- How to write timing and control logic in raw Assembly for a PIC microcontroller
- That embedded systems require deep attention to bit-level behavior and electrical design
- That fallback solutions are okay — as long as you understand why the original didn’t work

---

## 🧪 Demo

![Machine Running GIF](assets/Drinkmachine.gif)  
*A short GIF showing the machine in action*

---

## 📖 Full Report

Our full 140+ page report includes hardware design, flowcharts, full schematics, and deep analysis of failures.

📄 [Read the full report (PDF)](assets/MekatronikA)  

---

## 🛑 Status

This project is **archived**. The hardware is owned by the school, and no further development is planned.  
However, **pull requests are welcome** if you'd like to improve the communication logic or animation flow.

---

## 📜 License

This project is released under the **MIT License**.  
See [LICENSE](./LICENSE) for details.
