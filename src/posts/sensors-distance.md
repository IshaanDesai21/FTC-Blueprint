---
title: Distance Sensor
panelCategory: "Sensors"
date: 2026-05-10
description: Reading the REV 2m Distance Sensor.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The REV 2m Distance Sensor is a time-of-flight sensor. It sends an infrared pulse and measures how long it takes to return. Range is about 2 meters.

## Setup

Configure it as an I2C device. In code, use the `DistanceSensor` interface.

```java
import com.qualcomm.robotcore.hardware.DistanceSensor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

DistanceSensor distanceSensor = hardwareMap.get(DistanceSensor.class, "distanceSensor");
```

## Reading

Pass the unit you want to `getDistance()`.

```java
double inches = distanceSensor.getDistance(DistanceUnit.INCH);
double cm = distanceSensor.getDistance(DistanceUnit.CM);

telemetry.addData("Distance (in)", "%.2f", inches);
telemetry.update();
```

If nothing is in range the sensor returns a very large value, so check for that before using the number.

## Uses

- **Intake detection.** Mount the sensor inside the intake and stop the intake motor when the reading drops below a threshold.
- **Wall alignment.** Two sensors on the same side of the robot read the same distance when the robot is square to the wall.
- **Stopping before a wall.** Cut forward power when the reading is under a set distance.

## Example

Forward drive is blocked when something is closer than 5 inches.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DistanceSensor;
import com.qualcomm.robotcore.hardware.DcMotor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

@TeleOp(name = "Distance Sensor Example")
public class DistanceSensorExample extends LinearOpMode {

    private DistanceSensor distanceSensor;
    private DcMotor driveMotor;

    @Override
    public void runOpMode() {
        distanceSensor = hardwareMap.get(DistanceSensor.class, "distanceSensor");
        driveMotor = hardwareMap.get(DcMotor.class, "driveMotor");

        waitForStart();

        while (opModeIsActive()) {
            double inches = distanceSensor.getDistance(DistanceUnit.INCH);
            double drivePower = -gamepad1.left_stick_y;

            if (inches < 5.0 && drivePower > 0) {
                driveMotor.setPower(0);
            } else {
                driveMotor.setPower(drivePower);
            }

            telemetry.addData("Distance", "%.2f in", inches);
            telemetry.update();
        }
    }
}
```

## Notes

- Dark and transparent surfaces can give bad readings. Test against the actual object you plan to detect.
- Each read is an I2C transaction and takes time. Don't read the sensor more then once per loop.
