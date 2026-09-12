---
title: Roadrunner Localization
panelCategory: "Roadrunner"
date: 2026-03-28
description: How Road Runner tracks robot position with Pose2d, the localizer options available, and how to validate them with LocalizationTest.
tags: [software, manual, beginner, road runner, completed]
author: Blueprint
published: true
---

# Roadrunner Localization

Localization is how your robot answers the question **"where am I on the field, right now?"** Every trajectory Road Runner follows depends on this answer being accurate - if localization drifts, the robot will confidently drive to the wrong place.

---

## Pose2d: How Position Is Represented

Road Runner represents robot position and orientation with a single object, `Pose2d`, made of:

- **`x`** - position in inches along the field's X axis
- **`y`** - position in inches along the field's Y axis
- **`heading`** - orientation in radians

```java
Pose2d pose = new Pose2d(24.0, 12.0, Math.toRadians(90));
```

Every localizer's job is the same: continuously update a `Pose2d` estimate as the robot moves, using whatever sensors it has available.

---

## Localizer Options

Road Runner 1.0's quickstart ships with a few localizer implementations. You pick one based on your drivetrain hardware.

### 1. Drive Encoder Localization (`DriveLocalizer`)

Uses the built-in encoders on your drive motors (all four, for mecanum) plus the Control Hub's IMU for heading. No extra hardware required.

- **Pros:** Zero additional cost or build complexity - works with any drivetrain you already have.
- **Cons:** Noticeably less accurate. Wheel slip (especially on mecanum, which slides sideways by design) directly corrupts the position estimate. Accuracy degrades over a match as slop and slip accumulate.

```java
// Wired into MecanumDrive automatically when using the DriveLocalizer variant
localizer = new DriveLocalizer(pose);
```

### 2. Two-Wheel Odometry (`TwoDeadWheelLocalizer`)

Uses two unpowered "dead wheel" encoders (one parallel to the robot's forward direction, one perpendicular) plus the IMU for heading. A middle ground between cost and accuracy.

- Expects the parallel encoder plugged into a port named **`par`** and the perpendicular one into **`perp`** in your hardware configuration.
- Heading still comes from the IMU, so IMU calibration and mounting orientation matter.

### 3. Three-Wheel Odometry (`ThreeDeadWheelLocalizer`)

Uses three dead wheels: two parallel wheels spaced apart (for both position and heading via differential measurement) plus one perpendicular wheel for sideways motion. This is the option recommended in the [Roadrunner Introduction](/) for best accuracy.

- Expects ports named **`par0`**, **`par1`**, and **`perp`**.
- Because heading is derived purely from the difference between the two parallel encoders, it does not depend on the IMU at all - immune to IMU drift, and unaffected by wheel slip on the *driven* wheels since dead wheels spin freely and track true floor distance.

> **Note:** RoadRunner 1.0 also supports the SparkFun **OTOS** optical tracking sensor as a fourth localization option, which needs its own separate calibration OpModes (`OTOSAngularScalarTuner`, `OTOSLinearScalarTuner`, etc.) before standard tuning.

---

## Wiring a Localizer into the Drive Class

The quickstart's `MecanumDrive` constructor picks a localizer based on which lines are uncommented. For three-wheel odometry:

```java
public class MecanumDrive {
    public static Params PARAMS = new Params();

    public final Localizer localizer;

    public MecanumDrive(HardwareMap hardwareMap, Pose2d initialPose) {
        // ... motor and IMU setup omitted ...

        // Use ThreeDeadWheelLocalizer instead of the default DriveLocalizer
        localizer = new ThreeDeadWheelLocalizer(hardwareMap, PARAMS.inPerTick, initialPose);
    }
}
```

Swapping localizers later (say, upgrading from drive encoders to three dead wheels) is usually a one-line change here - the rest of your trajectory code doesn't need to know which localizer is active, since everything downstream just consumes `Pose2d`.

---

## Validating Localization with `LocalizationTest`

Before tuning path-following feedback (or trusting *any* autonomous), run the **`LocalizationTest`** OpMode from the quickstart and manually drive the robot with a gamepad while watching FTC Dashboard's field view and pose telemetry.

**What to check:**

1. **Drive straight down a tile line.** Does the reported `x`/`y` change by the same distance you actually moved? A tape measure and the field tile grid (24 in per tile) make a good ground truth.
2. **Rotate the robot exactly 360° by hand** (or with a turntable/jig). Does `heading` return to approximately where it started?
3. **Drive a full loop around the field perimeter and return to the start.** Does the reported pose match the physical starting position, or has it drifted?

**What good output looks like:** position error under about 1 inch and heading error under 1-2 degrees after a lap around the field. Small, consistent noise is normal; steadily growing drift is not.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Heading drifts even when driving in a straight line | Wrong `trackWidthTicks`, or a dead wheel not making solid floor contact | Re-run `AngularRampLogger`; check pod spring tension |
| Position scale is off (moves 2 ft, reports 4 ft) | Wrong `inPerTick` | Re-run `ForwardPushTest`/`ForwardRampLogger` |
| Sideways drift while driving straight | `perp` pod offset from center measured incorrectly | Re-measure the perpendicular pod's distance from the robot's center of rotation |
| Pose reads `NaN` or freezes | Disconnected encoder cable, or hardware config name mismatch | Check `par0`/`par1`/`perp` (or `par`/`perp`) names match your hardware config exactly |
| Heading is fine but position is inconsistent between runs | Encoder wiring intermittent, or dead wheel skipping on debris | Inspect wiring strain relief and clean the field/wheel |

> **Do this before feedback tuning.** If `LocalizationTest` isn't clean, tuning `FollowerPIDTuner` afterward is pointless - you'd just be teaching the feedback controller to compensate for bad position data, which won't generalize to a real match. See [How To Tune](/) for the full tuning order.
