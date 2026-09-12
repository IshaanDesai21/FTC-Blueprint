---
title: Roadrunner Actions
panelCategory: "Roadrunner"
date: 2026-03-28
description: How Road Runner 1.0's Action system works, and how to combine trajectory actions with subsystem actions like intakes and lifts.
tags: [software, manual, beginner, road runner, completed]
author: Blueprint
published: true
---

# Roadrunner Actions

![image.png](/images/posts/roadrunner-actions/1775345533412_image.png)

Road Runner 1.0 replaced the old `TrajectorySequence` + callback API with a much simpler idea: **everything your robot does is an `Action`.** Driving a spline is an action. Running an intake is an action. Waiting is an action. Once movement and mechanisms speak the same language, combining them - sequentially or in parallel - becomes trivial.

---

## Why Actions Replaced Trajectory Sequences

The old `TrajectorySequenceBuilder` API let you attach callbacks (`.addTemporalMarker(...)`) to a trajectory to trigger mechanism code partway through. It worked, but it had real problems:

- **Trajectories and mechanisms were different types.** A `TrajectorySequence` couldn't be composed with arbitrary robot logic - markers were a bolted-on escape hatch, not a real composition tool.
- **Timing was fragile.** Markers fired based on elapsed time or distance along the path, which broke silently if the trajectory was edited later.
- **No easy parallelism.** Running two independent mechanisms alongside a trajectory meant nested callbacks or manual state machines.

The `Action` interface fixes this by giving trajectories, mechanisms, and waits **one shared interface**. Anything that implements it can be sequenced, parallelized, or nested inside anything else that implements it.

---

## The `Action` Interface

```java
public interface Action {
    boolean run(@NonNull TelemetryPacket packet);
}
```

- **`run()` is called repeatedly**, once per loop iteration, from inside `Actions.runBlocking(...)` (or your own loop).
- **Return `true`** to indicate the action isn't finished yet - it will be called again next loop.
- **Return `false`** to indicate the action has completed.
- The `TelemetryPacket` lets the action log data to FTC Dashboard while it runs - useful for debugging exactly when/why an action finished.

> **Key idea:** an `Action` is not "a trajectory." It's any single unit of robot behavior with a start and an end. A trajectory happens to implement it, but so can a claw closing, an intake spinning, or a timed wait.

---

## Writing a Custom Action

Here's a simple custom action for a claw servo that opens and waits briefly for the servo to physically get there:

```java
package org.firstinspires.ftc.teamcode.actions;

import androidx.annotation.NonNull;

import com.acmerobotics.roadrunner.Action;
import com.acmerobotics.dashboard.telemetry.TelemetryPacket;
import com.qualcomm.robotcore.hardware.Servo;
import com.qualcomm.robotcore.util.ElapsedTime;

public class OpenClawAction implements Action {
    private final Servo claw;
    private final ElapsedTime timer = new ElapsedTime();
    private boolean initialized = false;

    public OpenClawAction(Servo claw) {
        this.claw = claw;
    }

    @Override
    public boolean run(@NonNull TelemetryPacket packet) {
        if (!initialized) {
            claw.setPosition(0.5); // open position
            timer.reset();
            initialized = true;
        }

        packet.put("claw timer", timer.seconds());

        // Give the servo 0.3s to physically reach the open position
        return timer.seconds() < 0.3;
    }
}
```

A common pattern is to expose a factory method on your subsystem class instead of instantiating the `Action` directly:

```java
public class Claw {
    private final Servo servo;

    public Claw(HardwareMap hardwareMap) {
        servo = hardwareMap.get(Servo.class, "claw");
    }

    public Action open() {
        return new OpenClawAction(servo);
    }

    public Action close() {
        return packet -> {
            servo.setPosition(0.0);
            return false; // instantaneous, no need to wait
        };
    }
}
```

Note the `close()` example - for simple, instantaneous actions you don't need a dedicated class at all. `Action` is a functional interface, so a lambda works fine.

---

## Combining Actions

Road Runner ships a small set of **action combinators** in `com.acmerobotics.roadrunner`:

| Combinator | Behavior |
|---|---|
| `SequentialAction(a, b, c, ...)` | Runs `a` to completion, then `b`, then `c`, in order. |
| `ParallelAction(a, b, c, ...)` | Calls `run()` on every action each loop, in parallel, until **all** of them return `false`. |
| `SleepAction(seconds)` | Waits a fixed duration - useful for simple timing without a custom class. |

### Example: drive trajectory + mechanism in parallel

This is the pattern you'll use constantly - start a spline, and run an intake or lift at the same time instead of waiting for the drive to finish first:

```java
package org.firstinspires.ftc.teamcode;

import com.acmerobotics.roadrunner.Action;
import com.acmerobotics.roadrunner.ParallelAction;
import com.acmerobotics.roadrunner.SequentialAction;
import com.acmerobotics.roadrunner.Pose2d;
import com.acmerobotics.roadrunner.Vector2d;
import com.acmerobotics.roadrunner.ftc.Actions;
import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;

@Autonomous(name = "Parallel Action Example")
public class ParallelActionExample extends LinearOpMode {
    @Override
    public void runOpMode() {
        Pose2d startPose = new Pose2d(0, 0, 0);
        MecanumDrive drive = new MecanumDrive(hardwareMap, startPose);
        Lift lift = new Lift(hardwareMap);
        Claw claw = new Claw(hardwareMap);

        Action driveToScore = drive.actionBuilder(startPose)
                .splineTo(new Vector2d(24, 24), Math.toRadians(90))
                .build();

        waitForStart();
        if (isStopRequested()) return;

        Actions.runBlocking(
                new SequentialAction(
                        // Drive the spline WHILE raising the lift -
                        // both actions run on the same loop, no threads needed
                        new ParallelAction(
                                driveToScore,
                                lift.raise()
                        ),
                        // Only after both finish, open the claw to score
                        claw.open()
                )
        );
    }
}
```

Because `ParallelAction` calls every child's `run()` on the **same** loop iteration, there's no threading, no race conditions, and no need for synchronization - it's cooperative multitasking, not real concurrency.

---

> **Warning:** Actions run inside `Actions.runBlocking()`, which blocks the OpMode thread in a loop until the outer action returns `false`. If you need to check `opModeIsActive()` or handle emergency stops mid-action, break your `Actions.runBlocking()` calls into smaller chunks rather than one giant action for the whole autonomous.

For a complete worked autonomous using this pattern end-to-end, see [Making an Auto](/).
