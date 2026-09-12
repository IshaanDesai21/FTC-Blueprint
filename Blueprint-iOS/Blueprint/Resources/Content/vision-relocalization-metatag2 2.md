---
title: Vision Relocalization Metatag2
panelCategory: "Vision"
date: 2026-03-28
description: Using AprilTag-based pose estimates (including Limelight's MegaTag2) to correct drivetrain odometry drift mid-match.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Vision Relocalization (MegaTag2)

Odometry (wheel encoders, dead wheels, or built-in IMU-based pose estimation like RoadRunner or Pedro Pathing) drifts over time. Wheels slip, dead wheels skip on field tile seams, and small errors accumulate every update cycle. Over a 30-second autonomous, that drift is usually small, but if you rely on the same pose estimate deep into a long teleop match, it can be off by several inches.

AprilTags fixed at known, unmoving locations on the field solve this. Because you always know exactly where a tag is on the field, a detection of that tag tells you exactly where your camera (and therefore your robot) is, independent of anything your wheels have done. This is called **relocalization**: periodically overwriting or correcting your drivetrain's pose estimate using a fresh, drift-free vision measurement.

> **Note:** "MetaTag2" is a common misspelling: the actual feature is **MegaTag2**, a Limelight-specific pose-fusion pipeline built on top of standard AprilTag detection. If you're not using a Limelight, you can still relocalize using the FTC SDK's built-in `AprilTagProcessor` pose data covered in the [AprilTag guide](/software/vision-april-tag). The concept is identical, just without Limelight's multi-tag fusion.

---

## 1. Two Ways to Get a Field-Relative Pose

### Option A: FTC SDK AprilTagProcessor

If a tag is in your loaded tag library, `detection.ftcPose` gives you the tag's position **relative to the camera**. To turn that into a **field-relative robot pose**, you combine it with the tag's known field position (from the tag library metadata) and your camera's mounting offset on the robot. This math is the same idea MegaTag2 automates for you, just done manually.

### Option B: Limelight MegaTag2

If your team runs a Limelight 3A, MegaTag2 does this fusion on-device and hands you a ready-to-use field pose. MegaTag2 improves on basic single-tag localization by using your robot's known heading (yaw) to eliminate pose ambiguity, so it returns a single, stable pose estimate even from one tag at a steep viewing angle. You don't need multiple tags in view for a clean result.

MegaTag2 requires you to feed it your robot's current heading (usually from the Control Hub's built-in IMU) every loop, **before** reading the pose:

```java
import com.qualcomm.hardware.limelightvision.Limelight3A;
import com.qualcomm.hardware.limelightvision.LLResult;
import org.firstinspires.ftc.robotcore.external.navigation.Pose3D;
import com.qualcomm.robotcore.hardware.IMU;

Limelight3A limelight;
IMU imu;

// In init():
limelight = hardwareMap.get(Limelight3A.class, "limelight");
imu = hardwareMap.get(IMU.class, "imu");
limelight.pipelineSwitch(0);
limelight.start();

// In the loop, every cycle:
double robotYawDegrees = imu.getRobotYawPitchRollAngles().getYaw(AngleUnit.DEGREES);
limelight.updateRobotOrientation(robotYawDegrees);

LLResult result = limelight.getLatestResult();
if (result != null && result.isValid()) {
    Pose3D botposeMt2 = result.getBotpose_MT2();
    // botposeMt2 gives a field-relative robot pose fused from AprilTag + heading data.
}
```

> **Order matters:** You must call `updateRobotOrientation()` with your current heading *before* calling `getBotpose_MT2()` on that same cycle, since MegaTag2's fusion math depends on having a fresh yaw value.

---

## 2. Feeding a Vision Pose Into Odometry

Whether you got the pose from `ftcPose` math or `getBotpose_MT2()`, the pattern for correcting your drivetrain's pose estimate is the same: only trust the vision reading when it's valid and reasonably fresh, and overwrite (or blend into) your localizer's current pose.

Both RoadRunner and Pedro Pathing expose a way to directly set the drivetrain's current pose estimate: RoadRunner via something like `drive.localizer.setPose(pose)` (API varies by RoadRunner version), and Pedro Pathing via its `Follower`'s pose-setting method. Check your specific version's docs for the exact call, but the integration shape looks like this:

```java
LLResult result = limelight.getLatestResult();

if (result != null && result.isValid()) {
    Pose3D botposeMt2 = result.getBotpose_MT2();

    // Convert Limelight's field-origin convention (meters, centered at field
    // center) into whatever units/origin your localizer expects (often inches,
    // origin at a field corner). Always double check this conversion carefully.
    double visionX = metersToInches(botposeMt2.getPosition().x);
    double visionY = metersToInches(botposeMt2.getPosition().y);
    double visionHeadingRad = botposeMt2.getOrientation().getYaw(AngleUnit.RADIANS);

    // Example: RoadRunner-style pose overwrite.
    // drive.localizer.setPose(new Pose2d(visionX, visionY, visionHeadingRad));

    // Example: Pedro Pathing-style pose overwrite.
    // follower.setPose(new Pose(visionX, visionY, visionHeadingRad));
}
```

### Tip
> **Don't overwrite blindly.** A single bad frame (motion blur, a tag partially blocked by another robot, reflections) can produce a wildly wrong pose. Common safeguards: only accept a vision pose if `isValid()` is true, if the reported distance to the tag is within a sane range, and if the new pose isn't absurdly far from your current odometry estimate (which would suggest a bad reading rather than real drift).

---

## 3. When to Relocalize

- **Start of teleop:** Reset your pose the moment a tag is visible, since autonomous drift compounds right up to the driver's first inputs.
- **Periodically during teleop:** If your robot's path regularly passes near field-fixed tags (e.g. tags mounted on a backdrop or goal), correct pose every time one comes into view rather than waiting for a specific "relocalize" button press.
- **Before a precision autonomous action:** If a cycle-critical action (scoring, docking) depends on accurate position, relocalize right before executing it rather than trusting several seconds of accumulated odometry.

> **Field of view matters:** Relocalization only works when a tag is actually visible. Mount your vision camera (Limelight or webcam) with a wide enough field of view, and at a height/angle that keeps relevant tags in frame during the parts of the match where you need corrections most.

---

## 4. Practical Example: Relocalize-on-Sight

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.hardware.limelightvision.Limelight3A;
import com.qualcomm.hardware.limelightvision.LLResult;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.IMU;
import org.firstinspires.ftc.robotcore.external.navigation.AngleUnit;
import org.firstinspires.ftc.robotcore.external.navigation.Pose3D;

@TeleOp(name = "MegaTag2 Relocalization Example", group = "Vision")
public class MegaTag2RelocalizationExample extends LinearOpMode {

    private Limelight3A limelight;
    private IMU imu;

    @Override
    public void runOpMode() {
        limelight = hardwareMap.get(Limelight3A.class, "limelight");
        imu = hardwareMap.get(IMU.class, "imu");

        limelight.pipelineSwitch(0);
        limelight.start();

        waitForStart();

        while (opModeIsActive()) {
            double robotYawDegrees = imu.getRobotYawPitchRollAngles().getYaw(AngleUnit.DEGREES);
            limelight.updateRobotOrientation(robotYawDegrees);

            LLResult result = limelight.getLatestResult();
            if (result != null && result.isValid()) {
                Pose3D botposeMt2 = result.getBotpose_MT2();

                telemetry.addData("Vision Pose", botposeMt2.toString());

                // Only relocalize on a driver button press, so a bad frame
                // can't silently teleport the pose estimate mid-cycle.
                if (gamepad1.a) {
                    // drive.localizer.setPose(convertToFieldPose(botposeMt2));
                    telemetry.addLine("Pose corrected from AprilTag!");
                }
            } else {
                telemetry.addData("Vision", "No valid tag in view");
            }

            telemetry.update();
        }

        limelight.stop();
    }
}
```

> **Bottom line:** AprilTags turn "where do I think I am" (odometry, which drifts) into "where am I actually" (vision, which doesn't) every time one is in view. Whether you get there through the FTC SDK's `AprilTagProcessor` or Limelight's MegaTag2, the underlying idea (fixed field tags as absolute ground truth) is the same.
