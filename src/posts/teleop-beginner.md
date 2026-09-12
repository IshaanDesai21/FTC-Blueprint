---
title: Teleop Beginner
panelCategory: "TeleOp"
date: 2026-06-02
description: A complete mecanum TeleOp with slow mode.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

Read [Teleop Introduction](/software/teleop-introduction) first. This page starts from the SDK sample `BasicOmniOpMode_Linear` and adds a slow mode.

## Motors

Four motors, named to match the SDK sample and your robot configuration.

```java
frontLeftDrive  = hardwareMap.get(DcMotor.class, "front_left_drive");
backLeftDrive   = hardwareMap.get(DcMotor.class, "back_left_drive");
frontRightDrive = hardwareMap.get(DcMotor.class, "front_right_drive");
backRightDrive  = hardwareMap.get(DcMotor.class, "back_right_drive");

frontLeftDrive.setDirection(DcMotor.Direction.REVERSE);
backLeftDrive.setDirection(DcMotor.Direction.REVERSE);
frontRightDrive.setDirection(DcMotor.Direction.FORWARD);
backRightDrive.setDirection(DcMotor.Direction.FORWARD);
```

The motors on one side face the opposite way from the other side, so one side is reversed. If the robot drives backward when the stick is pushed forward, flip all four.

## Mecanum math

```
frontLeft  = axial + lateral + yaw
frontRight = axial - lateral - yaw
backLeft   = axial - lateral + yaw
backRight  = axial + lateral - yaw
```

- `axial` is forward, from `left_stick_y` negated.
- `lateral` is strafe, from `left_stick_x`.
- `yaw` is rotation, from `right_stick_x`.

See [Mecanum Drivetrain](/software/mecanum-drivetrain) for why the signs are what they are.

## Normalization

Three inputs added together can exceed 1.0, which no motor can do. Take the largest of the four absolute powers and, only if it is over 1.0, divide all four by it. That keeps the ratio between wheels and keeps every value in range.

```java
max = Math.max(Math.abs(frontLeftPower), Math.abs(frontRightPower));
max = Math.max(max, Math.abs(backLeftPower));
max = Math.max(max, Math.abs(backRightPower));

if (max > 1.0) {
    frontLeftPower  /= max;
    frontRightPower /= max;
    backLeftPower   /= max;
    backRightPower  /= max;
}
```

## Slow mode

Hold the left bumper to drive at half speed. Multiply each power by the multiplier after normalizing.

```java
double speed = gamepad1.left_bumper ? 0.5 : 1.0;
```

## Full code

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.util.ElapsedTime;

@TeleOp(name="Mecanum TeleOp", group="Linear OpMode")
public class MecanumTeleOp extends LinearOpMode {

    private ElapsedTime runtime = new ElapsedTime();
    private DcMotor frontLeftDrive = null;
    private DcMotor backLeftDrive = null;
    private DcMotor frontRightDrive = null;
    private DcMotor backRightDrive = null;

    @Override
    public void runOpMode() {

        frontLeftDrive  = hardwareMap.get(DcMotor.class, "front_left_drive");
        backLeftDrive   = hardwareMap.get(DcMotor.class, "back_left_drive");
        frontRightDrive = hardwareMap.get(DcMotor.class, "front_right_drive");
        backRightDrive  = hardwareMap.get(DcMotor.class, "back_right_drive");

        frontLeftDrive.setDirection(DcMotor.Direction.REVERSE);
        backLeftDrive.setDirection(DcMotor.Direction.REVERSE);
        frontRightDrive.setDirection(DcMotor.Direction.FORWARD);
        backRightDrive.setDirection(DcMotor.Direction.FORWARD);

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();
        runtime.reset();

        while (opModeIsActive()) {
            double max;

            double axial   = -gamepad1.left_stick_y;
            double lateral =  gamepad1.left_stick_x;
            double yaw     =  gamepad1.right_stick_x;

            double frontLeftPower  = axial + lateral + yaw;
            double frontRightPower = axial - lateral - yaw;
            double backLeftPower   = axial - lateral + yaw;
            double backRightPower  = axial + lateral - yaw;

            max = Math.max(Math.abs(frontLeftPower), Math.abs(frontRightPower));
            max = Math.max(max, Math.abs(backLeftPower));
            max = Math.max(max, Math.abs(backRightPower));

            if (max > 1.0) {
                frontLeftPower  /= max;
                frontRightPower /= max;
                backLeftPower   /= max;
                backRightPower  /= max;
            }

            // Hold the left bumper for half speed.
            double speed = gamepad1.left_bumper ? 0.5 : 1.0;

            frontLeftDrive.setPower(frontLeftPower * speed);
            frontRightDrive.setPower(frontRightPower * speed);
            backLeftDrive.setPower(backLeftPower * speed);
            backRightDrive.setPower(backRightPower * speed);

            telemetry.addData("Status", "Run Time: " + runtime.toString());
            telemetry.addData("Front left/Right", "%4.2f, %4.2f", frontLeftPower, frontRightPower);
            telemetry.addData("Back  left/Right", "%4.2f, %4.2f", backLeftPower, backRightPower);
            telemetry.addData("Slow mode", gamepad1.left_bumper);
            telemetry.update();
        }
    }
}
```

## Testing

1. In the Driver Station app, open Configure Robot and check the motor names are exactly `front_left_drive`, `front_right_drive`, `back_left_drive`, `back_right_drive`.
2. Select the OpMode and press Init.
3. Press Start and test forward, backward, strafe left, strafe right, and rotation one at a time.
4. If one wheel spins the wrong way, reverse that motors direction in code.

Next, add mechanisms on `gamepad2`, and read [Finite State Machines in TeleOp](/software/teleop-fsm) for mechanisms with more than one step.
