---
title: Distance Sensor
panelCategory: "Sensors"
date: 2026-05-10
description: Reading the REV 2m Distance Sensor.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The REV 2m Distance Sensor is a time-of-flight sensor. It sends an infrared pulse and measures how long it takes to return. Range is about 2 meters. The SDK sample is `SensorREV2mDistance`.

## Reading it

Configure it as a REV 2m Distance Sensor on an I2C port. The sample names it `sensor_distance`. Read it through the generic `DistanceSensor` interface, and cast to `Rev2mDistanceSensor` if you want the sensor-specific methods.

```java
@TeleOp(name = "Sensor: REV2mDistance", group = "Sensor")
public class SensorREV2mDistance extends LinearOpMode {

    private DistanceSensor sensorDistance;

    @Override
    public void runOpMode() {
        sensorDistance = hardwareMap.get(DistanceSensor.class, "sensor_distance");

        // Cast it to reach the methods specific to this sensor.
        Rev2mDistanceSensor sensorTimeOfFlight = (Rev2mDistanceSensor) sensorDistance;

        telemetry.addData(">>", "Press start to continue");
        telemetry.update();

        waitForStart();
        while (opModeIsActive()) {
            telemetry.addData("deviceName", sensorDistance.getDeviceName() );
            telemetry.addData("range", String.format("%.01f mm", sensorDistance.getDistance(DistanceUnit.MM)));
            telemetry.addData("range", String.format("%.01f cm", sensorDistance.getDistance(DistanceUnit.CM)));
            telemetry.addData("range", String.format("%.01f m", sensorDistance.getDistance(DistanceUnit.METER)));
            telemetry.addData("range", String.format("%.01f in", sensorDistance.getDistance(DistanceUnit.INCH)));

            telemetry.addData("ID", String.format("%x", sensorTimeOfFlight.getModelID()));
            telemetry.addData("did time out", Boolean.toString(sensorTimeOfFlight.didTimeoutOccur()));

            telemetry.update();
        }
    }
}
```

`getDistance()` takes the unit you want. When nothing is in range it returns a very large value, so check for that before acting on the number. `didTimeoutOccur()` tells you the reading did not come back at all.

## Uses

- **Intake detection.** Mount the sensor inside the intake and stop the intake motor when the reading drops below a threshold.
- **Wall alignment.** Two sensors on the same side read the same distance when the robot is square to the wall.
- **Stopping before a wall.** Cut forward power when the reading is under a set distance.

## Example

Forward drive is blocked when something is closer than 5 inches.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.DistanceSensor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

@TeleOp(name = "Distance Sensor Example", group = "Sensor")
public class DistanceSensorExample extends LinearOpMode {

    private DistanceSensor sensorDistance;
    private DcMotor leftDrive;
    private DcMotor rightDrive;

    @Override
    public void runOpMode() {
        sensorDistance = hardwareMap.get(DistanceSensor.class, "sensor_distance");
        leftDrive  = hardwareMap.get(DcMotor.class, "left_drive");
        rightDrive = hardwareMap.get(DcMotor.class, "right_drive");

        leftDrive.setDirection(DcMotor.Direction.REVERSE);
        rightDrive.setDirection(DcMotor.Direction.FORWARD);

        waitForStart();

        while (opModeIsActive()) {
            double inches = sensorDistance.getDistance(DistanceUnit.INCH);
            double drive = -gamepad1.left_stick_y;

            if (inches < 5.0 && drive > 0) {
                drive = 0;
            }

            leftDrive.setPower(drive);
            rightDrive.setPower(drive);

            telemetry.addData("range", "%.01f in", inches);
            telemetry.update();
        }
    }
}
```

## Notes

- Dark and transparent surfaces give bad readings. Test against the actual object you plan to detect.
- Each read is an I2C transaction and takes time. Don't read the sensor more then once per loop.
