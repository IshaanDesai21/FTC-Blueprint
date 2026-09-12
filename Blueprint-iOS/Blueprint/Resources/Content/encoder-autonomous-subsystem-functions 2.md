---
title: Subsystem Functions
panelCategory: "Encoder Based"
date: 2026-03-27
description: Using RUN_TO_POSITION with preset tick constants and Range.clip safety limits to control arms and linear slides in autonomous.
tags: [software, intermediate, completed]
author: Blueprint
published: true
---

# Subsystem Functions

[Drivetrain Functions](/software/encoder-autonomous-drivetrain-functions) applied `RUN_TO_POSITION` to a 4-motor drivetrain. The exact same pattern (set target, set mode, set power, wait with a timeout) works just as well for non-drivetrain mechanisms like **arms** and **linear slides**. The main differences are that these mechanisms usually move between a small set of known, named positions, and they need hard safety limits so a bad target never over-extends or crashes the mechanism into itself.

---

## 1. Preset positions instead of freeform distances

A drivetrain moves to wherever the game requires. An arm or slide, on the other hand, usually only needs to visit a handful of repeatable positions: "down," "low scoring," "high scoring," and so on. Instead of computing ticks from a distance every time, define them once as named constants:

```java
public static final int ARM_POSITION_INTAKE      = 0;
public static final int ARM_POSITION_LOW_SCORE    = 800;
public static final int ARM_POSITION_HIGH_SCORE   = 1600;
public static final int ARM_POSITION_MAX          = 1800; // hard mechanical limit
```

An `enum` works well too if you want to pair each named position with metadata (like a matching claw state):

```java
public enum ArmPosition {
    INTAKE(0),
    LOW_SCORE(800),
    HIGH_SCORE(1600);

    public final int ticks;

    ArmPosition(int ticks) {
        this.ticks = ticks;
    }
}
```

Either approach works. `public static final int` constants are simpler and are what most teams reach for first; an `enum` is worth it once you have several related pieces of data per position.

---

## 2. Safety clamping with `Range.clip`

Unlike a drivetrain, an over-extended arm or slide can physically damage itself: snapping a linear slide past its max extension, or slamming an arm into the robot chassis. Before you ever call `setTargetPosition()`, clamp the requested value into a safe range using `Range.clip()`, from `com.qualcomm.robotcore.util.Range`:

```java
int safeTicks = Range.clip(requestedTicks, MIN_TICKS, MAX_TICKS);
```

`Range.clip(value, min, max)` returns `value` unchanged if it's already within `[min, max]`, or the nearest bound otherwise. It's a cheap, one-line guard against typos, bad sensor data, or a future teammate calling your method with an out-of-range number.

---

## 3. Complete example: an encoder-based arm

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.DcMotorEx;
import com.qualcomm.robotcore.util.ElapsedTime;
import com.qualcomm.robotcore.util.Range;

@Autonomous(name = "Encoder Arm Subsystem Example", group = "Encoder")
public class EncoderArmExample extends LinearOpMode {

    private DcMotorEx arm;
    private final ElapsedTime timer = new ElapsedTime();

    // ---- Preset positions (in encoder ticks) ----
    public static final int ARM_POSITION_INTAKE    = 0;
    public static final int ARM_POSITION_LOW_SCORE  = 800;
    public static final int ARM_POSITION_HIGH_SCORE = 1600;

    // ---- Hard safety limits ----
    public static final int ARM_MIN_TICKS = 0;
    public static final int ARM_MAX_TICKS = 1800;

    public static final double ARM_POWER = 0.6;
    public static final double MOVE_TIMEOUT_SECONDS = 2.5;

    @Override
    public void runOpMode() {
        arm = hardwareMap.get(DcMotorEx.class, "arm");

        arm.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        arm.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        arm.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        waitForStart();
        if (opModeIsActive()) {
            goToPosition(ARM_POSITION_LOW_SCORE);
            sleep(500); // pause to let a claw/servo action happen, for example

            goToPosition(ARM_POSITION_HIGH_SCORE);
            sleep(500);

            goToPosition(ARM_POSITION_INTAKE);
        }
    }

    /**
     * Moves the arm to a target tick count, clamped to a safe range,
     * using RUN_TO_POSITION with a timeout safety net.
     */
    private void goToPosition(int targetTicks) {
        int safeTicks = Range.clip(targetTicks, ARM_MIN_TICKS, ARM_MAX_TICKS);

        // 1. Set the target BEFORE switching modes.
        arm.setTargetPosition(safeTicks);

        // 2. Switch to RUN_TO_POSITION.
        arm.setMode(DcMotor.RunMode.RUN_TO_POSITION);

        // 3. Set the power that drives the closed loop.
        arm.setPower(ARM_POWER);

        // 4. Wait until arrival, with a timeout so a stalled arm can't hang the OpMode.
        timer.reset();
        while (opModeIsActive() && arm.isBusy() && timer.seconds() < MOVE_TIMEOUT_SECONDS) {
            telemetry.addData("Target", safeTicks);
            telemetry.addData("Current", arm.getCurrentPosition());
            telemetry.addData("Current Draw (mA)", arm.getCurrent(com.qualcomm.robotcore.hardware.CurrentUnit.MILLIAMPS));
            telemetry.update();
        }

        // Hold position: leave the motor in RUN_TO_POSITION rather than
        // cutting power, so the arm doesn't fall under gravity.
    }
}
```

---

## 4. Design notes

- **`DcMotorEx` vs `DcMotor`:** The example uses `DcMotorEx` because it exposes extra telemetry like `getCurrent()`, which is useful for detecting a stalled arm (a sudden current spike often means the mechanism has hit a hard stop). Everything used here, including `setTargetPosition()`, `setMode()`, `setPower()`, `isBusy()`, and `getCurrentPosition()`, is inherited from `DcMotor`, so a plain `DcMotor` works identically if you don't need the extra telemetry.
- **Don't cut power after arrival.** Notice `goToPosition()` does *not* call `arm.setPower(0)` at the end, unlike the drivetrain helpers in the previous post. A drivetrain has no reason to fight gravity once stopped, but an arm often does: cutting power on a `RUN_TO_POSITION` arm can let it drop if `ZeroPowerBehavior.BRAKE` isn't enough to hold the load. Leaving it in `RUN_TO_POSITION` with power applied lets the closed loop keep actively holding position.
- **`Range.clip` is cheap insurance.** Even if your preset constants are all within bounds today, clamping protects you from future bugs: a typo'd constant, a miscalculated dynamic target, or a value that came from driver input during a hybrid auto/teleop routine.
- **Timeouts matter even more here than on a drivetrain.** An arm that's mechanically jammed will pin current draw and never satisfy `isBusy() == false`. Without the `timer.seconds() < MOVE_TIMEOUT_SECONDS` check, a single jam could consume your entire autonomous period.

### Tip
> **Linear slides work identically.** Swap `arm` for `slide`, adjust the preset tick constants and `ARM_MAX_TICKS` to match your slide's physical travel limit, and the same `goToPosition()` method applies unchanged. The pattern (presets, `Range.clip`, `RUN_TO_POSITION`, timeout) generalizes to any single-motor mechanism with discrete target positions.

---

Together, these three posts cover the full encoder-based autonomous stack: the [core tick math](/software/encoder-autonomous-introduction), a [reusable drivetrain](/software/encoder-autonomous-drivetrain-functions), and encoder-driven subsystems. From here, teams that outgrow encoder-only autonomous should look at odometry-based options like RoadRunner or Pedro Pathing, and at [PID Control](/software/pid-control) and [Motion Profiling](/software/motion-profiling) for smoother, more precise motion.
