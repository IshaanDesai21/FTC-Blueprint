---
title: Encoder Autonomous Introduction
panelCategory: "Encoder Based"
date: 2026-06-08
description: Motor encoders, run modes, and a first encoder-based autonomous.
tags: [software, auto, beginner, completed]
author: Blueprint
published: true
---

The autonomous period is the first 30 seconds of a match. The robot runs on its own. Encoders let you move a known distance instead of running motors for a fixed time.

## Encoders

An encoder counts how far the motor shaft has turned. The count is in ticks. Ticks per revolution depends on the motor:

- goBILDA Yellow Jacket 312 RPM: 537.7 ticks per revolution
- goBILDA Yellow Jacket 435 RPM: 383.6 ticks per revolution

Check the product page for other motors. The encoder cable has to be plugged in to the encoder port that matchs the motor port.

## Why not time

Running a motor at 0.5 power for one second covers a different distance depending on battery voltage, the floor, and how much the robot weighs. An encoder target covers the same distance every time.

## Run modes

Every motor has a `RunMode`.

- **`RUN_WITHOUT_ENCODER`**: raw power. Typical for TeleOp driving.
- **`RUN_USING_ENCODER`**: the hub uses the encoder to hold a velocity. Power values become velocity targets. Use this between autonomous moves.
- **`STOP_AND_RESET_ENCODER`**: sets the count to zero. Set this once at init.
- **`RUN_TO_POSITION`**: the hub drives the motor to a target tick count and holds it. This is what encoder autonomous uses.

## Reset at init

Encoder counts carry over from whatever ran last. Reset every drive motor before using positions, then switch to `RUN_USING_ENCODER`.

```java
frontLeft.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
frontRight.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
backLeft.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
backRight.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);

frontLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
frontRight.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
backLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
backRight.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
```

## Example: drive forward

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.Autonomous;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;

@Autonomous(name = "Encoder Intro Example")
public class EncoderIntroExample extends LinearOpMode {

    DcMotor frontLeft, frontRight, backLeft, backRight;

    // 312 RPM motor, 96 mm wheel. Measure this for your robot.
    static final double TICKS_PER_INCH = 45.0;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        frontLeft.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        frontRight.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        backLeft.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        backRight.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);

        frontLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        frontRight.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        backLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        backRight.setMode(DcMotor.RunMode.RUN_USING_ENCODER);

        waitForStart();

        int ticks = (int) (24 * TICKS_PER_INCH);

        frontLeft.setTargetPosition(ticks);
        frontRight.setTargetPosition(ticks);
        backLeft.setTargetPosition(ticks);
        backRight.setTargetPosition(ticks);

        frontLeft.setMode(DcMotor.RunMode.RUN_TO_POSITION);
        frontRight.setMode(DcMotor.RunMode.RUN_TO_POSITION);
        backLeft.setMode(DcMotor.RunMode.RUN_TO_POSITION);
        backRight.setMode(DcMotor.RunMode.RUN_TO_POSITION);

        frontLeft.setPower(0.5);
        frontRight.setPower(0.5);
        backLeft.setPower(0.5);
        backRight.setPower(0.5);

        while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
            telemetry.addData("Front Left", frontLeft.getCurrentPosition());
            telemetry.addData("Front Right", frontRight.getCurrentPosition());
            telemetry.update();
        }

        frontLeft.setPower(0);
        frontRight.setPower(0);
        backLeft.setPower(0);
        backRight.setPower(0);
    }
}
```

`setTargetPosition()` has to be called before switching to `RUN_TO_POSITION`, or the SDK throws an exception. The wait loop checks `opModeIsActive()` as well as `isBusy()` so the OpMode exits cleanly when Stop is pressed.

## Ticks per inch

```
ticks per inch = ticks per revolution / (wheel diameter in inches * pi)
```

For a 537.7 tick motor on a 96 mm (3.78 in) wheel that is 537.7 / 11.87 = 45.3. Then measure. Command 48 inches, measure the actual distance, and scale the constant by `48 / actual`.

## Next

[Drivetrain Functions](/software/encoder-autonomous-drivetrain-functions) wraps this in `driveForward`, `strafeRight`, and `turnRight` methods. [Subsystem Functions](/software/encoder-autonomous-subsystem-functions) does the same for arms, slides, and claws.
