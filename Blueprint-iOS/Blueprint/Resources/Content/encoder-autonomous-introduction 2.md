---
title: Encoder Autonomous Introduction
panelCategory: "Encoder Based"
date: 2026-03-27
description: What encoder-based autonomous is, when to use it instead of RoadRunner/Pedro Pathing, and the core tick math behind driving known distances.
tags: [software, auto, beginner, completed]
author: Blueprint
published: true
---

# Encoder Autonomous Introduction

**Encoder-based autonomous** is the practice of writing autonomous routines that rely only on your drive motors' built-in rotary encoders: no odometry pods, no RoadRunner, no Pedro Pathing. You tell each motor "spin until you've counted N ticks" and use that to approximate driving a known distance or turning a known angle.

> **Scope:** This is the first post in a three-part series. This post covers the concept and the math. [Drivetrain Functions](/software/encoder-autonomous-drivetrain-functions) builds reusable `driveDistance()` / `turnDegrees()` methods on top of it, and [Subsystem Functions](/software/encoder-autonomous-subsystem-functions) applies the same `RUN_TO_POSITION` pattern to arms and slides.

---

## Why not just use RoadRunner or Pedro Pathing?

RoadRunner and Pedro Pathing are path-following libraries built on **odometry**: dedicated tracking wheels (or dead wheels) that measure the robot's actual position on the field, independent of drivetrain slip. They give you spline paths, velocity control, and localization, but they take real time to install, tune (drive constants, PID/feedforward gains), and debug.

Encoder-based autonomous skips all of that. It uses the encoders that are already built into your drive motors and asks them to do double duty: driving power **and** measuring distance.

### When encoder-based autonomous makes sense

- **Rookie teams** who need a working autonomous before they have the bandwidth to learn a path-following library.
- **Simple autos** with only a handful of discrete motions: drive forward, turn, drive again, maybe score a preload.
- **No time or budget** for building a dead-wheel odometry pod or tuning RoadRunner's drive constants.
- **Quick prototyping**, testing whether a mechanism or scoring sequence works before investing in a more robust localization stack.

### Limitations you should know up front

- **Drift accumulates.** Every turn and drive segment has small errors, and because there's no absolute position reference, those errors stack over the course of the autonomous.
- **No correction for wheel slip.** If a wheel skids (hitting a game piece, a field seam, or another robot), the encoder still counts ticks as if the robot moved, since the motor doesn't know the wheel didn't grip.
- **Sensitive to battery voltage sag.** As the battery voltage drops over a match, motors produce less torque at the same commanded power, which changes acceleration and can throw off timing-sensitive logic (though `RUN_TO_POSITION`, being position-based rather than time-based, is less affected than a pure timed-drive approach).
- **No true localization.** The robot never actually knows its field-relative (x, y, heading) position. It only knows how far its wheels have turned since the last reset. If you need to recover from an unexpected bump or re-localize mid-auto, encoder-only code has no way to do that.

In short: encoder-based autonomous is a great starting point and is genuinely sufficient for many simple autos, but it does not scale well to long, multi-step routines where accumulated error compounds.

---

## The core math: ticks to inches

Every FTC drive motor has a **quadrature encoder** attached to the motor shaft (or gearbox output, depending on the motor). Each full revolution of the encoded shaft produces a fixed number of countable "ticks." That number depends on the motor's internal gearbox ratio, since the encoder itself is typically mounted at the motor, before external gearing.

Some illustrative examples of common FTC motors:

| Motor | Approx. ticks per revolution (PPR) |
|---|---|
| goBILDA 5203 series, 312 RPM (19.2:1 gearbox) | ~537.7 |
| goBILDA 5203 series, 435 RPM (13.7:1 gearbox) | ~384.5 |
| goBILDA 5203 series, 223 RPM (26.9:1 gearbox) | ~751.8 |
| REV HD Hex Motor, 20:1 gearbox | 560 (28 base counts × 20) |
| REV HD Hex Motor, 40:1 gearbox | 1120 (28 base counts × 40) |

> **Always check your specific motor's spec sheet.** Ticks-per-revolution depends on the exact gearbox ratio you bought, and goBILDA and REV both publish the exact PPR for every gear ratio variant they sell. Don't assume; look it up.

### From ticks to inches per revolution

To convert encoder ticks into a real-world distance, you need three numbers:

1. **Ticks per motor revolution** (PPR), from the table above or your motor's spec sheet.
2. **Wheel diameter**, measured in inches, to compute wheel circumference: `circumference = π × diameter`.
3. **External gear ratio**: any additional gearing *between* the motor output and the wheel (belts, gears, chain). If the wheel is mounted directly on the motor shaft, this ratio is 1.0.

This gives the formula every encoder-based auto is built on:

$$\text{ticksPerInch} = \frac{\text{PPR} \times \text{externalGearRatio}}{\pi \times \text{wheelDiameter}}$$

**Worked example:** a goBILDA 312 RPM motor (537.7 PPR) and a 4-inch diameter wheel mounted directly on the motor shaft (no external gearing, ratio = 1.0):

```
ticksPerInch = (537.7 × 1.0) / (π × 4.0)
             = 537.7 / 12.566
             ≈ 42.8 ticks per inch
```

To drive 24 inches, you'd command a target of `24 × 42.8 ≈ 1027` ticks.

---

## Driving to a position with RUN_TO_POSITION

The FTC SDK's `DcMotor` class has a built-in closed-loop mode, `RUN_TO_POSITION`, that handles the ticks-to-power conversion for you internally. You give it a target tick count and a power cap, and the motor controller drives toward that target and holds it.

> **Order matters.** The SDK requires you to call `setTargetPosition()` **before** switching the mode to `RUN_TO_POSITION`. If you set the mode first, the target position update won't take effect correctly. The safe sequence is always: **set target → set mode → set power.**

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.hardware.DcMotor;

@Autonomous(name = "Encoder Basics Example", group = "Encoder")
public class EncoderBasicsExample extends LinearOpMode {

    private DcMotor frontLeft;

    // Motor + wheel constants (see math above)
    static final double TICKS_PER_REV     = 537.7; // goBILDA 312 RPM
    static final double WHEEL_DIAMETER_IN = 4.0;
    static final double EXTERNAL_GEARING  = 1.0;
    static final double TICKS_PER_INCH =
            (TICKS_PER_REV * EXTERNAL_GEARING) / (Math.PI * WHEEL_DIAMETER_IN);

    @Override
    public void runOpMode() {
        frontLeft = hardwareMap.get(DcMotor.class, "frontLeft");

        // Reset the encoder to zero before we start counting ticks.
        frontLeft.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        frontLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);

        waitForStart();
        if (opModeIsActive()) {
            // Drive forward 24 inches.
            int targetTicks = (int) (24 * TICKS_PER_INCH);

            // 1. Set the target BEFORE switching modes.
            frontLeft.setTargetPosition(targetTicks);

            // 2. Switch to RUN_TO_POSITION.
            frontLeft.setMode(DcMotor.RunMode.RUN_TO_POSITION);

            // 3. Set the power that drives the closed loop.
            frontLeft.setPower(0.5);

            // 4. Wait until the motor reports it has arrived.
            while (opModeIsActive() && frontLeft.isBusy()) {
                telemetry.addData("Target", targetTicks);
                telemetry.addData("Current", frontLeft.getCurrentPosition());
                telemetry.update();
            }

            // Stop the motor once we've arrived.
            frontLeft.setPower(0);
            frontLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        }
    }
}
```

A few details worth internalizing here:

- **`STOP_AND_RESET_ENCODER`** zeroes the encoder count. Always do this once at the start of your OpMode (or right before a movement) so your tick math is relative to a known starting point.
- **`isBusy()`** returns `true` while the motor is still actively trying to reach its target. It's what lets a `while` loop wait for the motion to finish.
- **`setPower()`** in `RUN_TO_POSITION` mode doesn't set a constant speed. Instead, it sets the *maximum* power the internal control loop is allowed to use while driving toward the target. The motor will automatically slow down and stop as it nears the target tick count.

### Tip
> **A single motor is rarely the whole story.** Real drivetrains have 3-4 motors that all need targets set and modes switched together, plus you'll want a timeout so a stalled motor doesn't hang your autonomous forever. That's exactly what [Drivetrain Functions](/software/encoder-autonomous-drivetrain-functions) covers next: reusable `driveDistance()` and `turnDegrees()` helpers you can drop into any OpMode.
