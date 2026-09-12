---
title: Drivetrain Functions
panelCategory: "Encoder Based"
date: 2026-03-27
description: Reusable driveDistance, strafeDistance, and turnDegrees helper methods for a 4-motor encoder-based drivetrain, with a timeout safety pattern.
tags: [software, auto, intermediate, completed]
author: Blueprint
published: true
---

# Drivetrain Functions

[Encoder Autonomous Introduction](/software/encoder-autonomous-introduction) covered the math behind ticks-per-inch and showed `RUN_TO_POSITION` on a single motor. Real autonomous routines need that logic wrapped into reusable methods that move **all four drive motors together**, and they need a safety net so a stuck motor doesn't hang your entire 30-second autonomous.

This post builds `driveDistance()`, `strafeDistance()`, and `turnDegrees()` helper methods for a 4-motor mecanum drivetrain, plus a timeout pattern using `ElapsedTime`.

---

## 1. The tick math, extended to strafing and turning

### Ticks per inch (driving straight)

Same formula as the introduction post:

$$\text{ticksPerInch} = \frac{\text{PPR} \times \text{externalGearRatio}}{\pi \times \text{wheelDiameter}}$$

### Ticks per inch (strafing, mecanum only)

Mecanum wheels slide sideways less efficiently than they roll forward, so most teams apply a **strafing multiplier** (typically 1.1-1.5, found empirically by testing) on top of the straight-line `ticksPerInch`:

$$\text{ticksPerInchStrafe} = \text{ticksPerInch} \times \text{strafingMultiplier}$$

> **Why the multiplier exists:** Mecanum rollers aren't perfectly efficient at 45°, and strafing generally has more scrub/friction than driving straight. Start with a multiplier around 1.1 and tune it by commanding a 24" strafe and measuring how far the robot actually moves.

### Ticks per degree (turning in place)

To turn in place, opposite sides of the drivetrain spin in opposite directions. The distance each wheel needs to travel is the arc length swept by that wheel around the robot's turning center, which depends on the **track width** (the distance between the left and right wheel contact points):

$$\text{ticksPerDegree} = \frac{\text{ticksPerInch} \times \pi \times \text{trackWidth}}{360}$$

This comes from the circumference of the circle each wheel traces during an in-place turn (`π × trackWidth`), converted to ticks, and divided across 360 degrees.

---

## 2. Safety: never trust a bare `while(isBusy())` loop

A naive movement loop looks like this:

```java
while (opModeIsActive() && frontLeft.isBusy()) {
    // wait...
}
```

The problem: if a wheel is physically blocked (pinned against a wall, tangled, or a motor cable comes loose), `isBusy()` can stay `true` indefinitely. That loop will run out your entire autonomous clock waiting for a movement that will never finish.

The fix is a **timeout pattern** using `ElapsedTime`: bail out of the wait loop after a maximum duration, regardless of whether `isBusy()` is still true.

```java
ElapsedTime timer = new ElapsedTime();
timer.reset();

double timeoutSeconds = 3.0;

while (opModeIsActive() && frontLeft.isBusy() && timer.seconds() < timeoutSeconds) {
    // wait, with a safety exit
}
```

---

## 3. Complete example: a 4-motor mecanum drivetrain class

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.util.ElapsedTime;

@Autonomous(name = "Encoder Drivetrain Functions Example", group = "Encoder")
public class EncoderDrivetrainExample extends LinearOpMode {

    private DcMotor frontLeft, frontRight, backLeft, backRight;
    private final ElapsedTime timer = new ElapsedTime();

    // ---- Motor + wheel constants ----
    static final double TICKS_PER_REV        = 537.7; // goBILDA 312 RPM
    static final double WHEEL_DIAMETER_IN    = 4.0;
    static final double EXTERNAL_GEAR_RATIO  = 1.0;
    static final double STRAFE_MULTIPLIER    = 1.15;   // tune empirically
    static final double TRACK_WIDTH_IN       = 14.0;   // distance between left/right wheels

    static final double TICKS_PER_INCH =
            (TICKS_PER_REV * EXTERNAL_GEAR_RATIO) / (Math.PI * WHEEL_DIAMETER_IN);
    static final double TICKS_PER_INCH_STRAFE = TICKS_PER_INCH * STRAFE_MULTIPLIER;
    static final double TICKS_PER_DEGREE =
            (TICKS_PER_INCH * Math.PI * TRACK_WIDTH_IN) / 360.0;

    static final double DEFAULT_TIMEOUT_SECONDS = 3.0;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        // Right-side motors are physically reversed on most drivetrains.
        frontRight.setDirection(DcMotor.Direction.REVERSE);
        backRight.setDirection(DcMotor.Direction.REVERSE);

        resetEncoders();

        waitForStart();
        if (opModeIsActive()) {
            driveDistance(24, 0.5);   // drive forward 24 inches
            turnDegrees(90, 0.4);     // turn in place 90 degrees
            strafeDistance(12, 0.5);  // strafe right 12 inches
        }
    }

    /** Zeroes all four encoders and switches back to encoder-driven mode. */
    private void resetEncoders() {
        for (DcMotor motor : new DcMotor[]{frontLeft, frontRight, backLeft, backRight}) {
            motor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
            motor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        }
    }

    /**
     * Drives straight for a given distance in inches.
     * Positive inches = forward, negative = backward.
     */
    private void driveDistance(double inches, double power) {
        int ticks = (int) (inches * TICKS_PER_INCH);

        setAllTargets(ticks, ticks, ticks, ticks);
        setAllModes(DcMotor.RunMode.RUN_TO_POSITION);
        setAllPower(power);

        waitForMotors(DEFAULT_TIMEOUT_SECONDS);
        stopAndResetToEncoderMode();
    }

    /**
     * Strafes sideways for a given distance in inches (mecanum drivetrain only).
     * Positive inches = right, negative = left.
     */
    private void strafeDistance(double inches, double power) {
        int ticks = (int) (inches * TICKS_PER_INCH_STRAFE);

        // Mecanum strafe: front-left/back-right spin one way,
        // front-right/back-left spin the other way.
        setAllTargets(ticks, -ticks, -ticks, ticks);
        setAllModes(DcMotor.RunMode.RUN_TO_POSITION);
        setAllPower(power);

        waitForMotors(DEFAULT_TIMEOUT_SECONDS);
        stopAndResetToEncoderMode();
    }

    /**
     * Turns in place by a given number of degrees.
     * Positive degrees = clockwise, negative = counter-clockwise.
     */
    private void turnDegrees(double degrees, double power) {
        int ticks = (int) (degrees * TICKS_PER_DEGREE);

        // Clockwise turn: left side drives forward, right side drives backward.
        setAllTargets(ticks, -ticks, ticks, -ticks);
        setAllModes(DcMotor.RunMode.RUN_TO_POSITION);
        setAllPower(power);

        waitForMotors(DEFAULT_TIMEOUT_SECONDS);
        stopAndResetToEncoderMode();
    }

    // ---- Internal helpers ----

    private void setAllTargets(int fl, int fr, int bl, int br) {
        // Targets must be set BEFORE switching to RUN_TO_POSITION.
        frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + fl);
        frontRight.setTargetPosition(frontRight.getCurrentPosition() + fr);
        backLeft.setTargetPosition(backLeft.getCurrentPosition() + bl);
        backRight.setTargetPosition(backRight.getCurrentPosition() + br);
    }

    private void setAllModes(DcMotor.RunMode mode) {
        frontLeft.setMode(mode);
        frontRight.setMode(mode);
        backLeft.setMode(mode);
        backRight.setMode(mode);
    }

    private void setAllPower(double power) {
        frontLeft.setPower(Math.abs(power));
        frontRight.setPower(Math.abs(power));
        backLeft.setPower(Math.abs(power));
        backRight.setPower(Math.abs(power));
    }

    /** Waits for all four motors to finish, or bails out after timeoutSeconds. */
    private void waitForMotors(double timeoutSeconds) {
        timer.reset();
        while (opModeIsActive()
                && timer.seconds() < timeoutSeconds
                && (frontLeft.isBusy() || frontRight.isBusy()
                    || backLeft.isBusy() || backRight.isBusy())) {
            telemetry.addData("FL", frontLeft.getCurrentPosition());
            telemetry.addData("FR", frontRight.getCurrentPosition());
            telemetry.addData("BL", backLeft.getCurrentPosition());
            telemetry.addData("BR", backRight.getCurrentPosition());
            telemetry.addData("Timer", "%.2f / %.2f sec", timer.seconds(), timeoutSeconds);
            telemetry.update();
        }
    }

    private void stopAndResetToEncoderMode() {
        setAllPower(0);
        setAllModes(DcMotor.RunMode.RUN_USING_ENCODER);
    }
}
```

---

## 4. Notes on the helper design

- **Relative targets:** `setAllTargets()` adds to `getCurrentPosition()` rather than using an absolute number. That way each call to `driveDistance()` or `turnDegrees()` moves *relative to wherever the robot currently is*, so you can safely chain multiple movements in a row.
- **Direction convention:** Positive `inches` and `degrees` values mean forward/right/clockwise in this example. Pick a convention, document it in a comment, and stay consistent across your whole codebase.
- **Timeout value:** 3 seconds is a reasonable default for short movements, but tune it to your robot. Too short and a slow-but-legitimate movement gets cut off; too long and a genuinely stuck motor eats your autonomous clock.
- **`RUN_USING_ENCODER` between moves:** Returning to `RUN_USING_ENCODER` after each move (rather than leaving motors in `RUN_TO_POSITION`) keeps the drivetrain in a predictable state and avoids stale target positions carrying into the next command.

### Tip
> **Test each helper in isolation first.** Before chaining `driveDistance()`, `turnDegrees()`, and `strafeDistance()` into a full autonomous, run each one alone and measure the actual distance/angle traveled with a tape measure or protractor. Adjust `TICKS_PER_INCH`, `STRAFE_MULTIPLIER`, or `TRACK_WIDTH_IN` until measured results match commanded ones, since small calibration errors compound quickly once you chain several moves.

---

Once your drivetrain can reliably move known distances and angles, the same `RUN_TO_POSITION` pattern extends naturally to other mechanisms. [Subsystem Functions](/software/encoder-autonomous-subsystem-functions) applies it to arms and linear slides with preset positions and safety clamping.
