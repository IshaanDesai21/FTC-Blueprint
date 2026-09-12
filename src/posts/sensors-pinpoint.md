---
title: Pinpoint Odometry Computer
panelCategory: "Sensors"
date: 2026-05-20
description: Reading field position and heading from the goBILDA Pinpoint.
published: true
tags: [software, completed]
author: Blueprint
---

The goBILDA Pinpoint is an I2C device with two encoder ports and its own IMU. Plug two odometry pods into it and it reports X, Y, and heading. The hub reads one device instead of two encoders and the IMU, and the position math runs on the Pinpoint.

## Why odometry pods

Drive wheel encoders slip when the robot strafes or turns, so the position drifts. Odometry pods are unpowered wheels that roll on the floor and do not slip. One pod is mounted to measure forward and back motion, the other to measure left and right.

## Wiring

- Plug the Pinpoint into an I2C port on the Control Hub.
- Plug the forward pod into the X encoder port and the strafe pod into the Y encoder port.
- Mount the pods so the wheels stay on the floor when the robot moves. Spring-loaded pods handle uneven tiles.
- Add the Pinpoint to the robot configuration as an I2C device and name it `pinpoint`.

## Setup

The driver class is `GoBildaPinpointDriver`. Recent SDK versions include it. If the import does not resolve, download the driver from goBILDA and put the file in `TeamCode`.

```java
import com.qualcomm.hardware.gobilda.GoBildaPinpointDriver;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;
import org.firstinspires.ftc.robotcore.external.navigation.Pose2D;

GoBildaPinpointDriver pinpoint = hardwareMap.get(GoBildaPinpointDriver.class, "pinpoint");

pinpoint.setOffsets(-84.0, -168.0, DistanceUnit.MM);
pinpoint.setEncoderResolution(GoBildaPinpointDriver.GoBildaOdometryPods.goBILDA_4_BAR_POD);
pinpoint.setEncoderDirections(
    GoBildaPinpointDriver.EncoderDirection.FORWARD,
    GoBildaPinpointDriver.EncoderDirection.FORWARD
);
pinpoint.resetPosAndIMU();
```

Older standalone versions of the driver take the offsets in millimeters with no unit argument.

**Offsets.** Measured from the robot's center of rotation.

- X offset: how far the forward pod (X) sits to the side of center. Left is positive.
- Y offset: how far the strafe pod (Y) sits ahead of center. Forward is positive.

Wrong offsets show up as heading or position drift when the robot spins in place.

**Encoder resolution.** Use `goBILDA_SWINGARM_POD` or `goBILDA_4_BAR_POD` to match the pods. For other wheels, `setEncoderResolution(double ticksPerMM)` takes the number directly.

**Directions.** If X goes negative when the robot drives forward, or Y goes negative when it strafes left, set that pod to `REVERSED`.

Call `resetPosAndIMU()` at init with the robot still. It zeros the position and calibrates the IMU, and takes a moment to finish.

## Reading position

Call `update()` once per loop, then read the pose.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.hardware.gobilda.GoBildaPinpointDriver;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;
import org.firstinspires.ftc.robotcore.external.navigation.Pose2D;

@TeleOp(name = "Pinpoint Test")
public class PinpointTest extends LinearOpMode {

    @Override
    public void runOpMode() {
        GoBildaPinpointDriver pinpoint = hardwareMap.get(GoBildaPinpointDriver.class, "pinpoint");

        pinpoint.setOffsets(-84.0, -168.0, DistanceUnit.MM);
        pinpoint.setEncoderResolution(GoBildaPinpointDriver.GoBildaOdometryPods.goBILDA_4_BAR_POD);
        pinpoint.setEncoderDirections(
            GoBildaPinpointDriver.EncoderDirection.FORWARD,
            GoBildaPinpointDriver.EncoderDirection.FORWARD
        );
        pinpoint.resetPosAndIMU();

        waitForStart();

        while (opModeIsActive()) {
            pinpoint.update();
            Pose2D pos = pinpoint.getPosition();

            telemetry.addData("X (in)", "%.2f", pos.getX(DistanceUnit.INCH));
            telemetry.addData("Y (in)", "%.2f", pos.getY(DistanceUnit.INCH));
            telemetry.addData("Heading (deg)", "%.2f", pos.getHeading(AngleUnit.DEGREES));
            telemetry.update();
        }
    }
}
```

Push the robot around by hand and watch the numbers. Forward should raise X, left should raise Y, and counter-clockwise rotation should raise heading. Fix any pod that reads backwards with `setEncoderDirections`.

## Driving to a position

Once position is known, a move is a loop that compares current position to a target.

```java
double targetX = 24.0;

while (opModeIsActive()) {
    pinpoint.update();
    double x = pinpoint.getPosition().getX(DistanceUnit.INCH);
    double error = targetX - x;

    if (Math.abs(error) < 0.5) break;

    double power = Math.max(-0.5, Math.min(0.5, error * 0.05));
    frontLeft.setPower(power);
    frontRight.setPower(power);
    backLeft.setPower(power);
    backRight.setPower(power);
}

frontLeft.setPower(0);
frontRight.setPower(0);
backLeft.setPower(0);
backRight.setPower(0);
```

The same idea extends to Y and heading with a controller for each one. Road Runner uses the Pinpoint as a localizer, so if you want full path following rather then single-axis moves, use that instead of writing your own.

## Notes

- Call `update()` exactly once per loop. Reading the position without calling `update()` returns the old value.
- Reset position at the start of autonomous. Position carries over from whatever ran last.
- Keep the pod wheels clean. Dust on the wheel changes the effective diameter and the distances go off.
