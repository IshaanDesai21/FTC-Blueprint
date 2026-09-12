---
title: Drivetrain Functions
panelCategory: "Encoder Based"
date: 2026-06-10
description: Reusable driveForward, strafeRight, and turnRight methods using encoders.
tags: [software, auto, intermediate, completed]
author: Blueprint
published: true
---

Setting four target positions, four modes, and four powers for every move gets long. Wrap it in methods so the autonomous reads as a list of moves.

## Brake mode

Set `BRAKE` on all drive motors during init so the robot stops instead of coasting past the target.

```java
frontLeft.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
frontRight.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
backLeft.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
backRight.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
```

## Ticks per inch

Ticks per inch depends on encoder resolution, gear ratio, and wheel diameter. A 312 RPM goBILDA motor on a 96 mm wheel is about 45. Measure it:

1. Mark the start position.
2. Command 48 inches with the current constant.
3. Measure the actual distance.
4. New constant = `(48 / actual) * old constant`.
5. Repeat until it is within half an inch.

```java
static final double TICKS_PER_INCH = 45.0;
```

## Helpers

```java
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
```

## driveForward

All four motors move the same direction. Negative inches drives backward.

```java
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
```

Targets are `getCurrentPosition() + ticks`, so each move is relative to where the motor is now. The counts keep accumulating across moves and that is fine.

## strafeRight

Front left and back right drive forward, front right and back left drive backward.

Strafing is less accurate than driving. The rollers slip sideways, so the same ticks cover a shorter distance. The `1.1` factor compensates for that. Measure it seperately from the forward constant.

```java
public void strafeRight(double inches, double power) {
    int ticks = (int) (inches * TICKS_PER_INCH * 1.1);

    frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + ticks);
    frontRight.setTargetPosition(frontRight.getCurrentPosition() - ticks);
    backLeft.setTargetPosition(backLeft.getCurrentPosition() - ticks);
    backRight.setTargetPosition(backRight.getCurrentPosition() + ticks);

    setAllRunMode(DcMotor.RunMode.RUN_TO_POSITION);
    setAllPower(power);

    while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
        telemetry.addData("Strafing", "%.1f in", inches);
        telemetry.update();
    }

    setAllPower(0);
    setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);
}
```

Negative inches strafes left.

## turnRight

Left side forward, right side backward. Ticks per degree depends on the track width and the wheels, so measure it: command 90 degrees, measure the actual angle, and scale.

Encoder turns drift because the wheels scrub during a turn. For turns that matter, use the [IMU](/software/sensors-imu) heading instead and turn until the measured angle reaches the target.

```java
static final double TICKS_PER_DEGREE = 5.7;

public void turnRight(double degrees, double power) {
    int ticks = (int) (degrees * TICKS_PER_DEGREE);

    frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + ticks);
    frontRight.setTargetPosition(frontRight.getCurrentPosition() - ticks);
    backLeft.setTargetPosition(backLeft.getCurrentPosition() + ticks);
    backRight.setTargetPosition(backRight.getCurrentPosition() - ticks);

    setAllRunMode(DcMotor.RunMode.RUN_TO_POSITION);
    setAllPower(power);

    while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
        telemetry.addData("Turning", "%.1f deg", degrees);
        telemetry.update();
    }

    setAllPower(0);
    setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);
}
```

## Full OpMode

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;

@Autonomous(name = "Encoder Drivetrain Auto")
public class EncoderDrivetrainAuto extends LinearOpMode {

    DcMotor frontLeft, frontRight, backLeft, backRight;

    static final double TICKS_PER_INCH   = 45.0;
    static final double TICKS_PER_DEGREE = 5.7;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        frontLeft.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        frontRight.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        backLeft.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
        backRight.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        setAllRunMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);

        waitForStart();

        driveForward(24, 0.5);
        strafeRight(12, 0.4);
        turnRight(90, 0.4);
        driveForward(12, 0.5);
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

    public void strafeRight(double inches, double power) {
        int ticks = (int) (inches * TICKS_PER_INCH * 1.1);

        frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + ticks);
        frontRight.setTargetPosition(frontRight.getCurrentPosition() - ticks);
        backLeft.setTargetPosition(backLeft.getCurrentPosition() - ticks);
        backRight.setTargetPosition(backRight.getCurrentPosition() + ticks);

        setAllRunMode(DcMotor.RunMode.RUN_TO_POSITION);
        setAllPower(power);

        while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
            telemetry.addData("Strafing", "%.1f in", inches);
            telemetry.update();
        }

        setAllPower(0);
        setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);
    }

    public void turnRight(double degrees, double power) {
        int ticks = (int) (degrees * TICKS_PER_DEGREE);

        frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + ticks);
        frontRight.setTargetPosition(frontRight.getCurrentPosition() - ticks);
        backLeft.setTargetPosition(backLeft.getCurrentPosition() + ticks);
        backRight.setTargetPosition(backRight.getCurrentPosition() - ticks);

        setAllRunMode(DcMotor.RunMode.RUN_TO_POSITION);
        setAllPower(power);

        while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
            telemetry.addData("Turning", "%.1f deg", degrees);
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
}
```

## Notes

- Measure `TICKS_PER_INCH` and `TICKS_PER_DEGREE` on the real robot. The values above are placeholders.
- Use relative targets so moves chain correctly.
- Strafe distance changes with floor surface. Re-check it on the competition field.
- These moves block until done. The robot cannot run a mechanism at the same time as a drive move with this pattern.
