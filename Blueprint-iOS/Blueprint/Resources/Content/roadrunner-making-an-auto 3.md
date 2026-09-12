---
title: Roadrunner Making An Auto
panelCategory: "Roadrunner"
date: 2026-03-28
description: A complete worked example of building and running a Road Runner 1.0 autonomous OpMode from scratch.
tags: [software, manual, beginner, road runner, completed]
author: Blueprint
published: true
---

# Roadrunner Making An Auto

Once your robot is [tuned](/), writing an autonomous is mostly about chaining trajectory calls onto a `TrajectoryActionBuilder` and running the result. This guide walks through a full example, piece by piece, then shows the complete OpMode.

---

## 1. Initialize the Drive Class

Every Road Runner auto starts by constructing your drive class with the robot's **starting pose** - its `x`, `y`, and heading on the field at the moment the OpMode begins.

```java
Pose2d startPose = new Pose2d(0, 0, Math.toRadians(0));
MecanumDrive drive = new MecanumDrive(hardwareMap, startPose);
```

> **This pose matters more than anything else in the file.** Every `splineTo()`, `lineToX()`, and `strafeTo()` call afterward is relative to it. Get it wrong and the whole autonomous will be offset on the field even though the code "runs fine."

---

## 2. Build a Trajectory with `TrajectoryActionBuilder`

Call `drive.actionBuilder(startPose)` to get a builder, then chain movement calls onto it. Common methods:

| Method | What it does |
|---|---|
| `.lineToX(x)` / `.lineToY(y)` | Straight line to an absolute X or Y coordinate, keeping current heading/tangent |
| `.strafeTo(new Vector2d(x, y))` | Straight line to an absolute point |
| `.splineTo(new Vector2d(x, y), heading)` | Smooth curved path to a point, ending at the given heading |
| `.turn(radians)` | Turn in place by a relative angle |
| `.turnTo(radians)` | Turn in place to an absolute heading |
| `.setTangent(radians)` | Overrides the direction the next path segment leaves the current point |
| `.waitSeconds(seconds)` | Pauses in place |

Chain as many as you need, then finish with `.build()` to get a single `Action`:

```java
Action toScorePreload = drive.actionBuilder(startPose)
        .splineTo(new Vector2d(24, 24), Math.toRadians(90))
        .waitSeconds(0.5)
        .build();
```

`.build()` does **not** run anything - it just compiles the chain into an `Action` you can run later (or combine with other actions, see [Roadrunner Actions](/)).

---

## 3. Run It with `Actions.runBlocking()`

Inside your `LinearOpMode`, after `waitForStart()`, hand the built action to `Actions.runBlocking()`. This blocks the OpMode thread, repeatedly calling `run()` on the action (and updating FTC Dashboard telemetry) until it completes.

```java
waitForStart();
Actions.runBlocking(toScorePreload);
```

---

## Full Example

Here's a complete, self-contained autonomous OpMode: drive from the start, spline to a scoring position, strafe over, turn to face a second target, and park.

```java
package org.firstinspires.ftc.teamcode;

import com.acmerobotics.roadrunner.Action;
import com.acmerobotics.roadrunner.Pose2d;
import com.acmerobotics.roadrunner.SequentialAction;
import com.acmerobotics.roadrunner.Vector2d;
import com.acmerobotics.roadrunner.ftc.Actions;
import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;

@Autonomous(name = "Basic Spline Auto")
public class BasicSplineAuto extends LinearOpMode {

    @Override
    public void runOpMode() {
        // 1. Starting pose - must match where the robot physically sits at init
        Pose2d startPose = new Pose2d(0, 0, Math.toRadians(0));
        MecanumDrive drive = new MecanumDrive(hardwareMap, startPose);

        // 2. Build each leg of the path as its own action
        Action toScorePosition = drive.actionBuilder(startPose)
                .splineTo(new Vector2d(24, 24), Math.toRadians(90))
                .build();

        Action toSecondTarget = drive.actionBuilder(new Pose2d(24, 24, Math.toRadians(90)))
                .lineToY(36)
                .turn(Math.toRadians(-90))
                .build();

        Action parkAction = drive.actionBuilder(new Pose2d(24, 36, Math.toRadians(0)))
                .strafeTo(new Vector2d(12, 36))
                .build();

        telemetry.addLine("Ready - waiting for start");
        telemetry.update();

        waitForStart();
        if (isStopRequested()) return;

        // 3. Run every leg in order
        Actions.runBlocking(
                new SequentialAction(
                        toScorePosition,
                        toSecondTarget,
                        parkAction
                )
        );

        telemetry.addLine("Autonomous complete");
        telemetry.update();
    }
}
```

> **Why build each leg separately instead of one giant chain?** Splitting the path into named `Action` variables (`toScorePosition`, `toSecondTarget`, `parkAction`) makes it far easier to insert mechanism actions between legs later, or to reorder/skip legs based on a vision result. See [Roadrunner Actions](/) for combining these with intake/lift/claw actions.

---

## Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Starting a new `actionBuilder()` from the wrong pose | Robot cuts across the field diagonally between legs | Chain `actionBuilder` calls from the **ending pose** of the previous leg, not the original `startPose` |
| Building the action before `waitForStart()` but expecting live sensor data | Auto doesn't react to vision/sensor input read after `waitForStart()` | Build the action *after* you've read whatever data determines the path (e.g. an AprilTag result) |
| Calling `.build()` multiple times or reusing an `Action` object | Trajectory behaves oddly on repeated runs | Build a fresh `Action` each time you need to run that path again |
| Forgetting `isStopRequested()` checks | OpMode doesn't stop cleanly if stopped mid-autonomous | Check `isStopRequested()` before/between `Actions.runBlocking()` calls |

Once this runs correctly on the field, use [MeepMeep](/) to visualize and iterate on paths without redeploying to the robot every time.
