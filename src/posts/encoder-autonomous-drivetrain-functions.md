---
title: Drivetrain Functions
panelCategory: "Encoder Based"
date: 2026-06-10
description: Applying the SDK encoderDrive pattern to a four motor mecanum robot.
tags: [software, auto, intermediate, completed]
author: Blueprint
published: true
---

[Encoder Autonomous Introduction](/software/encoder-autonomous-introduction) covers the SDK sample `RobotAutoDriveByEncoder_Linear`, which drives two motors. This page extends the same `encoderDrive` pattern to four mecanum motors and adds strafe and turn.

Everything here keeps the sample's structure: relative targets, `RUN_TO_POSITION`, a timeout, `Math.abs()` on the speed, and a return to `RUN_USING_ENCODER` afterwards.

## Counts per inch

```java
static final double COUNTS_PER_MOTOR_REV  = 537.7 ;  // goBILDA 5202 312 RPM
static final double DRIVE_GEAR_REDUCTION  = 1.0 ;
static final double WHEEL_DIAMETER_INCHES = 3.78 ;   // 96 mm
static final double COUNTS_PER_INCH       = (COUNTS_PER_MOTOR_REV * DRIVE_GEAR_REDUCTION) /
                                            (WHEEL_DIAMETER_INCHES * 3.1415);
```

Measure it. Command 48 inches, measure what the robot actually travelled, and adjust `WHEEL_DIAMETER_INCHES` until the two agree.

## Brake mode

Set `BRAKE` on all four motors during init so the robot stops instead of coasting past the target.

```java
frontLeftDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
frontRightDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
backLeftDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
backRightDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
```

## One move method

Rather than three near-identical methods, take the tick offset for each wheel. Forward, strafe, and turn only differ in the signs.

```java
public void encoderDrive(double speed,
                         double frontLeftInches, double frontRightInches,
                         double backLeftInches,  double backRightInches,
                         double timeoutS) {

    if (opModeIsActive()) {

        int newFrontLeftTarget  = frontLeftDrive.getCurrentPosition()  + (int)(frontLeftInches  * COUNTS_PER_INCH);
        int newFrontRightTarget = frontRightDrive.getCurrentPosition() + (int)(frontRightInches * COUNTS_PER_INCH);
        int newBackLeftTarget   = backLeftDrive.getCurrentPosition()   + (int)(backLeftInches   * COUNTS_PER_INCH);
        int newBackRightTarget  = backRightDrive.getCurrentPosition()  + (int)(backRightInches  * COUNTS_PER_INCH);

        frontLeftDrive.setTargetPosition(newFrontLeftTarget);
        frontRightDrive.setTargetPosition(newFrontRightTarget);
        backLeftDrive.setTargetPosition(newBackLeftTarget);
        backRightDrive.setTargetPosition(newBackRightTarget);

        setAllRunMode(DcMotor.RunMode.RUN_TO_POSITION);

        runtime.reset();
        setAllPower(Math.abs(speed));

        while (opModeIsActive() &&
               (runtime.seconds() < timeoutS) &&
               (frontLeftDrive.isBusy() && frontRightDrive.isBusy() &&
                backLeftDrive.isBusy()  && backRightDrive.isBusy())) {

            telemetry.addData("Running to", " %7d :%7d :%7d :%7d",
                    newFrontLeftTarget, newFrontRightTarget, newBackLeftTarget, newBackRightTarget);
            telemetry.addData("Currently at", " at %7d :%7d :%7d :%7d",
                    frontLeftDrive.getCurrentPosition(), frontRightDrive.getCurrentPosition(),
                    backLeftDrive.getCurrentPosition(),  backRightDrive.getCurrentPosition());
            telemetry.update();
        }

        setAllPower(0);
        setAllRunMode(DcMotor.RunMode.RUN_USING_ENCODER);

        sleep(250);
    }
}

private void setAllRunMode(DcMotor.RunMode mode) {
    frontLeftDrive.setMode(mode);
    frontRightDrive.setMode(mode);
    backLeftDrive.setMode(mode);
    backRightDrive.setMode(mode);
}

private void setAllPower(double power) {
    frontLeftDrive.setPower(power);
    frontRightDrive.setPower(power);
    backLeftDrive.setPower(power);
    backRightDrive.setPower(power);
}
```

## Forward, strafe, turn

The signs match the mecanum kinematics in [Mecanum Drivetrain](/software/mecanum-drivetrain).

```java
public void driveForward(double inches, double speed, double timeoutS) {
    encoderDrive(speed, inches, inches, inches, inches, timeoutS);
}

public void strafeRight(double inches, double speed, double timeoutS) {
    // Strafing slips sideways, so it covers less ground per tick than driving.
    double corrected = inches * 1.1;
    encoderDrive(speed, corrected, -corrected, -corrected, corrected, timeoutS);
}

public void turnRight(double inches, double speed, double timeoutS) {
    encoderDrive(speed, inches, -inches, inches, -inches, timeoutS);
}
```

Negative inches drives backward, strafes left, or turns left.

## Accuracy

Forward moves are the most accurate. Strafing is worse, because the rollers slip sideways under load, which is what the 1.1 factor compensates for. Measure that factor seperately from the forward one, and re-check it on the competition floor.

Turning by encoder counts is the least accurate, since the wheels scrub through the turn and the amount depends on how the robot is loaded. For turns that matter, drive the turn from the IMU heading instead. The SDK sample for that is `RobotAutoDriveByGyro_Linear`, and the [IMU guide](/software/sensors-imu) covers reading the heading.

## Running a routine

```java
waitForStart();

driveForward(24, DRIVE_SPEED, 5.0);
strafeRight(12, DRIVE_SPEED, 4.0);
turnRight(9, TURN_SPEED, 4.0);
driveForward(12, DRIVE_SPEED, 4.0);
```

Every move blocks until it finishes, so the robot cannot run a mechanism during a drive with this pattern. [Subsystem Functions](/software/encoder-autonomous-subsystem-functions) uses the same approach for arms and slides.
