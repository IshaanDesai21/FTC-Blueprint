---
title: "Pedro Pathing: Localization"
panelCategory: "Pedro Pathing"
date: 2026-03-28
description: Understanding and configuring localization in Pedro Pathing.
tags: [software, advanced, video, completed]
author: Blueprint
published: true
---

# Localization in Pedro Pathing

Localization is how your robot answers the question "where am I on the field?" Pedro Pathing cannot follow a path it cannot measure progress against: every `follower.update()` call depends on an accurate, low-latency estimate of the robot's current **pose** (X, Y, and heading).

> **Definition:** A "pose" is a snapshot of the robot's position and orientation (`x`, `y`, and `heading`) at a single moment in time. Pedro represents this with its `Pose` class.

---

## 1. How Pedro Tracks Pose

Pedro Pathing doesn't calculate position itself. It delegates that job to a **localizer**. The localizer is the piece of code (and hardware) responsible for producing a `Pose` every loop. The `Follower` just asks the localizer for the current pose and steers toward the path.

Most FTC teams localize using **dead wheel odometry**: unpowered "dead" wheels with encoders, spring-loaded or mounted so they always stay in contact with the field tiles. Because they aren't driven by a motor, they don't slip the way your mecanum wheels do, so their encoder ticks are a much more trustworthy measure of how far the robot actually moved.

Pedro ships with built-in support for a few localizer types, most commonly configured through the `Constants` class in the Pedro Pathing quickstart:

- **Two-wheel + IMU localizer**: one forward pod, one strafe pod, plus the Control Hub's IMU for heading.
- **Three-wheel localizer**: two parallel (forward) pods and one perpendicular (strafe) pod, computing heading purely from the difference between the two parallel encoders.
- **Pinpoint localizer (`PinpointLocalizer`)**: offloads the pod fusion to the [goBILDA Pinpoint Odometry Computer](/software/sensors-pinpoint), which returns a ready-to-use pose over I2C. See our [Pinpoint guide](/software/sensors-pinpoint) for hardware setup.

> [!NOTE]
> Which localizer you use is configured once, in your `Constants`/hardware setup. The rest of your autonomous code (`follower.setStartingPose(...)`, `follower.getPose()`, `follower.followPath(...)`) is identical no matter which localizer is behind it. This is one of the main reasons to use Pedro instead of hand-rolling your own odometry math.

---

## 2. Two-Wheel vs. Three-Wheel Odometry

| | Two-Wheel + IMU | Three-Wheel |
|---|---|---|
| **Pods used** | 1 forward, 1 strafe | 2 forward (parallel), 1 strafe |
| **Heading source** | Control/Expansion Hub IMU | Difference between the two forward pods |
| **Mounting** | Simpler, fewer holes to route | Needs two parallel pods spaced apart symmetrically |
| **Weak point** | IMU drift over long/aggressive matches | Small errors in pod spacing directly skew heading |
| **Best for** | Most teams: simpler build, good accuracy | Teams that want to be independent of IMU drift entirely |

Both approaches work well when tuned correctly. The two-wheel setup is more common because it's mechanically simpler (one fewer pod to fit on the chassis) and the IMU on modern REV hubs is quite good. The three-wheel setup trades that simplicity for immunity to IMU-specific drift, at the cost of needing very precise, symmetric pod placement: any asymmetry in the two forward pods' distance from the center of rotation shows up directly as heading error.

If you're using a [Pinpoint Odometry Computer](/software/sensors-pinpoint), the two-wheel-style pod layout still applies. The Pinpoint just does the encoder-plus-IMU sensor fusion in dedicated hardware instead of on the Control Hub.

---

## 3. Setting and Reading Pose

### Setting the starting pose

Before you follow any paths, tell the `Follower` where the robot is starting from. This matters even in TeleOp: if you skip it, Pedro assumes you're starting at `(0, 0, 0)`, which will make every path built off actual field coordinates wrong.

```java
import com.pedropathing.follower.Follower;
import com.pedropathing.geometry.Pose;

Follower follower;

// Wherever your robot physically starts on the field, in inches and radians
Pose startPose = new Pose(9, 111, Math.toRadians(0));

follower = Constants.createFollower(hardwareMap);
follower.setStartingPose(startPose);
```

> **Tip:** In autonomous, `startPose` should match the exact tile/wall position you place the robot at during setup. In TeleOp, if your autonomous already ran, you generally want to carry the ending pose over (e.g. via a static field) rather than re-zeroing at `(0, 0, 0)`.

### Reading the current pose

Once the follower is running, you can read the live pose at any time with `getPose()`:

```java
Pose currentPose = follower.getPose();

double x = currentPose.getX();
double y = currentPose.getY();
double heading = currentPose.getHeading(); // radians

telemetry.addData("X", "%.2f", x);
telemetry.addData("Y", "%.2f", y);
telemetry.addData("Heading (deg)", "%.2f", Math.toDegrees(heading));
```

Remember to call `follower.update()` once per loop, since this is what actually pulls fresh data from the localizer and advances path following. If you never call `update()`, `getPose()` will keep returning stale data.

---

## 4. Common Localization Problems

### Drift over time

**Symptom:** The robot's reported pose slowly diverges from its real position the longer a match runs, especially heading.

**Causes & fixes:**
- **Slipping pods**: a dead wheel that isn't spring-loaded firmly enough will skip on field tile seams. Check that pods maintain consistent downward pressure across the whole field.
- **IMU drift** (two-wheel setups): small heading errors compound over a match. Re-zero heading between autonomous and TeleOp when possible, and avoid violent collisions that can jolt the IMU.
- **Wheel-diameter/ticks-per-inch miscalibration**: if your tuned ticks-per-inch value is even slightly off, every inch of travel accumulates a proportional error. Re-run Pedro's localization tuning routines (forward/strafe tuners) after any hardware changes to the pods or wheels.

### Wrong pod offsets

**Symptom:** The robot's *heading* looks correct, but X/Y position is consistently wrong in a way that gets worse the more the robot turns. For example, driving straight forward looks fine, but turning in place makes the reported position "orbit" away from the real one.

**Cause:** Pod offsets describe how far each odometry pod sits from the robot's **center of rotation** (typically the geometric center of the drivetrain). If these offsets are wrong, the localizer can't correctly account for the extra arc distance a pod travels when the robot spins.

**Fix:** Physically measure (in inches, or whatever `distanceUnit` you configured) how far each pod is offset from the center of rotation, and double check the sign convention your localizer expects (forward-positive / left-positive is standard in Pedro and the goBILDA Pinpoint). Re-measure any time a pod is remounted.

### Mismatched encoder directions

**Symptom:** Driving the robot forward makes X *decrease*, or strafing left makes Y *decrease*. Position tracks perfectly, just backwards.

**Fix:** Flip the corresponding encoder direction in your localizer configuration rather than trying to compensate for it elsewhere in your code.

> [!WARNING]
> Never try to "fix" a localization sign or direction issue by negating values downstream in your path-following or drive code. Always fix it at the source (the encoder direction or pod offset configuration), otherwise you'll end up with contradictory signs scattered across your codebase that break the next time someone touches the drivetrain.

---

## Full Example

```java
package org.firstinspires.ftc.teamcode;

import com.pedropathing.follower.Follower;
import com.pedropathing.geometry.Pose;
import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;

@Autonomous(name = "Localization Telemetry Example")
public class LocalizationExample extends LinearOpMode {

    private Follower follower;

    @Override
    public void runOpMode() {
        follower = Constants.createFollower(hardwareMap);

        // Set this to the robot's actual starting position on the field
        Pose startPose = new Pose(9, 111, Math.toRadians(0));
        follower.setStartingPose(startPose);

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            // Must be called every loop to refresh the pose from the localizer
            follower.update();

            Pose pose = follower.getPose();
            telemetry.addData("X", "%.2f", pose.getX());
            telemetry.addData("Y", "%.2f", pose.getY());
            telemetry.addData("Heading (deg)", "%.2f", Math.toDegrees(pose.getHeading()));
            telemetry.update();
        }
    }
}
```

---

> [!NOTE]
> Before trusting any autonomous routine, run Pedro's built-in localization test/tuning OpModes and manually push the robot in straight lines and rotations, comparing the telemetry pose against a tape measure on the field. A five-minute tuning check now saves a match-losing missed path later.
