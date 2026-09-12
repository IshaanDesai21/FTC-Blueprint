---
title: Subsystem Functions
panelCategory: "Encoder Based"
date: 2026-06-12
description: Arm, slide, and claw methods for autonomous with encoders and servos.
tags: [software, auto, intermediate, completed]
author: Blueprint
published: true
---

Arms, slides, and claws in autonomous use the same pattern as the drivetrain: set a target, wait until the mechanism gets there, move on.

## Motor mechanisms

`RUN_TO_POSITION` works the same on an arm or slide motor as on a drive motor. Add a timeout. If the mechanism is blocked, `isBusy()` can stay true and the autonomous would wait on it for the rest of the period.

```java
public void moveArmToPosition(int targetTicks, double power) {
    armMotor.setTargetPosition(targetTicks);
    armMotor.setMode(DcMotor.RunMode.RUN_TO_POSITION);
    armMotor.setPower(Math.abs(power));

    ElapsedTime timeout = new ElapsedTime();
    while (opModeIsActive() && armMotor.isBusy() && timeout.seconds() < 3.0) {
        telemetry.addData("Arm target", targetTicks);
        telemetry.addData("Arm position", armMotor.getCurrentPosition());
        telemetry.update();
    }

    armMotor.setPower(0);
}
```

`Math.abs(power)` because `RUN_TO_POSITION` picks the direction from the target. A negative power here does not reverse it. Set the timeout a little longer than the slowest move you expect.

## Position constants

```java
static final int ARM_HOME       = 0;
static final int ARM_PICKUP     = 150;
static final int ARM_SCORE_LOW  = 600;
static final int ARM_SCORE_HIGH = 1100;
```

```java
moveArmToPosition(ARM_SCORE_HIGH, 0.7);
openClaw();
moveArmToPosition(ARM_HOME, 0.5);
```

Find the numbers by moving the arm by hand with the encoder reading on telemetry and writing them down as you go along.

## Servos

A servo has no feedback, so the code does not know when it has arrived. Sleep long enough for the move to finish before the next step.

```java
static final double CLAW_OPEN   = 0.8;
static final double CLAW_CLOSED = 0.2;

public void openClaw() {
    clawServo.setPosition(CLAW_OPEN);
    sleep(500);
}

public void closeClaw() {
    clawServo.setPosition(CLAW_CLOSED);
    sleep(500);
}
```

500 ms is a starting point. Watch the claw and shorten or lengthen it.

## Slides

Same as the arm. For a vertical slide, leave a small power on after the move so it does not drop.

```java
static final int SLIDE_DOWN = 0;
static final int SLIDE_LOW  = 400;
static final int SLIDE_HIGH = 1200;

public void setSlideHeight(int targetTicks, double power) {
    slideMotor.setTargetPosition(targetTicks);
    slideMotor.setMode(DcMotor.RunMode.RUN_TO_POSITION);
    slideMotor.setPower(Math.abs(power));

    ElapsedTime timeout = new ElapsedTime();
    while (opModeIsActive() && slideMotor.isBusy() && timeout.seconds() < 4.0) {
        telemetry.addData("Slide target", targetTicks);
        telemetry.addData("Slide position", slideMotor.getCurrentPosition());
        telemetry.update();
    }

    slideMotor.setPower(0.05);
}
```

The motor stays in `RUN_TO_POSITION`, so the 0.05 is the maximum power it will use to hold the target. Raise it if the slide still sag.

## Full OpMode

Drives to a scoring position, raises the slide, moves the arm, opens the claw, returns home, backs away.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.Servo;
import com.qualcomm.robotcore.util.ElapsedTime;

@Autonomous(name = "Full Auto With Subsystems")
public class FullAutoWithSubsystems extends LinearOpMode {

    DcMotor frontLeft, frontRight, backLeft, backRight;
    DcMotor armMotor, slideMotor;
    Servo   clawServo;

    static final double TICKS_PER_INCH = 45.0;

    static final int ARM_HOME   = 0;
    static final int ARM_SCORE  = 700;
    static final int SLIDE_DOWN = 0;
    static final int SLIDE_HIGH = 1200;
    static final double CLAW_OPEN   = 0.8;
    static final double CLAW_CLOSED = 0.2;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "front_left_drive");
        frontRight = hardwareMap.get(DcMotor.class, "front_right_drive");
        backLeft   = hardwareMap.get(DcMotor.class, "back_left_drive");
        backRight  = hardwareMap.get(DcMotor.class, "back_right_drive");

        armMotor   = hardwareMap.get(DcMotor.class, "arm_motor");
        slideMotor = hardwareMap.get(DcMotor.class, "slide_motor");
        clawServo  = hardwareMap.get(Servo.class, "claw_servo");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        frontLeft.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        frontRight.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        backLeft.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        backRight.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        setAllRunMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        armMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        slideMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);

        setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);
        armMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        slideMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);

        clawServo.setPosition(CLAW_CLOSED);

        waitForStart();

        driveForward(36, 0.5);
        setSlideHeight(SLIDE_HIGH, 0.8);
        moveArmToPosition(ARM_SCORE, 0.6);
        openClaw();
        moveArmToPosition(ARM_HOME, 0.5);
        setSlideHeight(SLIDE_DOWN, 0.6);
        driveForward(-12, 0.4);
    }

    public void driveForward(double inches, double power) {
        int ticks = (int) (inches * TICKS_PER_INCH);

        frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + ticks);
        frontRight.setTargetPosition(frontRight.getCurrentPosition() + ticks);
        backLeft.setTargetPosition(backLeft.getCurrentPosition() + ticks);
        backRight.setTargetPosition(backRight.getCurrentPosition() + ticks);

        setAllRunMode(DcMotor.RunMode.RUN_TO_POSITION);
        setAllPower(power);

        while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
            telemetry.addData("Driving", "%.1f in", inches);
            telemetry.update();
        }

        setAllPower(0);
        setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);
    }

    private void setAllRunMode(DcMotor.RunMode mode) {
        frontLeft.setMode(mode);
        frontRight.setMode(mode);
        backLeft.setMode(mode);
        backRight.setMode(mode);
    }

    private void setAllPower(double power) {
        frontLeft.setPower(power);
        frontRight.setPower(power);
        backLeft.setPower(power);
        backRight.setPower(power);
    }

    public void moveArmToPosition(int targetTicks, double power) {
        armMotor.setTargetPosition(targetTicks);
        armMotor.setMode(DcMotor.RunMode.RUN_TO_POSITION);
        armMotor.setPower(Math.abs(power));

        ElapsedTime timeout = new ElapsedTime();
        while (opModeIsActive() && armMotor.isBusy() && timeout.seconds() < 3.0) {
            telemetry.addData("Arm target", targetTicks);
            telemetry.addData("Arm position", armMotor.getCurrentPosition());
            telemetry.update();
        }

        armMotor.setPower(0);
    }

    public void setSlideHeight(int targetTicks, double power) {
        slideMotor.setTargetPosition(targetTicks);
        slideMotor.setMode(DcMotor.RunMode.RUN_TO_POSITION);
        slideMotor.setPower(Math.abs(power));

        ElapsedTime timeout = new ElapsedTime();
        while (opModeIsActive() && slideMotor.isBusy() && timeout.seconds() < 4.0) {
            telemetry.addData("Slide target", targetTicks);
            telemetry.addData("Slide position", slideMotor.getCurrentPosition());
            telemetry.update();
        }

        slideMotor.setPower(0.05);
    }

    public void openClaw() {
        clawServo.setPosition(CLAW_OPEN);
        sleep(500);
    }

    public void closeClaw() {
        clawServo.setPosition(CLAW_CLOSED);
        sleep(500);
    }
}
```

## Notes

- Always put a timeout on a `RUN_TO_POSITION` wait.
- Reset mechanism encoders at init with the mechanism physically at its home position. If the arm starts halfway up, zero is halfway up.
- Test each method alone in a small OpMode before chaining them.
- The arm is left at zero power after its move. If it drops, hold it the same way as the slide.
