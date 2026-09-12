---
title: AprilTag Detection
panelCategory: "Vision"
date: 2026-04-14
description: Detecting AprilTags with VisionPortal and driving to one.
tags: [software, beginner, completed]
author: Blueprint
published: true
---

AprilTags are square black and white markers placed on the field. The SDK detects them from a webcam and reports the distance and angle from the camera to each tag. Every tag has an ID, and the field tag positions are listed in the game manual.

The samples are `ConceptAprilTag` for reading tags and `RobotAutoDriveToAprilTagOmni` for driving to one. The code here is from the second.

## Requirements

- A USB webcam plugged into the Control Hub, named `Webcam 1` in the robot configuration.
- An SDK version with `VisionPortal` and `AprilTagProcessor`.

## Setting up the processor

```java
private void initAprilTag() {
    aprilTag = new AprilTagProcessor.Builder().build();

    // Decimation trades detection range against frame rate.
    // 1 detects a 2 inch tag from 10 feet at 10 fps.
    // 2 detects a 2 inch tag from 6 feet at 22 fps.
    // 3 detects a 2 inch tag from 4 feet at 30 fps.
    aprilTag.setDecimation(2);

    visionPortal = new VisionPortal.Builder()
            .setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"))
            .addProcessor(aprilTag)
            .build();
}
```

Decimation can be changed mid-match. Lower it when you need range, raise it when you need frame rate.

The sample also sets a short manual exposure, around 6 ms at gain 250, to cut motion blur while the robot is moving. Tags are much harder to detect from a moving robot on the default auto exposure.

## Reading detections

```java
List<AprilTagDetection> currentDetections = aprilTag.getDetections();
for (AprilTagDetection detection : currentDetections) {
    if (detection.metadata != null) {
        if ((DESIRED_TAG_ID < 0) || (detection.id == DESIRED_TAG_ID)) {
            targetFound = true;
            desiredTag = detection;
            break;
        }
    } else {
        // Not in the tag library, so there is no size information and no pose.
        telemetry.addData("Unknown", "Tag ID %d is not in TagLibrary", detection.id);
    }
}
```

`metadata` is null for a tag that is not in the library. `ftcPose` is only filled in for known tags, so check `metadata` before reading it. Setting the desired ID to -1 accepts any tag.

## Pose fields

- **`range`**: straight-line distance from the camera to the tag, in inches.
- **`bearing`**: angle the camera would turn to point at the tag, in degrees.
- **`yaw`**: how much the tag is rotated relative to the camera, which tells you how far off to the side of the tag you are.

The driving sample uses all three: range to set forward speed, bearing to turn, and yaw to strafe.

## Driving to a tag

```java
final double DESIRED_DISTANCE = 12.0;

// Drive = Error * Gain. Smaller gains are smoother, larger are more aggressive.
final double SPEED_GAIN  =  0.02  ;
final double STRAFE_GAIN =  0.015 ;
final double TURN_GAIN   =  0.01  ;

final double MAX_AUTO_SPEED = 0.5;
final double MAX_AUTO_STRAFE= 0.5;
final double MAX_AUTO_TURN  = 0.3;
```

```java
if (gamepad1.left_bumper && targetFound) {

    double rangeError   = (desiredTag.ftcPose.range - DESIRED_DISTANCE);
    double headingError = desiredTag.ftcPose.bearing;
    double yawError     = desiredTag.ftcPose.yaw;

    drive  = Range.clip(rangeError * SPEED_GAIN, -MAX_AUTO_SPEED, MAX_AUTO_SPEED);
    turn   = Range.clip(headingError * TURN_GAIN, -MAX_AUTO_TURN, MAX_AUTO_TURN) ;
    strafe = Range.clip(-yawError * STRAFE_GAIN, -MAX_AUTO_STRAFE, MAX_AUTO_STRAFE);

} else {

    // Manual driving, slowed down to stay controllable.
    drive  = -gamepad1.left_stick_y  / 2.0;
    strafe = -gamepad1.left_stick_x  / 2.0;
    turn   = -gamepad1.right_stick_x / 3.0;
}

moveRobot(drive, strafe, turn);
sleep(10);
```

Each output is the error multiplied by a gain and then clipped. That is proportional control. Bigger error means more power, and the clip stops the robot lunging when a tag first appears far away.

Holding the bumper for automatic approach, rather than running it unconditionally, means the driver can line the robot up manually first and stays in control.

## Moving the robot

```java
public void moveRobot(double x, double y, double yaw) {
    double frontLeftPower    =  x - y - yaw;
    double frontRightPower   =  x + y + yaw;
    double backLeftPower     =  x + y - yaw;
    double backRightPower    =  x - y + yaw;

    double max = Math.max(Math.abs(frontLeftPower), Math.abs(frontRightPower));
    max = Math.max(max, Math.abs(backLeftPower));
    max = Math.max(max, Math.abs(backRightPower));

    if (max > 1.0) {
        frontLeftPower /= max;
        frontRightPower /= max;
        backLeftPower /= max;
        backRightPower /= max;
    }

    frontLeftDrive.setPower(frontLeftPower);
    frontRightDrive.setPower(frontRightPower);
    backLeftDrive.setPower(backLeftPower);
    backRightDrive.setPower(backRightPower);
}
```

In this method positive x is forward, positive y is strafe left, and positive yaw is counter-clockwise. Those signs differ from `BasicOmniOpMode_Linear`, so do not mix the two formulas in one file.

## Notes

- During init the Driver Station menu has a Camera Stream option. Use it to check tags are in frame.
- Detection depends on lighting. Test under lighting close to the competition venue.
- Always check `metadata != null` before reading `ftcPose`. Its the most common null pointer crash in vision code.
