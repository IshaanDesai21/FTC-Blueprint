---
title: Teleop Introduction
panelCategory: "TeleOp"
date: 2026-03-28
description: What TeleOp mode is, how the OpMode lifecycle works, and why FTC teams split control across two gamepads.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Teleop Introduction

TeleOp ("Teleoperated") is the driver-controlled period of an FTC match. Unlike Autonomous, where the robot runs pre-programmed instructions with no human input, TeleOp hands control directly to your drive team through two Xbox-style gamepads plugged into the Driver Station.

> [!NOTE]
> A regulation FTC match is 2 minutes and 30 seconds long: 30 seconds of Autonomous, followed by 2 minutes of Driver-Controlled (TeleOp) period. The last 30 seconds of TeleOp is usually the "Endgame."

---

## 1. The `@TeleOp` Annotation

Any `OpMode` (or `LinearOpMode`) becomes selectable as a TeleOp program on the Driver Station by adding the `@TeleOp` annotation above the class definition.

```java
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;

@TeleOp(name = "Main TeleOp", group = "Competition")
public class MainTeleOp extends LinearOpMode {
    @Override
    public void runOpMode() {
        // your code here
    }
}
```

- `name` is what shows up in the Driver Station's OpMode list.
- `group` lets you organize related OpModes together (e.g. `"Competition"`, `"Test"`).

This is nearly identical to how Autonomous programs are declared, except they use `@Autonomous` instead of `@TeleOp`. The SDK uses this annotation purely to sort OpModes into the correct list on the Driver Station; it has no effect on how your code actually runs.

---

## 2. The TeleOp OpMode Lifecycle

Every `LinearOpMode`, whether Autonomous or TeleOp, follows the same basic lifecycle, but TeleOp code is written a little differently because it needs to react to a human in real time instead of running a fixed script.

1. **Init**: When you press "INIT" on the Driver Station, `runOpMode()` starts executing. This is where you call `hardwareMap.get(...)` for every motor, servo, and sensor, and set initial directions/behaviors.
2. **`waitForStart()`**: Execution pauses here until the driver presses "PLAY" (or Autonomous finishes, if it runs first).
3. **Main Loop**: Once started, `opModeIsActive()` becomes `true` and your `while (opModeIsActive())` loop begins running repeatedly, often hundreds of times per second, for the duration of the TeleOp period.
4. **Stop**: When time runs out or the driver presses "STOP", `opModeIsActive()` becomes `false`, the loop exits, and `runOpMode()` returns.

```java
@Override
public void runOpMode() {
    // 1. Init: set up hardware once
    DcMotor leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");

    telemetry.addData("Status", "Initialized");
    telemetry.update();

    // 2. Wait for the driver to press PLAY
    waitForStart();

    // 3. Main loop: runs continuously until match end or STOP
    while (opModeIsActive()) {
        // Read gamepad input, drive motors, update telemetry
    }

    // 4. Stop: cleanup happens automatically when the loop exits
}
```

> **Key difference from Autonomous:** In Autonomous, your loop body is usually a sequence of discrete steps ("drive forward, then turn, then stop"). In TeleOp, the loop body runs continuously and must re-read gamepad state on **every single iteration**, since the driver's inputs can change at any moment.

---

## 3. Two Gamepads: `gamepad1` and `gamepad2`

The FTC SDK gives every OpMode access to two `Gamepad` objects: `gamepad1` and `gamepad2`. Both are automatically populated with live controller state, so you never construct them yourself.

| Object | Convention | Typical Role |
|---|---|---|
| `gamepad1` | **Driver** | Controls the drivetrain (movement, rotation) |
| `gamepad2` | **Operator / Manipulator** | Controls mechanisms (arms, lifts, claws, intakes, shooters) |

```java
double drivePower = -gamepad1.left_stick_y; // Driver moves the robot
if (gamepad2.a) {
    // Operator triggers a mechanism, e.g. opening a claw
}
```

### Why split control across two people?

Most competitive FTC robots have far more going on than one person can manage safely:

- **Driving well takes full attention.** Navigating the field, avoiding other robots, and lining up for scoring locations is a full-time job for one set of hands.
- **Mechanisms need precision too.** Running a multi-jointed arm, a linear slide, or a turret at the same time as driving leads to fumbled inputs and missed scores.
- **Two brains beat one under time pressure.** With a 2-minute TeleOp period, splitting cognitive load between a driver and an operator lets each person react faster to their half of the job.

Some smaller or simpler robots are driven entirely from `gamepad1`, with the operator's controls duplicated onto `gamepad2` as backup. As robots get more complex, though, a dedicated operator on `gamepad2` becomes standard practice for competitive teams.

> [!WARNING]
> Both controllers must be paired to the Driver Station **in order**: the first controller paired becomes `gamepad1`, the second becomes `gamepad2`. Always double check controller assignment on the Driver Station app before a match.

---

## 4. Where This Series Goes Next

This is the first of three guides on writing TeleOp code:

1. **Teleop Introduction** *(this guide)*: What TeleOp is, the OpMode lifecycle, and the two-gamepad convention.
2. **[Teleop Beginner](/software/teleop-beginner)**: Practical joystick-driven movement (tank drive and arcade drive), mapping buttons to mechanisms, and a complete working example that combines a drivetrain with a servo-controlled claw.
3. **[Teleop FSM](/software/teleop-fsm)**: Using finite state machines to control multi-step mechanisms cleanly, so complex sequences (like an intake-to-outtake transfer) don't turn into tangled `if` statements.

By the end of the series you'll be able to write a robust, competition-ready TeleOp OpMode from scratch.

---
