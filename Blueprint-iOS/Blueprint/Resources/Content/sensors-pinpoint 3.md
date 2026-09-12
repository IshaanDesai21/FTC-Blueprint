---
title: Pinpoint Odometry Computer
panelCategory: "Sensors"
date: 2026-01-01
description: How to use the goBILDA Pinpoint Odometry Computer for accurate, offloaded robot localization.
published: true
tags: [software, completed]
author: Ishaan Desai
---

# Pinpoint Odometry Computer

The **goBILDA Pinpoint Odometry Computer** is a dedicated I2C coprocessor built specifically to solve robot localization. Instead of reading two dead wheel odometry pod encoders on your Control Hub and fusing them with heading data in your own OpMode code, the Pinpoint does that entire computation onboard its own chip (an ESP32-S3, paired with a dedicated IMU) and just hands your robot a ready-to-use position.

> **Why it matters:** Every encoder read your Control Hub performs takes time, and running the pose math (position + heading fusion) every loop adds CPU load. The Pinpoint moves both of those jobs off the Control Hub entirely: your OpMode just asks the Pinpoint for its latest pose over I2C.

---

## 1. What It Actually Does

The Pinpoint reads two perpendicular dead wheel odometry pods (an X/forward pod and a Y/strafe pod) plus its own internal IMU, and fuses them into a single accurate `(x, y, heading)` estimate using pose exponential math, the same category of algorithm used in FRC's most accurate odometry systems. It reports that pose back to your robot over I2C as a `Pose2D`.

This is functionally similar to running a two-wheel-odometry localizer yourself (e.g. with Pedro Pathing's built-in two-wheel + IMU localizer), except the sensor fusion happens on dedicated hardware rather than competing for time with the rest of your OpMode loop.

---

## 2. Wiring

The Pinpoint is an I2C device. Connect it to any I2C port on your REV Control Hub or Expansion Hub, and plug your two dead wheel encoder pods directly into the Pinpoint itself (not into the hub). The Pinpoint reads the encoders directly, then reports the fused result to the hub over I2C.

In the Driver Station's robot configuration, add the device under the I2C port you used and name it something consistent, like `pinpoint`.

> [!WARNING]
> Avoid I2C bus port 0 on the Control Hub if it's already reserved for the hub's built-in IMU on your configuration. Double-check your configuration file if you run into "device not found" errors.

---

## 3. Initialization

Add the `GoBildaPinpointDriver` class to your hardware map lookup. It lives in the `com.qualcomm.hardware.gobilda` package (bundled directly with the FTC SDK/Pedro Pathing quickstart).

```java
import com.qualcomm.hardware.gobilda.GoBildaPinpointDriver;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;
import org.firstinspires.ftc.robotcore.external.navigation.Pose2D;

GoBildaPinpointDriver pinpoint;

pinpoint = hardwareMap.get(GoBildaPinpointDriver.class, "pinpoint");
```

## 4. Setting Pod Offsets

The Pinpoint needs to know how far each odometry pod sits from the point on the robot you want tracked, almost always the robot's center of rotation. Offsets are set with `setOffsets(xOffset, yOffset, distanceUnit)`:

- **X offset**: how far **sideways** from the tracking point the X (forward) pod is. Left of center is positive, right of center is negative.
- **Y offset**: how far **forward** from the tracking point the Y (strafe) pod is. Forward of center is positive, backward is negative.

```java
pinpoint.setOffsets(-84.0, -168.0, DistanceUnit.MM); // measure these on your own robot!
```

> [!CAUTION]
> These default example values are tuned for goBILDA's own reference robot. They are almost certainly wrong for your robot. Physically measure the distance from your tracking center to each pod and enter your own numbers, or your position estimate will be systematically off, worse the more the robot rotates.

Next, tell the Pinpoint what kind of odometry pods you're using so it can convert encoder ticks to real-world distance:

```java
pinpoint.setEncoderResolution(GoBildaPinpointDriver.GoBildaOdometryPods.goBILDA_4_BAR_POD);
// or: GoBildaPinpointDriver.GoBildaOdometryPods.goBILDA_SWINGARM_POD
```

If you're using third-party dead wheel pods, use the overload that takes a raw ticks-per-unit value instead:

```java
pinpoint.setEncoderResolution(13.26291192, DistanceUnit.MM);
```

Finally, set the direction each pod counts in. The forward pod should count up when the robot moves forward; the strafe pod should count up when the robot moves left:

```java
pinpoint.setEncoderDirections(
    GoBildaPinpointDriver.EncoderDirection.FORWARD,
    GoBildaPinpointDriver.EncoderDirection.FORWARD
);
```

If position tracks backwards on one axis, flip the corresponding direction here rather than negating it elsewhere in your code.

## 5. Calibrating and Resetting

Before a match, recalibrate the internal IMU and zero out position while the robot is completely stationary:

```java
pinpoint.resetPosAndIMU(); // resets position to (0,0,0) AND recalibrates the IMU
```

This should be one of the last things you do during `init()`, since it takes a fraction of a second and requires the robot to not be moving. If you only want to recalibrate the gyro without resetting position (for example, mid-match after setting a known pose from AprilTag localization), use `recalibrateIMU()` instead.

You can also explicitly tell the Pinpoint what pose it should be tracking from, useful for setting a field-relative starting position, or for correcting position using a secondary sensor like a camera:

```java
pinpoint.setPosition(new Pose2D(DistanceUnit.INCH, 9, 111, AngleUnit.DEGREES, 0));
```

## 6. Reading Position

Call `update()` once per loop to pull the latest fused pose over I2C, then read it with `getPosition()`, which returns a `Pose2D`:

```java
pinpoint.update();

Pose2D pose = pinpoint.getPosition();
double x = pose.getX(DistanceUnit.INCH);
double y = pose.getY(DistanceUnit.INCH);
double heading = pose.getHeading(AngleUnit.DEGREES);

telemetry.addData("X", "%.2f in", x);
telemetry.addData("Y", "%.2f in", y);
telemetry.addData("Heading", "%.2f deg", heading);
```

The Pinpoint also reports velocity (`getVelX()`, `getVelY()`, `getHeadingVelocity()`) and a device status you can use to detect faults:

```java
telemetry.addData("Status", pinpoint.getDeviceStatus());
```

Possible statuses include `READY`, `CALIBRATING`, `FAULT_NO_PODS_DETECTED`, `FAULT_X_POD_NOT_DETECTED`, `FAULT_Y_POD_NOT_DETECTED`, and `FAULT_BAD_READ`. It's worth checking these in telemetry while bringing up a new robot so a disconnected pod is obvious immediately rather than showing up as silently wrong position data.

### Tip
> **Pedro Pathing integration:** If you're using Pedro Pathing, you generally don't call the Pinpoint driver directly at all. Pedro's Pinpoint localizer wraps this driver for you, and your OpMode just calls `follower.setStartingPose(...)` and `follower.getPose()` as usual. See our [Pedro Pathing localization guide](/software/pedro-localization) for that workflow.

---

## Full Example

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.hardware.gobilda.GoBildaPinpointDriver;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;
import org.firstinspires.ftc.robotcore.external.navigation.Pose2D;

@TeleOp(name = "Pinpoint Example", group = "Sensor")
public class PinpointExample extends LinearOpMode {

    private GoBildaPinpointDriver pinpoint;

    @Override
    public void runOpMode() {
        pinpoint = hardwareMap.get(GoBildaPinpointDriver.class, "pinpoint");

        // 1. Set pod offsets from the robot's center of rotation (measure your own robot!)
        pinpoint.setOffsets(-84.0, -168.0, DistanceUnit.MM);

        // 2. Tell the Pinpoint what kind of pods are attached
        pinpoint.setEncoderResolution(GoBildaPinpointDriver.GoBildaOdometryPods.goBILDA_4_BAR_POD);

        // 3. Set encoder count directions
        pinpoint.setEncoderDirections(
                GoBildaPinpointDriver.EncoderDirection.FORWARD,
                GoBildaPinpointDriver.EncoderDirection.FORWARD
        );

        // 4. Zero position and recalibrate the IMU (robot must be stationary)
        pinpoint.resetPosAndIMU();

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            pinpoint.update();

            Pose2D pose = pinpoint.getPosition();

            telemetry.addData("X (in)", "%.2f", pose.getX(DistanceUnit.INCH));
            telemetry.addData("Y (in)", "%.2f", pose.getY(DistanceUnit.INCH));
            telemetry.addData("Heading (deg)", "%.2f", pose.getHeading(AngleUnit.DEGREES));
            telemetry.addData("Status", pinpoint.getDeviceStatus());
            telemetry.update();
        }
    }
}
```

---

> [!NOTE]
> **Source of truth:** Pod offsets, encoder resolution, and encoder directions are all things you should re-verify any time you physically move a pod or change wheel hardware. A Pinpoint with stale offsets will report confident, smooth-looking numbers that are simply wrong. Always sanity check against a tape measure after any mechanical changes.
