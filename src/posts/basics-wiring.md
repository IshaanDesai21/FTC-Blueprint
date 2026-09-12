---
title: Basics of Wiring and Configuration
panelCategory: "Basics"
date: 2026-04-08
description: Connecting motors, servos, and sensors to the hub and configuring them in the Driver Station app.
tags: [completed, software, beginner, manual]
author: Blueprint
published: true
---

Before code can run, every device has to be plugged into the correct port and named in the robot configuration. Most "my motor doesn't work" problems at competition are wiring or configuration, not code.

## Wiring

### Motors

Motors plug into the motor ports on the Control Hub or Expansion Hub. The motor port uses a JST VH connector. The encoder cable plugs into the 4-pin encoder port next to the same motor port. A motor and its encoder must be on the same port number or the encoder reads the wrong motor.

### Servos

Servos use the 3-pin servo ports. The connector is not keyed, so match the wire colors to the markings on the hub. If a servo is plugged in backwards it will not move.

### Sensors

- **I2C** ports are for color sensors, distance sensors, and other devices that send data over a bus.
- **Digital** ports are for on/off devices like touch sensors and limit switches.
- **Analog** ports are for devices that output a voltage, like potentiometers.

Check the manufacturer's product page if you are not sure which port a sensor uses.

## Configuration

The Robot Controller needs to know what is plugged into each port. This is the robot configuration.

1. In the Driver Station app, open the menu and choose **Configure Robot**.
2. Tap **New**. The app scans for connected hubs and lists them.
3. For each port that has a device, select the device type and give it a name.
4. Save the configuration and activate it.

The name you type here must match the string passed to `hardwareMap.get()` exactly, including capitalization.

```java
DcMotor leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
```

Use names that describe the device, like `frontLeft` or `armMotor`. If the name in code does not match the configuration, the OpMode will crash on init with a message saying the device could not be found.

## Before every match

Pull on every connector. Anything that moves isnt seated. Loose motor and encoder cables are the most common cause of a robot dying mid-match, and they are easy to catch beforehand.
