---
title: Mecanum Drivetrain
panelCategory: 'Miscellaneous'
date: 2026-04-28
description: The kinematics and code for a four motor mecanum drivetrain.
tags: [completed, software, beginner, kinematics]
author: Blueprint
published: true
---

Mecanum wheels have rollers mounted at 45 degrees around the rim. Spinning the four wheels in different combinations moves the robot forward, sideways, or in rotation without turning the wheels.

## Kinematics

Three inputs: forward `y`, strafe `x`, and rotation `rx`. Each wheel's power is a sum of the three with different signs.

- Front left = `y + x + rx`
- Front right = `y - x - rx`
- Back left = `y - x + rx`
- Back right = `y + x - rx`

When strafing right, the front left and back right wheels drive forward while the front right and back left drive backward. The roller angles turn that into sideways motion.

## Code

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Mecanum Drive")
public class MecanumDrive extends LinearOpMode {
    @Override
    public void runOpMode() {
        DcMotor frontLeft = hardwareMap.get(DcMotor.class, "frontLeft");
        DcMotor frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        DcMotor backLeft = hardwareMap.get(DcMotor.class, "backLeft");
        DcMotor backRight = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        waitForStart();

        while (opModeIsActive()) {
            double y = -gamepad1.left_stick_y;
            double x = gamepad1.left_stick_x * 1.1;
            double rx = gamepad1.right_stick_x;

            double denominator = Math.max(Math.abs(y) + Math.abs(x) + Math.abs(rx), 1);
            double frontLeftPower = (y + x + rx) / denominator;
            double backLeftPower = (y - x + rx) / denominator;
            double frontRightPower = (y - x - rx) / denominator;
            double backRightPower = (y + x - rx) / denominator;

            frontLeft.setPower(frontLeftPower);
            backLeft.setPower(backLeftPower);
            frontRight.setPower(frontRightPower);
            backRight.setPower(backRightPower);
        }
    }
}
```

**Denominator.** If the three inputs add to more than 1.0, a motor would be asked for more than full power. Dividing all four by the largest sum keeps the ratios between wheels the same and keeps every power in range.

**1.1 on strafe.** Mecanum robots strafe slower than they drive forward. Multiplying the strafe input by a small constant compensates. Tune it for your robot.

**Reversed left side.** Which side needs reversing depends on how the motors are mounted. If the robot drives backward when you push forward, flip which side is reversed.

## Notes

- Weight has to be spread across all four wheels. A light corner loses traction and the robot drifts while strafing.
- The wheels must be mounted so the rollers form an X when viewed from above. If the robot rotates instead of strafing, one or more wheel is in the wrong position.
- Field-centric drive rotates `x` and `y` by the IMU heading before the math above, so the robot moves relative to the field instead of its own front. See [Teleop Beginner](/software/teleop-beginner).
