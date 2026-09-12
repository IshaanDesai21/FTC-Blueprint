---
title: Distance Sensor
panelCategory: "Sensors"
date: 2026-04-05
description: How to use a distance sensor
tags: [software, completed, beginner]
author: Ishaan Desai
published: true
---

# Distance Sensor Guide

Distance sensors (like the REV 2m Distance Sensor) use "Time of Flight" (TOF) technology to measure how far away an object is by bouncing an infrared beam off it.

> **Accuracy:** TOF sensors are extremely precise (within millimeters) but have a limited range (usually up to 2 meters). They are much faster and more reliable than older ultrasonic sensors.

---

## 1. Initialization

You need both the `DistanceSensor` class and the `DistanceUnit` utility.

```java
import com.qualcomm.robotcore.hardware.DistanceSensor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

DistanceSensor distanceSensor = hardwareMap.get(DistanceSensor.class, "distanceSensor");
```

## 2. Reading Distance

You can request the distance in various units (Inches, CM, MM).

```java
double distanceInches = distanceSensor.getDistance(DistanceUnit.INCH);
double distanceCM = distanceSensor.getDistance(DistanceUnit.CM);

telemetry.addData("Distance (in)", "%.2f", distanceInches);
telemetry.update();
```

## 3. Practical Use Cases

- **Wall Alignment:** Use two distance sensors (one on the front-left, one on the front-right) to ensure your robot is perfectly parallel to a wall. If both sensors read the same distance, you are straight!
- **Intake Detection:** Place a sensor inside your intake to automatically stop the motor once a game piece is captured.
- **Auto Navigation:** Detect if another robot is blocking your path during autonomous.
- **Automatic Braking:** If you are driving towards a wall at high speed, the robot can automatically slow down or stop when it gets within a certain distance.

### Tip
> **Avoiding Interference:** If you use multiple TOF sensors facing the same direction, they can sometimes "confuse" each other's infrared beams. Try to angle them slightly away from each other or read them sequentially if you encounter "jittery" data.

---

This example shows how to use the Distance Sensor to "auto-brake." The robot will stop the motor if it gets too close to an object.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DistanceSensor;
import com.qualcomm.robotcore.hardware.DcMotor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

@TeleOp(name = "Auto-Brake Distance Example", group = "Sensor")
public class DistanceSensorExample extends LinearOpMode {

    private DistanceSensor distanceSensor;
    private DcMotor driveMotor; // Example motor to control

    @Override
    public void runOpMode() {
        distanceSensor = hardwareMap.get(DistanceSensor.class, "distanceSensor");
        driveMotor = hardwareMap.get(DcMotor.class, "driveMotor");

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            // 1. Read distance in inches
            double distanceInches = distanceSensor.getDistance(DistanceUnit.INCH);

            // 2. Drive logic with safety check
            double drivePower = -gamepad1.left_stick_y;
            
            // If we are closer than 5 inches, don't allow forward movement
            if (distanceInches < 5.0 && drivePower > 0) {
                 driveMotor.setPower(0);
                 telemetry.addData("Safety", "WALL DETECTED - BRAKING");
            } else {
                 driveMotor.setPower(drivePower);
                 telemetry.addData("Safety", "Clear");
            }

            // 3. Telemetry output
            telemetry.addData("Distance", "%.2f in", distanceInches);
            telemetry.update();
        }
    }
}
```

---

### Tip
> **Material Matters:** TOF sensors can struggle with very dark materials (which absorb light) or highly reflective/transparent materials (like plexiglass or field perimeter glass). Always test with the specific material you intend to detect!

