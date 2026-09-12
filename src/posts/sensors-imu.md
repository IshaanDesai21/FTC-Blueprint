---
title: Universal IMU Guide
panelCategory: "Sensors"
date: 2026-05-14
description: Reading heading from the Control Hub IMU with the universal IMU interface.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The Control Hub has a built-in IMU with a gyroscope and accelerometer. In FTC it is mostly used for heading, the direction the robot is facing.

Current SDK versions use the `IMU` interface. Older code used `BNO055IMU` directly. This page covers the `IMU` interface.

## Hub orientation

The IMU needs to know how the hub is mounted. You give it the direction the REV logo faces and the direction the USB ports face, relative to the robot.

```java
import com.qualcomm.hardware.rev.RevHubOrientationOnRobot;
import com.qualcomm.robotcore.hardware.IMU;

IMU imu = hardwareMap.get(IMU.class, "imu");

IMU.Parameters parameters = new IMU.Parameters(new RevHubOrientationOnRobot(
    RevHubOrientationOnRobot.LogoFacingDirection.UP,
    RevHubOrientationOnRobot.UsbFacingDirection.FORWARD
));

imu.initialize(parameters);
```

`"imu"` is the name the Control Hub's IMU has in the default configuration.

If the heading changes in the wrong direction or the wrong axis, the orientation is set wrong. Check where the logo and USB ports actually point.

## Reading angles

```java
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.YawPitchRollAngles;

YawPitchRollAngles angles = imu.getRobotYawPitchRollAngles();

double yaw   = angles.getYaw(AngleUnit.DEGREES);
double pitch = angles.getPitch(AngleUnit.DEGREES);
double roll  = angles.getRoll(AngleUnit.DEGREES);
```

Yaw is the heading. It is zero at the orientation the robot had when `initialize()` ran, and it increases counter-clockwise. Pitch is front-to-back tilt and roll is side-to-side tilt.

## Resetting heading

```java
imu.resetYaw();
```

This sets the current heading to zero. Field-centric drive usually binds this to a button so the driver can re-zero if the robot starts at an angle.

## Initialization

Call `imu.initialize()` before `waitForStart()` and keep the robot still while it runs. Moving the robot during initialization gives you an offset heading for the whole match.

## Example

Press A to reset yaw.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.hardware.rev.RevHubOrientationOnRobot;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.IMU;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;

@TeleOp(name = "IMU Example")
public class IMUExample extends LinearOpMode {

    private IMU imu;

    @Override
    public void runOpMode() {
        imu = hardwareMap.get(IMU.class, "imu");

        IMU.Parameters parameters = new IMU.Parameters(new RevHubOrientationOnRobot(
                RevHubOrientationOnRobot.LogoFacingDirection.UP,
                RevHubOrientationOnRobot.UsbFacingDirection.FORWARD
        ));
        imu.initialize(parameters);

        waitForStart();

        while (opModeIsActive()) {
            if (gamepad1.a) {
                imu.resetYaw();
            }

            double yaw = imu.getRobotYawPitchRollAngles().getYaw(AngleUnit.DEGREES);

            telemetry.addData("Heading", "%.2f", yaw);
            telemetry.update();
        }
    }
}
```

The IMU is read over I2C, so each call to `getRobotYawPitchRollAngles()` cost time. Read it once per loop and store the result.
