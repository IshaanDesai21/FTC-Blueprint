---
title: Vision April Tag
panelCategory: "Vision"
date: 2026-03-28
description: How to detect AprilTags and read their pose using the FTC SDK's built-in VisionPortal and AprilTagProcessor.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Vision April Tag

AprilTags are the black-and-white square fiducial markers placed around the field. The FTC SDK ships with a built-in `AprilTagProcessor` that runs on top of the `VisionPortal` camera framework, giving you tag ID, position, and orientation without writing any OpenCV code yourself.

> **Why AprilTags?** Unlike color detection, AprilTags give you an absolute, reliable reference point on the field. Because each tag has a known ID and a known field position, they're the backbone of most autonomous alignment and relocalization strategies.

---

## 1. Setting Up the VisionPortal

Everything in the FTC vision system flows through a `VisionPortal`, which manages the camera, and one or more "processors" that analyze each frame. To detect AprilTags, you attach an `AprilTagProcessor` to the portal.

```java
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.firstinspires.ftc.vision.VisionPortal;
import org.firstinspires.ftc.vision.apriltag.AprilTagDetection;
import org.firstinspires.ftc.vision.apriltag.AprilTagProcessor;

import java.util.List;

private AprilTagProcessor aprilTag;
private VisionPortal visionPortal;

private void initAprilTag() {
    // Create the AprilTag processor.
    aprilTag = new AprilTagProcessor.Builder()
            .build();

    // Create the vision portal by using a builder.
    VisionPortal.Builder builder = new VisionPortal.Builder();
    builder.setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"));
    builder.addProcessor(aprilTag);

    visionPortal = builder.build();
}
```

Call `initAprilTag()` once during `runOpMode()`, before `waitForStart()`.

### Tip
> **Decimation:** `aprilTag.setDecimation(3)` trades detection range for frame rate. Lower decimation (1) detects tags farther away but runs slower; higher decimation (3, the default) runs faster but requires the tag to be closer. You can change this on the fly mid-match if you know you'll be scanning at different ranges during auto vs. teleop.

---

## 2. Reading Detections

Each call to `aprilTag.getDetections()` returns a `List<AprilTagDetection>` for the tags visible in the current frame.

```java
List<AprilTagDetection> currentDetections = aprilTag.getDetections();

for (AprilTagDetection detection : currentDetections) {
    if (detection.metadata != null) {
        telemetry.addLine(String.format("\n==== (ID %d) %s", detection.id, detection.metadata.name));
        telemetry.addLine(String.format("XYZ %6.1f %6.1f %6.1f  (inch)",
                detection.ftcPose.x, detection.ftcPose.y, detection.ftcPose.z));
        telemetry.addLine(String.format("PRY %6.1f %6.1f %6.1f  (deg)",
                detection.ftcPose.pitch, detection.ftcPose.roll, detection.ftcPose.yaw));
        telemetry.addLine(String.format("RBE %6.1f %6.1f %6.1f  (inch, deg, deg)",
                detection.ftcPose.range, detection.ftcPose.bearing, detection.ftcPose.elevation));
    } else {
        // Tag was seen, but it isn't in the loaded tag library, so no pose is available.
        telemetry.addLine(String.format("\n==== (ID %d) Unknown", detection.id));
    }
}
```

`detection.metadata` is only populated for tags that exist in the currently loaded tag library (by default, the current season's field tag set). If a tag isn't recognized, you still get its `id` and pixel `center`, but no `ftcPose`.

### The `ftcPose` Fields

| Field | Meaning |
|---|---|
| `x`, `y`, `z` | Position of the tag relative to the camera (inches by default): X = right, Y = forward, Z = up. |
| `pitch`, `roll`, `yaw` | Rotation of the tag relative to the camera (degrees). |
| `range` | Straight-line distance from the camera to the tag. |
| `bearing` | Horizontal angle from the camera's forward direction to the tag (degrees, positive = tag is to the left). |
| `elevation` | Vertical angle from the camera's forward direction to the tag. |

`range`/`bearing`/`elevation` are usually the most useful fields for driving logic, since they describe the tag directly in terms of "how far" and "which way to turn."

---

## 3. Practical Example: Aligning to a Tag

A common autonomous pattern is to drive toward a specific tag ID until you're within a target range, using `bearing` to steer and `range` to control forward speed.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.hardware.DcMotor;
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.firstinspires.ftc.vision.VisionPortal;
import org.firstinspires.ftc.vision.apriltag.AprilTagDetection;
import org.firstinspires.ftc.vision.apriltag.AprilTagProcessor;

import java.util.List;

@Autonomous(name = "AprilTag Align Example", group = "Vision")
public class AprilTagAlignExample extends LinearOpMode {

    private static final int TARGET_TAG_ID = 3;
    private static final double DESIRED_RANGE = 12.0; // inches

    private AprilTagProcessor aprilTag;
    private VisionPortal visionPortal;

    private DcMotor leftDrive, rightDrive;

    @Override
    public void runOpMode() {
        leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
        rightDrive = hardwareMap.get(DcMotor.class, "rightDrive");

        aprilTag = new AprilTagProcessor.Builder().build();
        visionPortal = new VisionPortal.Builder()
                .setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"))
                .addProcessor(aprilTag)
                .build();

        waitForStart();

        while (opModeIsActive()) {
            AprilTagDetection target = null;

            for (AprilTagDetection detection : aprilTag.getDetections()) {
                if (detection.id == TARGET_TAG_ID && detection.ftcPose != null) {
                    target = detection;
                    break;
                }
            }

            if (target != null) {
                double rangeError = target.ftcPose.range - DESIRED_RANGE;
                double bearingError = target.ftcPose.bearing;

                // Simple proportional control.
                double forward = rangeError * 0.05;
                double turn = bearingError * 0.02;

                leftDrive.setPower(forward + turn);
                rightDrive.setPower(forward - turn);

                telemetry.addData("Range", "%.1f in", target.ftcPose.range);
                telemetry.addData("Bearing", "%.1f deg", target.ftcPose.bearing);
            } else {
                leftDrive.setPower(0);
                rightDrive.setPower(0);
                telemetry.addData("Status", "Target tag not visible");
            }

            telemetry.update();
        }

        visionPortal.close();
    }
}
```

---

> **Save CPU:** Call `visionPortal.stopStreaming()` when you don't need vision temporarily (e.g. during a long non-vision autonomous segment) and `visionPortal.resumeStreaming()` when you need it again. Always call `visionPortal.close()` when your OpMode ends if you created the portal manually and won't reuse it.

### Tip
> **Units:** By default, `ftcPose` distances are in inches and angles in degrees. You can override this with `.setOutputUnits(DistanceUnit.CM, AngleUnit.RADIANS)` on the `AprilTagProcessor.Builder` if your codebase standardizes on metric.
