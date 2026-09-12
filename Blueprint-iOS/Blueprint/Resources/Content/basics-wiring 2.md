---
title: Basics of Wiring and Configuration
panelCategory: "Basics"
date: 2026-03-28
description: Essential guide to wiring your FTC robot and configuring it in the app.
tags: [completed, software, beginner, manual, completed]
author: Ishaan Desai
published: true
---

# Basics of Wiring and Configuration

Proper wiring and configuration are the foundation of a reliable FTC robot. This guide covers the basics of connecting your hardware to the Control Hub or Expansion Hub and setting it up in the FTC Robot Controller app.

---

## Wiring Your Robot

### 1. Connecting Motors
Motors should be connected to the motor ports on the Control Hub or Expansion Hub. Ensure you use the correct cable type for your motors (e.g., Anderson Powerpole or JST-VH).

### 2. Connecting Servos
Servos are connected to the servo ports. Pay close attention to the orientation of the connectors; the black (ground) wire should be on the outside.

### 3. Connecting Sensors
Most sensors in FTC use I2C, Digital, or Analog ports.

- **I2C:** Used for sensors like the IMU, color sensors, and distance sensors.
- **Digital:** Used for touch sensors or limit switches.
- **Analog:** Used for potentiometers or specialized sensors.

---

## Configuring Your Robot in the App

Once your hardware is wired, you must configure it in the FTC Robot Controller app so your code knows which device is on which port.

### 1. Accessing the Configuration
On the Driver Station app, tap the three-dot menu in the top-right corner and select **Configure Robot**.

### 2. Creating a Configuration
Select **New** to create a new configuration. The app will scan for connected hubs.

### 3. Naming Your Devices
For each port, select the device type and give it a unique name. This name _must_ match the string you use in your Java code's `hardwareMap.get()` call.

```java
// Example: The name "leftDrive" in the app must match here
DcMotor leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
```

---

> **Secure Connections:** Ensure every connector is fully seated and won't vibrate loose during a match.
