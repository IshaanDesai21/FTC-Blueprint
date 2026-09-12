---
title: Teleop Beginner
panelCategory: "TeleOp"
date: 2026-03-28
description: A practical guide to driving and controlling mechanisms in TeleOp, covering tank drive, arcade drive, button mapping, and a complete working example.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Teleop Beginner

This guide picks up where [Teleop Introduction](/software/teleop-introduction) left off. You'll learn how to turn raw gamepad input into robot movement, how to map buttons to mechanisms, and see a complete `LinearOpMode` that ties it all together.

---

## 1. Reading the Joysticks

Each `Gamepad` object exposes its analog sticks as `float` fields ranging from `-1.0` to `1.0`:

- `left_stick_x`, `left_stick_y`
- `right_stick_x`, `right_stick_y`

> [!WARNING]
> On the FTC SDK, **pushing a stick forward (up) returns a negative Y value**, not positive. This trips up almost every new team. You almost always need to negate `stick_y` before using it as motor power: `-gamepad1.left_stick_y`.

---

## 2. Tank Drive

Tank drive maps each side of the robot to one stick: the left stick controls the left wheels, the right stick controls the right wheels.

```java
double leftPower  = -gamepad1.left_stick_y;
double rightPower = -gamepad1.right_stick_y;

leftDrive.setPower(leftPower);
rightDrive.setPower(rightPower);
```

Since both sticks already range from `-1.0` to `1.0`, no additional clamping is required here: the raw negated stick value is already a valid motor power.

**Pros:** simple to understand, very direct.
**Cons:** turning in place requires pushing the sticks in opposite directions, which can feel unintuitive to new drivers.

---

## 3. Arcade Drive

Arcade drive uses a single stick: pushing forward/back drives the robot, and pushing left/right turns it. This is done by combining a **drive** term and a **turn** term, then clamping the result so no motor is ever asked for more than 100% power.

```java
double drive = -gamepad1.left_stick_y; // Forward / backward
double turn  =  gamepad1.left_stick_x; // Left / right

double leftPower  = drive + turn;
double rightPower = drive - turn;

// Clamp to the valid power range in case drive + turn exceeds 1.0
leftPower  = Range.clip(leftPower, -1.0, 1.0);
rightPower = Range.clip(rightPower, -1.0, 1.0);

leftDrive.setPower(leftPower);
rightDrive.setPower(rightPower);
```

`Range.clip()` comes from `com.qualcomm.robotcore.util.Range` and is the standard FTC SDK utility for clamping a value between a min and max. It's needed here because `drive + turn` (or `drive - turn`) can exceed `±1.0` when both terms are large, which would otherwise throw off the ratio between the two sides or simply get silently clamped by the motor controller in an unpredictable way.

**Pros:** intuitive, single-stick driving; most new drivers pick this up faster.
**Cons:** slightly less direct control over each side individually.

> ### Tip
> Many competitive teams offer **both** as configurable driving styles, or add a "slow mode" trigger that scales all power down (e.g. multiply by `0.5`) for precise positioning near scoring locations.

---

## 4. Handling Stick Drift (Deadzone)

Analog sticks rarely rest at *exactly* `0.0`, since cheap potentiometers can drift and report small values like `0.03` even when untouched. Left unhandled, this causes the robot to creep slowly on its own. Apply a simple deadzone check before using stick values:

```java
public static double applyDeadzone(double value, double threshold) {
    if (Math.abs(value) < threshold) {
        return 0.0;
    }
    return value;
}
```

```java
double drive = applyDeadzone(-gamepad1.left_stick_y, 0.05);
double turn  = applyDeadzone(gamepad1.left_stick_x, 0.05);
```

A threshold of `0.05`-`0.1` is usually enough to eliminate drift without noticeably affecting fine control.

---

## 5. Mapping Buttons to Mechanisms

Beyond the sticks, `Gamepad` exposes buttons as `boolean` fields, and the triggers as `float` fields (`0.0` to `1.0`, unpressed to fully pressed):

| Field | Type | Description |
|---|---|---|
| `gamepad1.a` / `.b` / `.x` / `.y` | `boolean` | Face buttons |
| `gamepad1.left_bumper` / `.right_bumper` | `boolean` | Bumpers |
| `gamepad1.left_trigger` / `.right_trigger` | `float` | Analog triggers (0.0-1.0) |
| `gamepad1.dpad_up` / `.dpad_down` / `.dpad_left` / `.dpad_right` | `boolean` | D-pad |

A simple example: use the bumpers to open and close a claw servo.

```java
if (gamepad2.right_bumper) {
    claw.setPosition(1.0); // Open
} else if (gamepad2.left_bumper) {
    claw.setPosition(0.0); // Closed
}
```

Or use an analog trigger to control intake speed proportionally:

```java
intake.setPower(gamepad2.right_trigger); // 0.0 to 1.0 based on how far it's pressed
```

> [!NOTE]
> Notice the mechanism controls above use `gamepad2`, following the driver/operator split from the [Teleop Introduction](/software/teleop-introduction) guide. Your own robot can assign these however fits your drive team best.

---

## 6. Complete Example: Drivetrain + Claw

This full `LinearOpMode` combines arcade drive on `gamepad1` with a claw servo controlled from `gamepad2`.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.Servo;
import com.qualcomm.robotcore.util.Range;

@TeleOp(name = "Beginner TeleOp", group = "Tutorial")
public class BeginnerTeleOp extends LinearOpMode {

    private DcMotor leftDrive;
    private DcMotor rightDrive;
    private Servo claw;

    private static final double DEADZONE = 0.05;

    @Override
    public void runOpMode() {
        // 1. Initialize hardware
        leftDrive  = hardwareMap.get(DcMotor.class, "leftDrive");
        rightDrive = hardwareMap.get(DcMotor.class, "rightDrive");
        claw       = hardwareMap.get(Servo.class, "claw");

        // 2. Reverse one side so positive power drives both sides forward
        leftDrive.setDirection(DcMotor.Direction.REVERSE);
        rightDrive.setDirection(DcMotor.Direction.FORWARD);

        leftDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        rightDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {

            // 3. Arcade drive (gamepad1 = driver)
            double drive = applyDeadzone(-gamepad1.left_stick_y, DEADZONE);
            double turn  = applyDeadzone(gamepad1.left_stick_x, DEADZONE);

            double leftPower  = Range.clip(drive + turn, -1.0, 1.0);
            double rightPower = Range.clip(drive - turn, -1.0, 1.0);

            leftDrive.setPower(leftPower);
            rightDrive.setPower(rightPower);

            // 4. Claw control (gamepad2 = operator)
            if (gamepad2.right_bumper) {
                claw.setPosition(1.0); // Open
            } else if (gamepad2.left_bumper) {
                claw.setPosition(0.0); // Closed
            }

            // 5. Telemetry
            telemetry.addData("Left Power", "%.2f", leftPower);
            telemetry.addData("Right Power", "%.2f", rightPower);
            telemetry.addData("Claw Position", "%.2f", claw.getPosition());
            telemetry.update();
        }
    }

    private double applyDeadzone(double value, double threshold) {
        if (Math.abs(value) < threshold) {
            return 0.0;
        }
        return value;
    }
}
```

---

## Next Up

Simple `if (gamepad.a)` toggles work fine for a single servo, but they start to break down once a mechanism needs multiple steps, like a claw that must go Open → Closing → Closed, or an automated scoring sequence. The next guide, **[Teleop FSM](/software/teleop-fsm)**, covers finite state machines: the standard pattern for controlling multi-step mechanisms cleanly.

---
