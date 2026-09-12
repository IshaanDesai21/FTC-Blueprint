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

Current SDK versions use the `IMU` interface. Older code used `BNO055IMU` directly. The sample for the modern interface is `SensorIMUOrthogonal`.

## Hub orientation

The IMU needs to know how the hub is mounted. You give it the direction the printed logo faces and the direction the USB ports face, both relative to the robot, with left and right as seen from behind the robot.

Orthogonal means each of those two directions must be one of six: `FORWARD`, `BACKWARD`, `UP`, `DOWN`, `LEFT`, `RIGHT`. If the hub is mounted at an angle, use the `SensorIMUNonOrthogonal` sample instead.

```java
RevHubOrientationOnRobot.LogoFacingDirection logoDirection = RevHubOrientationOnRobot.LogoFacingDirection.UP;
RevHubOrientationOnRobot.UsbFacingDirection  usbDirection  = RevHubOrientationOnRobot.UsbFacingDirection.FORWARD;

RevHubOrientationOnRobot orientationOnRobot = new RevHubOrientationOnRobot(logoDirection, usbDirection);

imu = hardwareMap.get(IMU.class, "imu");
imu.initialize(new IMU.Parameters(orientationOnRobot));
```

`"imu"` is the name the Control Hub's IMU has in the default configuration. Picking two directions that cannot both be true throws an exception at initialization. For a REV 9-Axis IMU, use `Rev9AxisImuOrientationOnRobot`, which takes an I2C port direction instead of a USB direction.

## Reading angles

```java
YawPitchRollAngles orientation = imu.getRobotYawPitchRollAngles();
AngularVelocity angularVelocity = imu.getRobotAngularVelocity(AngleUnit.DEGREES);

double yaw   = orientation.getYaw(AngleUnit.DEGREES);
double pitch = orientation.getPitch(AngleUnit.DEGREES);
double roll  = orientation.getRoll(AngleUnit.DEGREES);
```

Yaw is the heading and is the one you want for driving. It is zero at the orientation the robot had when `initialize()` ran. Pitch is front-to-back tilt and roll is side-to-side tilt. `getRobotAngularVelocity()` gives the rotation rate on each axis, which is useful for telling whether the robot has finished turning.

## Resetting heading

```java
imu.resetYaw();
```

This sets the current heading to zero. Field-centric drive usually binds this to a button so the driver can re-zero if the robot starts at an angle.

## Initialization

Call `imu.initialize()` before `waitForStart()` and keep the robot still while it runs. Moving the robot during initialization gives you an offset heading for the whole match.

## The sample

```java
@TeleOp(name = "Sensor: IMU Orthogonal", group = "Sensor")
public class SensorIMUOrthogonal extends LinearOpMode
{
    IMU imu;

    @Override public void runOpMode() throws InterruptedException {

        imu = hardwareMap.get(IMU.class, "imu");

        // Edit these two lines to match how your hub is mounted.
        RevHubOrientationOnRobot.LogoFacingDirection logoDirection = RevHubOrientationOnRobot.LogoFacingDirection.UP;
        RevHubOrientationOnRobot.UsbFacingDirection  usbDirection  = RevHubOrientationOnRobot.UsbFacingDirection.FORWARD;

        RevHubOrientationOnRobot orientationOnRobot = new RevHubOrientationOnRobot(logoDirection, usbDirection);

        imu.initialize(new IMU.Parameters(orientationOnRobot));

        while (!isStopRequested()) {

            telemetry.addData("Hub orientation", "Logo=%s   USB=%s\n ", logoDirection, usbDirection);

            if (gamepad1.y) {
                telemetry.addData("Yaw", "Resetting\n");
                imu.resetYaw();
            } else {
                telemetry.addData("Yaw", "Press Y (triangle) on Gamepad to reset\n");
            }

            YawPitchRollAngles orientation = imu.getRobotYawPitchRollAngles();
            AngularVelocity angularVelocity = imu.getRobotAngularVelocity(AngleUnit.DEGREES);

            telemetry.addData("Yaw (Z)", "%.2f Deg. (Heading)", orientation.getYaw(AngleUnit.DEGREES));
            telemetry.addData("Pitch (X)", "%.2f Deg.", orientation.getPitch(AngleUnit.DEGREES));
            telemetry.addData("Roll (Y)", "%.2f Deg.\n", orientation.getRoll(AngleUnit.DEGREES));
            telemetry.addData("Yaw (Z) velocity", "%.2f Deg/Sec", angularVelocity.zRotationRate);
            telemetry.addData("Pitch (X) velocity", "%.2f Deg/Sec", angularVelocity.xRotationRate);
            telemetry.addData("Roll (Y) velocity", "%.2f Deg/Sec", angularVelocity.yRotationRate);
            telemetry.update();
        }
    }
}
```

This sample runs its loop on `!isStopRequested()` rather than `opModeIsActive()`, so the angles update during init as well as after Start. That is handy while you are working out which orientation values are right.

The IMU is read over I2C, so each call to `getRobotYawPitchRollAngles()` cost time. Read it once per loop and store the result.

## Turning by heading

To turn a set number of degrees, read the yaw, compare it to the target, and drive the motors until the difference is small. The SDK sample for a full gyro-driven autonomous is `RobotAutoDriveByGyro_Linear`, which is more reliable than [turning by encoder counts](/software/encoder-autonomous-drivetrain-functions).
