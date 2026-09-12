---
title: Teleop Beginner
panelCategory: "TeleOp"
date: 2026-06-02
description: A complete mecanum TeleOp with slow mode.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

Read [Teleop Introduction](/software/teleop-introduction) first. This page builds a working mecanum drive TeleOp.

## Motors

Four motors: front left, front right, back left, back right.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Mecanum TeleOp")
public class MecanumTeleOp extends LinearOpMode {

    DcMotor frontLeft, frontRight, backLeft, backRight;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        waitForStart();

        while (opModeIsActive()) {
            // driving code
        }
    }
}
```

The motors on one side face the opposite way from the other side, so one side is reversed. If the robot drives backward when the stick is pushed forward, reverse the other side instead.

## Mecanum math

```
frontLeft  = y + x + rx
frontRight = y - x - rx
backLeft   = y - x + rx
backRight  = y + x - rx
```

- `y` is forward, from `left_stick_y` negated.
- `x` is strafe, from `left_stick_x`.
- `rx` is rotation, from `right_stick_x`.

```java
double y  = -gamepad1.left_stick_y;
double x  =  gamepad1.left_stick_x;
double rx =  gamepad1.right_stick_x;
```

See [Mecanum Drivetrain](/software/mecanum-drivetrain) for why the signs are what they are.

## Normalization

When the three inputs add to more than 1.0 the motor powers go out of range. The SDK clamps them, but clamping breaks the ratio between wheels and the robot does not go where the stick points. Divide all four by the largest sum when it is over 1.

```java
double denominator = Math.max(Math.abs(y) + Math.abs(x) + Math.abs(rx), 1);

double frontLeftPower  = (y + x + rx) / denominator;
double frontRightPower = (y - x - rx) / denominator;
double backLeftPower   = (y - x + rx) / denominator;
double backRightPower  = (y + x - rx) / denominator;
```

`Math.max(..., 1)` means the division does nothing when the sum is already 1 or less.

## Slow mode

Hold the left bumper to drive at half speed.

```java
double speedMultiplier = gamepad1.left_bumper ? 0.5 : 1.0;
```

Multiply each motor power by it.

## Full code

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Mecanum TeleOp")
public class MecanumTeleOp extends LinearOpMode {

    DcMotor frontLeft, frontRight, backLeft, backRight;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        waitForStart();

        while (opModeIsActive()) {
            double y  = -gamepad1.left_stick_y;
            double x  =  gamepad1.left_stick_x;
            double rx =  gamepad1.right_stick_x;

            double speedMultiplier = gamepad1.left_bumper ? 0.5 : 1.0;

            double denominator = Math.max(Math.abs(y) + Math.abs(x) + Math.abs(rx), 1);

            double frontLeftPower  = ((y + x + rx) / denominator) * speedMultiplier;
            double frontRightPower = ((y - x - rx) / denominator) * speedMultiplier;
            double backLeftPower   = ((y - x + rx) / denominator) * speedMultiplier;
            double backRightPower  = ((y + x - rx) / denominator) * speedMultiplier;

            frontLeft.setPower(frontLeftPower);
            frontRight.setPower(frontRightPower);
            backLeft.setPower(backLeftPower);
            backRight.setPower(backRightPower);

            telemetry.addData("FL | FR", "%.2f | %.2f", frontLeftPower, frontRightPower);
            telemetry.addData("BL | BR", "%.2f | %.2f", backLeftPower, backRightPower);
            telemetry.addData("Slow Mode", gamepad1.left_bumper);
            telemetry.update();
        }
    }
}
```

## Testing

1. In the Driver Station app, open Configure Robot and check the motor names are exactly `frontLeft`, `frontRight`, `backLeft`, `backRight`.
2. Select the OpMode and press Init.
3. Press Start and test forward, backward, strafe left, strafe right, and rotation one at a time.
4. If one wheel spins the wrong way, reverse that motors direction in code.

Next, add mechanisms on `gamepad2`, and read [Finite State Machines in TeleOp](/software/teleop-fsm) for mechanisms with more than one step.
