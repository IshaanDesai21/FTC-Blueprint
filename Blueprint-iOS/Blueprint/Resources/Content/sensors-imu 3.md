---
title: Universal IMU Guide
panelCategory: "Sensors"
date: 2026-04-05
description: Using the modern, hub-agnostic IMU interface for robot orientation.
tags: [software, completed, beginner]
author: Ishaan Desai
published: true
---

# Universal IMU Guide

The Inertial Measurement Unit (IMU) is one of the most important sensors on your robot. It combines a **Gyroscope** (measuring rotation) and an **Accelerometer** (measuring acceleration) to help your robot understand its orientation in 3D space.

In modern FTC (SDK 8.0+), we use the universal `IMU` interface, which works across all REV Control Hub and Expansion Hub versions.

---

## 1. Defining Orientation

Before initializing the IMU, you must tell the software how the Control Hub is mounted on your robot. This is done using `RevHubOrientationOnRobot`.

You need to specify:
1. **Logo Direction**: Which way the REV logo on the hub is facing (UP, DOWN, FORWARD, etc.)
2. **USB Direction**: Which way the USB ports on the hub are facing.

```java
import com.qualcomm.hardware.rev.RevHubOrientationOnRobot;
import com.qualcomm.robotcore.hardware.IMU;

IMU imu = hardwareMap.get(IMU.class, "imu");

// Adjust these to match your robot's actual mounting!
IMU.Parameters parameters = new IMU.Parameters(new RevHubOrientationOnRobot(
    RevHubOrientationOnRobot.LogoFacingDirection.UP,
    RevHubOrientationOnRobot.UsbFacingDirection.FORWARD
));

imu.initialize(parameters);
```

## 2. Reading Angles (Yaw, Pitch, Roll)

The IMU provides three primary angles:
- **Yaw**: The direction the robot is facing (Heading). This is the most used angle for driving straight or turning.
- **Pitch**: The "tilt" of the robot (front-to-back).
- **Roll**: The "side-to-side" tilt.

```java
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.YawPitchRollAngles;

YawPitchRollAngles angles = imu.getRobotYawPitchRollAngles();

double yaw = angles.getYaw(AngleUnit.DEGREES);
double pitch = angles.getPitch(AngleUnit.DEGREES);
double roll = angles.getRoll(AngleUnit.DEGREES);

telemetry.addData("Yaw (Heading)", "%.2f", yaw);
```

## 3. Resetting the Heading

When your OpMode starts, the IMU's Yaw is set to 0 based on the robot's current position. If you want to "re-zero" the robot (e.g., in a field-centric drive system), use:

```java
imu.resetYaw();
```

---

## Full Example: Field-Centric Heading

This example shows how to initialize the IMU and read the Yaw for use in a basic heading-display OpMode.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.hardware.rev.RevHubOrientationOnRobot;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.IMU;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;

@TeleOp(name = "Universal IMU Example", group = "Sensor")
public class IMUExample extends LinearOpMode {

    private IMU imu;

    @Override
    public void runOpMode() {
        // 1. Initialize IMU
        imu = hardwareMap.get(IMU.class, "imu");

        // 2. Configure Orientation
        // Change these to match your hub's mounting!
        IMU.Parameters parameters = new IMU.Parameters(new RevHubOrientationOnRobot(
                RevHubOrientationOnRobot.LogoFacingDirection.UP,
                RevHubOrientationOnRobot.UsbFacingDirection.FORWARD
        ));

        imu.initialize(parameters);

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            // 3. Reset Yaw if 'A' is pressed
            if (gamepad1.a) {
                imu.resetYaw();
            }

            // 4. Read Heading
            double yaw = imu.getRobotYawPitchRollAngles().getYaw(AngleUnit.DEGREES);

            telemetry.addData("Heading", "%.2f degrees", yaw);
            telemetry.addData("Tip", "Press 'A' to reset Yaw");
            telemetry.update();
        }
    }
}
```

---

> [!CAUTION]
> **Initialization Time:** It is best to initialize the IMU in the `init` section of your OpMode (before `waitForStart`). Moving the robot during IMU initialization can cause drift or incorrect readings. Ensure the robot is stationary while the code is initializing!
