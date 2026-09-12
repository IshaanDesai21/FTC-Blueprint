---
title: AprilTag Detection
panelCategory: "Vision"
date: 2026-04-14
description: Detecting AprilTags with VisionPortal and driving toward one.
tags: [software, beginner, completed]
author: Blueprint
published: true
---

AprilTags are square black and white markers placed on the field. The SDK detects them from a webcam and reports the distance and angle from the camera to each tag. Every tag has an ID, and the field tag positions are listed in the game manual.

## Requirements

- A USB webcam plugged into the Control Hub.
- The webcam in the robot configuration. The default name is `Webcam 1`.
- SDK 8.2 or newer, which has `VisionPortal` and `AprilTagProcessor`.

## Setup

`AprilTagProcessor` does the detection. `VisionPortal` runs the camera and feeds it frames.

```java
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.firstinspires.ftc.vision.VisionPortal;
import org.firstinspires.ftc.vision.apriltag.AprilTagProcessor;

AprilTagProcessor aprilTag = new AprilTagProcessor.Builder().build();

VisionPortal visionPortal = new VisionPortal.Builder()
    .setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"))
    .addProcessor(aprilTag)
    .build();
```

Build this before `waitForStart()`. The defaults use the current season's tag library, so the range numbers are correct for the official tags.

## Reading detections

```java
import org.firstinspires.ftc.vision.apriltag.AprilTagDetection;
import java.util.List;

List<AprilTagDetection> detections = aprilTag.getDetections();
for (AprilTagDetection detection : detections) {
    if (detection.metadata != null) {
        telemetry.addData("ID", detection.id);
        telemetry.addData("Range", "%.1f in", detection.ftcPose.range);
        telemetry.addData("Bearing", "%.1f deg", detection.ftcPose.bearing);
        telemetry.addData("Yaw", "%.1f deg", detection.ftcPose.yaw);
    }
}
```

`metadata` is null for a tag that is not in the tag library. `ftcPose` is only filled in for known tags, so check `metadata` before reading it.

## Pose fields

- **`range`**: straight-line distance from the camera to the tag, in inches.
- **`bearing`**: angle the camera would have to turn to point at the tag, in degrees. Positive means the tag is to the left.
- **`yaw`**: how much the tag is rotated relative to the camera. Zero means you are looking at it straight on.

`range` and `bearing` are enough to drive to a tag.

## Example: drive to a tag

Proportional control on range and bearing. The robot drives until it is 12 inches from tag 3 and pointed at it.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.util.ElapsedTime;
import com.qualcomm.robotcore.util.Range;
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.firstinspires.ftc.vision.VisionPortal;
import org.firstinspires.ftc.vision.apriltag.AprilTagDetection;
import org.firstinspires.ftc.vision.apriltag.AprilTagProcessor;
import java.util.List;

@Autonomous(name = "Drive To AprilTag")
public class DriveToAprilTag extends LinearOpMode {

    static final int TARGET_TAG_ID = 3;
    static final double DESIRED_RANGE = 12.0;
    static final double RANGE_GAIN = 0.02;
    static final double TURN_GAIN = 0.01;
    static final double MAX_DRIVE = 0.4;
    static final double MAX_TURN = 0.3;

    @Override
    public void runOpMode() {
        DcMotor frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        DcMotor frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        DcMotor backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        DcMotor backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        AprilTagProcessor aprilTag = new AprilTagProcessor.Builder().build();
        VisionPortal visionPortal = new VisionPortal.Builder()
            .setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"))
            .addProcessor(aprilTag)
            .build();

        waitForStart();

        ElapsedTime timeout = new ElapsedTime();

        while (opModeIsActive() && timeout.seconds() < 10) {
            AprilTagDetection target = null;

            List<AprilTagDetection> detections = aprilTag.getDetections();
            for (AprilTagDetection d : detections) {
                if (d.metadata != null && d.id == TARGET_TAG_ID) {
                    target = d;
                    break;
                }
            }

            double drive = 0;
            double rotate = 0;

            if (target != null) {
                double rangeError = target.ftcPose.range - DESIRED_RANGE;
                double bearing = target.ftcPose.bearing;

                if (Math.abs(rangeError) < 1.0 && Math.abs(bearing) < 2.0) {
                    break;
                }

                drive = Range.clip(rangeError * RANGE_GAIN, -MAX_DRIVE, MAX_DRIVE);
                rotate = Range.clip(-bearing * TURN_GAIN, -MAX_TURN, MAX_TURN);

                telemetry.addData("Range", "%.1f", target.ftcPose.range);
                telemetry.addData("Bearing", "%.1f", bearing);
            } else {
                telemetry.addLine("Tag not visible");
            }

            frontLeft.setPower(drive + rotate);
            frontRight.setPower(drive - rotate);
            backLeft.setPower(drive + rotate);
            backRight.setPower(drive - rotate);

            telemetry.update();
        }

        frontLeft.setPower(0);
        frontRight.setPower(0);
        backLeft.setPower(0);
        backRight.setPower(0);

        visionPortal.close();
    }
}
```

`rotate` is negated because a positive bearing means the tag is to the left and the robot has to turn counter-clockwise, which is a negative `rx` in the mecanum convention used on this site. If the robot turns away from the tag, flip the sign.

The loop exits when the robot is on target, when the timeout runs out, or when Stop is pressed. If the tag is not visible the robot stops and waits.

## Notes

- Call `visionPortal.close()` when done so the camera is released.
- While the OpMode is in init, the Driver Station menu has a Camera Stream option that shows the camera view. Use it to check that tags are in frame.
- Detection depends on lighting. Test under lighting close to the competition venue.
- Higher camera resolution gives better range at the cost of frame rate. Set it with `.setCameraResolution(new Size(640, 480))` on the portal builder if you need to change it.
- Always check `metadata != null` before reading `ftcPose`. Its the most common null pointer crash in vision code.
