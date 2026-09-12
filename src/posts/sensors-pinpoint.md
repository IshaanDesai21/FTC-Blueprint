---
title: Pinpoint Odometry Computer
panelCategory: "Sensors"
date: 2026-05-20
description: Reading field position and heading from the goBILDA Pinpoint.
published: true
tags: [software, completed]
author: Blueprint
---

The goBILDA Pinpoint is an I2C device with two encoder ports and its own IMU. Plug two odometry pods into it and it reports X, Y, and heading. The hub reads one device instead of two encoders and the IMU, and the position math runs on the Pinpoint. The SDK sample is `SensorGoBildaPinpoint`.

## Why odometry pods

Drive wheel encoders slip when the robot strafes or turns, so the position drifts. Odometry pods are unpowered wheels that roll on the floor and do not slip. One pod measures forward and back motion, the other measures left and right.

## Wiring

- Plug the Pinpoint into an I2C port on the Control Hub.
- Plug the forward pod into the X port and the strafe pod into the Y port.
- Mount the pods so the wheels stay on the floor when the robot moves.
- Add the Pinpoint to the robot configuration and name it `pinpoint`.

## Configuration

```java
public void configurePinpoint() {

    // X is how far sideways the forward pod is from the tracking point. Left is positive.
    // Y is how far forward the strafe pod is from the tracking point. Forward is positive.
    pinpoint.setOffsets(-84.0, -168.0, DistanceUnit.MM);

    // Use the pod type you have. For other pods, pass ticks per unit instead:
    // pinpoint.setEncoderResolution(13.26291192, DistanceUnit.MM);
    pinpoint.setEncoderResolution(GoBildaPinpointDriver.GoBildaOdometryPods.goBILDA_4_BAR_POD);

    // X should increase driving forward, Y should increase strafing left.
    pinpoint.setEncoderDirections(GoBildaPinpointDriver.EncoderDirection.FORWARD,
                                  GoBildaPinpointDriver.EncoderDirection.FORWARD);

    // Resets position to 0,0,0 and recalibrates the IMU. Robot must be still.
    pinpoint.resetPosAndIMU();
}
```

Wrong offsets show up as heading or position drift when the robot spins in place. If X falls while driving forward, or Y falls while strafing left, set that pod to `REVERSED`.

The IMU calibrates itself at power on, but recalibrating with `resetPosAndIMU()` while the robot sits still gives a better starting heading. A bad calibration means every position in the routine is off.

## The sample

```java
public class SensorGoBildaPinpoint extends OpMode {

    GoBildaPinpointDriver pinpoint;

    @Override
    public void init() {
        pinpoint = hardwareMap.get(GoBildaPinpointDriver.class, "pinpoint");
        configurePinpoint();

        // Where the robot is starting from.
        pinpoint.setPosition(new Pose2D(DistanceUnit.INCH, 0, 0, AngleUnit.DEGREES, 0));
    }

    @Override
    public void loop() {
        telemetry.addLine("Push your robot around to see it track");
        telemetry.addLine("Press A to reset the position");

        if (gamepad1.a) {
            pinpoint.setPosition(new Pose2D(DistanceUnit.INCH, 0, 0, AngleUnit.DEGREES, 0));
        }

        pinpoint.update();
        Pose2D pose2D = pinpoint.getPosition();

        telemetry.addData("X coordinate (IN)", pose2D.getX(DistanceUnit.INCH));
        telemetry.addData("Y coordinate (IN)", pose2D.getY(DistanceUnit.INCH));
        telemetry.addData("Heading angle (DEGREES)", pose2D.getHeading(AngleUnit.DEGREES));
    }
}
```

Push the robot around by hand and watch the numbers. Forward should raise X, left should raise Y, and counter-clockwise rotation should raise heading.

`setPosition()` takes a known pose, so you can also feed it a position worked out from an [AprilTag](/software/vision-april-tag) reading mid-match to correct accumulated drift.

## Driving to a position

Once position is known, a move is a loop that compares the current position to a target.

```java
double targetX = 24.0;

while (opModeIsActive()) {
    pinpoint.update();
    double x = pinpoint.getPosition().getX(DistanceUnit.INCH);
    double error = targetX - x;

    if (Math.abs(error) < 0.5) break;

    double power = Math.max(-0.5, Math.min(0.5, error * 0.05));
    frontLeftDrive.setPower(power);
    frontRightDrive.setPower(power);
    backLeftDrive.setPower(power);
    backRightDrive.setPower(power);
}

frontLeftDrive.setPower(0);
frontRightDrive.setPower(0);
backLeftDrive.setPower(0);
backRightDrive.setPower(0);
```

The same idea extends to Y and heading with a controller for each. Road Runner can use the Pinpoint as a localizer, so if you want full path following rather then single-axis moves, use that instead of writing your own.

## Notes

- Call `update()` exactly once per loop. Reading the position without calling `update()` returns the previous value.
- Reset the position at the start of autonomous. It carries over from whatever ran last.
- Keep the pod wheels clean. Dust changes the effective diameter and the distances go off.
