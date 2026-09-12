---
title: Roadrunner Meepmeep
panelCategory: "Roadrunner"
date: 2026-03-28
description: How to use MeepMeep, Road Runner's desktop path visualizer, to design and check trajectories without deploying to the robot.
tags: [software, manual, beginner, road runner, completed]
author: Blueprint
published: true
---

# Roadrunner Meepmeep

MeepMeep is a small desktop Java application, separate from your FTC robot project, that visually simulates Road Runner trajectories on your computer. It draws your robot's path on a field image and animates it exactly as Road Runner would run it - no robot, no deploy cycle, no battery required.

---

## Why Use It?

Iterating on a trajectory directly on the robot is slow: change a coordinate, build, deploy, drive to a starting position, run, watch, repeat. MeepMeep collapses that loop to seconds.

- **Instant feedback** - edit a `.splineTo()` call and re-run the simulation immediately.
- **Catch obviously broken paths** before they ever touch the field - a robot driving through a wall, a spline looping the wrong way, a heading pointing backward.
- **Sanity-check timing** - watch two `Action`s run in parallel to see whether a mechanism action will actually finish before the drive gets there.

> MeepMeep does not replace field testing. It uses the same trajectory *planning* math as Road Runner, but it doesn't know about wheel slip, battery sag, or your actual tuned constants unless you enter them.

---

## Setting Up MeepMeep

MeepMeep is its own standalone Java/Gradle project (it is **not** added to your `TeamCode` module). The simplest path is to clone or download the [MeepMeep repository](https://github.com/acmerobotics/MeepMeep) and open it in IntelliJ IDEA or Android Studio as a separate project.

Add the dependency in your MeepMeep project's `build.gradle` if you're integrating it manually:

```gradle
repositories {
    maven { url = 'https://maven.brott.dev/' }
}

dependencies {
    implementation 'com.acmerobotics.roadrunner:MeepMeep:0.1.7'
}
```

> Check the [MeepMeep repository](https://github.com/acmerobotics/MeepMeep) for the current version number before adding it - this is a fast-moving dependency.

---

## Basic Usage

A MeepMeep program has four parts: create the `MeepMeep` instance, build a robot entity with constraints and a trajectory, add it to the field, and start the simulation.

```java
import com.acmerobotics.roadrunner.Pose2d;
import com.acmerobotics.roadrunner.Vector2d;
import com.noahbres.meepmeep.MeepMeep;
import com.noahbres.meepmeep.roadrunner.DefaultBotBuilder;
import com.noahbres.meepmeep.roadrunner.entity.RoadRunnerBotEntity;

public class MeepMeepTesting {
    public static void main(String[] args) {
        // Field is 800px square in the simulator window
        MeepMeep meepMeep = new MeepMeep(800);

        RoadRunnerBotEntity myBot = new DefaultBotBuilder(meepMeep)
                // Match these to your tuned constants for a realistic sim
                .setConstraints(60, 60, Math.toRadians(180), Math.toRadians(180), 15)
                .build();

        myBot.runAction(myBot.getDrive().actionBuilder(new Pose2d(0, 0, 0))
                .splineTo(new Vector2d(24, 24), Math.toRadians(90))
                .waitSeconds(1)
                .lineToY(48)
                .build());

        meepMeep.setBackground(MeepMeep.Background.FIELD_INTO_THE_DEEP_JUICE_DARK)
                .setDarkMode(true)
                .setBackgroundAlpha(0.95f)
                .addEntity(myBot)
                .start();
    }
}
```

Running `main()` opens a window that loops the animation, letting you visually confirm the path before touching the robot.

### `setConstraints()` parameters

```java
.setConstraints(maxVel, maxAccel, maxAngVel, maxAngAccel, trackWidth)
```

Enter your **actual tuned values** from `MecanumDrive.Params` here (`maxWheelVel`, `maxProfileAccel`, `maxAngVel`, `maxAngAccel`, `trackWidthTicks` converted to inches) so the simulated path timing matches what the real robot will do.

---

## Simulating Multiple Robots

MeepMeep supports adding more than one `RoadRunnerBotEntity` to the same field - useful for planning around an alliance partner or opponent robot to avoid collisions:

```java
RoadRunnerBotEntity opponentBot = new DefaultBotBuilder(meepMeep)
        .setConstraints(50, 50, Math.toRadians(180), Math.toRadians(180), 15)
        .setColorScheme(new ColorSchemeRedDark())
        .build();

opponentBot.runAction(opponentBot.getDrive().actionBuilder(new Pose2d(-24, -24, 0))
        .lineToY(0)
        .build());

meepMeep.addEntity(myBot)
        .addEntity(opponentBot)
        .start();
```

---

## Tips for Using MeepMeep Effectively

| Tip | Why |
|---|---|
| Keep constraints in sync with your tuned `Params` | Otherwise the simulated timing (and whether parallel actions finish in time) will be misleading |
| Use the same coordinate system as your real code | Copy field coordinates directly out of your OpMode so you're testing the actual path, not a rough approximation |
| Watch for the path looping the "long way" around on `splineTo()` | Usually means the target heading or tangent doesn't match the direction you intended |
| Re-check in MeepMeep after any coordinate edit | It's free and instant - there's no reason to skip straight to field testing after a change |

Once a path looks right in MeepMeep, copy the same `actionBuilder()` chain into your real OpMode. See [Making an Auto](/) for the full pattern of building and running that chain on the robot.
