---
title: Encoder Autonomous Introduction
panelCategory: "Encoder Based"
date: 2026-06-08
description: Motor encoders, run modes, and the SDK encoder autonomous sample.
tags: [software, auto, beginner, completed]
author: Blueprint
published: true
---

The autonomous period is the first 30 seconds of a match. The robot runs on its own. Encoders let you move a known distance instead of running motors for a fixed time.

The SDK ships this as `RobotAutoDriveByEncoder_Linear`. The code on this page is that sample.

## Encoders

An encoder counts how far the motor shaft has turned. The count is in ticks. Ticks per revolution depends on the motor:

- goBILDA Yellow Jacket 312 RPM: 537.7 ticks per revolution
- goBILDA Yellow Jacket 435 RPM: 383.6 ticks per revolution
- TETRIX with the standard encoder: 1440 ticks per revolution

Check the vendor page for other motors. The encoder cable has to be plugged in to the encoder port that matchs the motor port.

## Why not time

Running a motor at 0.5 power for one second covers a different distance depending on battery voltage, the floor, and how much the robot weighs. An encoder target covers the same distance every time.

## Run modes

Every motor has a `RunMode`.

- **`RUN_WITHOUT_ENCODER`**: raw power. Typical for TeleOp driving.
- **`RUN_USING_ENCODER`**: the hub uses the encoder to hold a velocity. Power values become velocity targets. Use this between autonomous moves.
- **`STOP_AND_RESET_ENCODER`**: sets the count to zero. Set this once at init.
- **`RUN_TO_POSITION`**: the hub drives the motor to a target tick count and holds it. This is what encoder autonomous uses.

## Counts per inch

The SDK computes this from the motor and wheel rather than hardcoding it.

```java
static final double COUNTS_PER_MOTOR_REV  = 1440 ;   // check your motor vendor's page
static final double DRIVE_GEAR_REDUCTION  = 1.0 ;    // 2.0 for a 12 tooth gear driving a 24 tooth gear
static final double WHEEL_DIAMETER_INCHES = 4.0 ;
static final double COUNTS_PER_INCH       = (COUNTS_PER_MOTOR_REV * DRIVE_GEAR_REDUCTION) /
                                            (WHEEL_DIAMETER_INCHES * 3.1415);
```

Then measure. Command 48 inches, measure the actual distance, and scale `WHEEL_DIAMETER_INCHES` by `actual / 48` until it lands.

## The sample

```java
@Autonomous(name="Robot: Auto Drive By Encoder", group="Robot")
public class RobotAutoDriveByEncoder_Linear extends LinearOpMode {

    private DcMotor leftDrive  = null;
    private DcMotor rightDrive = null;
    private ElapsedTime runtime = new ElapsedTime();

    static final double COUNTS_PER_MOTOR_REV  = 1440 ;
    static final double DRIVE_GEAR_REDUCTION  = 1.0 ;
    static final double WHEEL_DIAMETER_INCHES = 4.0 ;
    static final double COUNTS_PER_INCH       = (COUNTS_PER_MOTOR_REV * DRIVE_GEAR_REDUCTION) /
                                                (WHEEL_DIAMETER_INCHES * 3.1415);
    static final double DRIVE_SPEED = 0.6;
    static final double TURN_SPEED  = 0.5;

    @Override
    public void runOpMode() {

        leftDrive  = hardwareMap.get(DcMotor.class, "left_drive");
        rightDrive = hardwareMap.get(DcMotor.class, "right_drive");

        leftDrive.setDirection(DcMotor.Direction.REVERSE);
        rightDrive.setDirection(DcMotor.Direction.FORWARD);

        leftDrive.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        rightDrive.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);

        leftDrive.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        rightDrive.setMode(DcMotor.RunMode.RUN_USING_ENCODER);

        telemetry.addData("Starting at",  "%7d :%7d",
                          leftDrive.getCurrentPosition(),
                          rightDrive.getCurrentPosition());
        telemetry.update();

        waitForStart();

        // A negative distance drives backward. The last value is a timeout in seconds.
        encoderDrive(DRIVE_SPEED,  48,  48, 5.0);
        encoderDrive(TURN_SPEED,   12, -12, 4.0);
        encoderDrive(DRIVE_SPEED, -24, -24, 4.0);

        telemetry.addData("Path", "Complete");
        telemetry.update();
        sleep(1000);
    }

    public void encoderDrive(double speed,
                             double leftInches, double rightInches,
                             double timeoutS) {
        int newLeftTarget;
        int newRightTarget;

        if (opModeIsActive()) {

            // Targets are relative to where the motors are now.
            newLeftTarget  = leftDrive.getCurrentPosition()  + (int)(leftInches * COUNTS_PER_INCH);
            newRightTarget = rightDrive.getCurrentPosition() + (int)(rightInches * COUNTS_PER_INCH);
            leftDrive.setTargetPosition(newLeftTarget);
            rightDrive.setTargetPosition(newRightTarget);

            leftDrive.setMode(DcMotor.RunMode.RUN_TO_POSITION);
            rightDrive.setMode(DcMotor.RunMode.RUN_TO_POSITION);

            runtime.reset();
            leftDrive.setPower(Math.abs(speed));
            rightDrive.setPower(Math.abs(speed));

            // Stops when the target is reached, the timeout expires, or the OpMode ends.
            while (opModeIsActive() &&
                   (runtime.seconds() < timeoutS) &&
                   (leftDrive.isBusy() && rightDrive.isBusy())) {

                telemetry.addData("Running to",  " %7d :%7d", newLeftTarget,  newRightTarget);
                telemetry.addData("Currently at",  " at %7d :%7d",
                                            leftDrive.getCurrentPosition(), rightDrive.getCurrentPosition());
                telemetry.update();
            }

            leftDrive.setPower(0);
            rightDrive.setPower(0);

            leftDrive.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
            rightDrive.setMode(DcMotor.RunMode.RUN_USING_ENCODER);

            sleep(250);
        }
    }
}
```

## Things worth noting

- `setTargetPosition()` is called before switching to `RUN_TO_POSITION`. The other order throws an exception.
- Speed is passed through `Math.abs()`. Direction comes from the target, not the sign of the power.
- The wait loop checks three things: the OpMode is still active, the timeout has not expired, and both motors are still busy. Without the timeout a stalled motor holds up the rest of the routine.
- Using `&&` between the two `isBusy()` calls means the move ends as soon as either motor arrives. Use `||` if both must finish.
- Targets are relative to the current position, so moves chain without resetting encoders between them.

## Next

[Drivetrain Functions](/software/encoder-autonomous-drivetrain-functions) applies the same pattern to a four motor mecanum robot. [Subsystem Functions](/software/encoder-autonomous-subsystem-functions) does it for arms, slides, and claws.
