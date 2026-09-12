---
title: Common Practices
panelCategory: "Miscellaneous"
date: 2026-03-28
description: Practical, scannable software best practices for FTC team codebases.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Common Practices

These are habits that separate a codebase a whole team can work in from one only the original author understands. None of these require advanced knowledge; they're just good defaults worth adopting early in the season, before your codebase grows past the point where cleanup is easy.

---

## 1. Centralize Your Constants

Every hardcoded number scattered through your code (a PID gain, a servo position, a motor's ticks-per-revolution) is a number someone will eventually need to find and tune under time pressure. Put them all in one place.

```java
public class RobotConstants {
    // Drivetrain
    public static final double DRIVE_MAX_POWER = 1.0;
    public static final double TICKS_PER_REV = 537.7;

    // Arm
    public static final int ARM_UP_POSITION = 1200;
    public static final int ARM_DOWN_POSITION = 0;
    public static final double ARM_KP = 0.005;

    // Claw
    public static final double CLAW_OPEN = 0.4;
    public static final double CLAW_CLOSED = 0.75;
}
```

Reference it from anywhere with `RobotConstants.ARM_UP_POSITION`. When a mentor asks "can you nudge the claw open position a bit tighter," that's a one-line change instead of a codebase-wide search.

> **Tip:** Keep `RobotConstants` free of hardware objects (no `DcMotor`, no `Servo`). It should only hold numbers, not live hardware references. Mixing the two makes the class harder to reuse across OpModes.

## 2. Avoid Magic Numbers

A "magic number" is any literal value in your code whose meaning isn't obvious from context.

```java
// Avoid:
if (distanceSensor.getDistance(DistanceUnit.INCH) < 5.0) { ... }

// Prefer:
if (distanceSensor.getDistance(DistanceUnit.INCH) < RobotConstants.WALL_STOP_DISTANCE_IN) { ... }
```

The second version is self-documenting, and because it lives in `RobotConstants`, it's tunable without hunting through control logic to find where it's used.

## 3. Keep Hardware Names Consistent

The string you pass to `hardwareMap.get(...)` has to exactly match the device name configured on the Driver Station/Control Hub. Mismatches here are one of the most common sources of "it worked yesterday" bugs after a re-config.

- Use the same naming convention in your robot configuration file and your code: don't let one say `frontLeftMotor` and the other say `FL_motor`.
- Keep a single class (or section of `RobotConstants`) that lists every hardware device name as a `String` constant, so there's one place to check when a name changes.


```java
public class HardwareNames {
    public static final String FRONT_LEFT_MOTOR = "frontLeftMotor";
    public static final String FRONT_RIGHT_MOTOR = "frontRightMotor";
    public static final String ARM_MOTOR = "armMotor";
    public static final String PINPOINT = "pinpoint";
}
```

```java
DcMotor frontLeft = hardwareMap.get(DcMotor.class, HardwareNames.FRONT_LEFT_MOTOR);
```

> [!WARNING]
> Renaming a device in the Driver Station configuration without updating the matching string in code (or vice versa) throws a runtime `hardwareMap` exception the moment the OpMode initializes. This is usually discovered for the first time on the practice field, not at your desk. Grep for the old name whenever you rename a device.

## 4. Telemetry Hygiene

`telemetry` is one of your main debugging tools, but it's easy to misuse in ways that slow down your loop or hide bugs.

- **Call `telemetry.update()` once per loop.** Every `addData()` just queues a line; nothing is actually sent to the Driver Station until `update()` is called. Calling `update()` multiple times per loop wastes time flushing partial data and can visibly slow down your control loop.
- **Don't leave debug spam in competition code.** Verbose per-loop telemetry you added to debug a specific issue should come back out once it's fixed. Extra `addData()` calls add up, and a cluttered telemetry screen is harder for drivers to read during a match.
- **Put the most actionable data first.** Battery voltage, current subsystem state, and any active faults should be easy to spot at a glance, not buried under twenty lines of raw encoder ticks.

```java
// Correct: gather all data, then flush once
telemetry.addData("Battery", "%.2fV", voltageSensor.getVoltage());
telemetry.addData("Arm State", armState);
telemetry.addData("Heading", "%.1f", heading);
telemetry.update(); // single flush per loop
```

For a deeper look at loop-time performance (including how sensor/encoder reads interact with your loop speed), see our [Bulk Reads guide](/software/bulkreads).

## 5. Safe Defaults on Hardware

A few defaults cost nothing to set and prevent entire categories of bugs:

- **Always set zero power behavior explicitly.** `DcMotor.ZeroPowerBehavior.BRAKE` holds position when power is cut (good for arms/lifts fighting gravity); `FLOAT` lets the motor coast (often better for drivetrains). Don't rely on the SDK's default; declare the behavior you actually want.

```java
armMotor.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
```

- **Always clip motor power to `[-1.0, 1.0]`.** Combining multiple inputs (e.g. drive + strafe + turn in a mecanum mixer) can easily produce a sum outside that range, which the SDK will silently clamp. Doing it yourself keeps the *ratio* between wheel powers correct instead of letting the SDK clamp only some of them.

```java
double frontLeftPower = Range.clip(drive + strafe + turn, -1.0, 1.0);
```

- **Never assume a sensor read succeeded.** Check for `null` or out-of-range values (especially on I2C devices, which can occasionally return a bad read) before acting on them, particularly in autonomous where there's no driver to notice something is wrong.

## 6. Version Control Basics for Teams

Git is what lets multiple students write code on the same robot without overwriting each other's work. A few habits go a long way:

- **Commit early, commit often.** Small, focused commits with clear messages ("fix claw servo direction," not "stuff") are far easier to review and revert than one giant commit at the end of a build session.
- **Use branches for anything experimental.** Try a new subsystem or refactor on a branch, not directly on `main`. If it doesn't work out, you delete the branch instead of untangling `main`.
- **Pull before you push.** Get in the habit of pulling the latest changes before starting work, especially if more than one person edits the same files.
- **Don't commit build artifacts.** Make sure `.gitignore` excludes `build/`, `.gradle/`, and IDE-specific files. Committing generated files creates noisy diffs and merge conflicts that have nothing to do with your actual code.
- **Resolve conflicts deliberately.** When Git flags a merge conflict, read both versions and understand *why* they conflict before picking one. Don't just take "theirs" or "mine" blindly, especially in files like `RobotConstants` where both changes might be needed.

### Tip
> **Protect `main`:** If your Git host supports it (GitHub, GitLab, etc.), consider requiring pull requests into `main` instead of direct pushes. It adds a light review step and makes it much harder for one bad commit to break the competition build for the whole team.

---

Good practices compound. A codebase with centralized constants, consistent naming, and clean telemetry is one where a new team member can find what they need and make a safe change on day one, instead of being afraid to touch anything.
