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

The SDK ships this as `BasicOmniOpMode_Linear`. The code below is that sample.

## Kinematics

Three inputs. The SDK calls them axial (forward), lateral (strafe), and yaw (rotation). Each wheel's power is a sum of the three with different signs.

- Front left = `axial + lateral + yaw`
- Front right = `axial - lateral - yaw`
- Back left = `axial - lateral + yaw`
- Back right = `axial + lateral - yaw`

When strafing right, the front left and back right wheels drive forward while the front right and back left drive backward. The roller angles turn that into sideways motion.

## Code

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.util.ElapsedTime;

@TeleOp(name="Basic: Omni Linear OpMode", group="Linear OpMode")
public class BasicOmniOpMode_Linear extends LinearOpMode {

    private ElapsedTime runtime = new ElapsedTime();
    private DcMotor frontLeftDrive = null;
    private DcMotor backLeftDrive = null;
    private DcMotor frontRightDrive = null;
    private DcMotor backRightDrive = null;

    @Override
    public void runOpMode() {

        // These strings must match the names in the robot configuration.
        frontLeftDrive  = hardwareMap.get(DcMotor.class, "front_left_drive");
        backLeftDrive   = hardwareMap.get(DcMotor.class, "back_left_drive");
        frontRightDrive = hardwareMap.get(DcMotor.class, "front_right_drive");
        backRightDrive  = hardwareMap.get(DcMotor.class, "back_right_drive");

        // Start with these reversals, then test. Push the left stick forward and
        // reverse any wheel that runs backward until all four drive the robot forward.
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

            // Left stick drives and strafes, right stick rotates.
            double axial   = -gamepad1.left_stick_y;  // pushing the stick forward gives a negative value
            double lateral =  gamepad1.left_stick_x;
            double yaw     =  gamepad1.right_stick_x;

            double frontLeftPower  = axial + lateral + yaw;
            double frontRightPower = axial - lateral - yaw;
            double backLeftPower   = axial - lateral + yaw;
            double backRightPower  = axial + lateral - yaw;

            // Scale the powers down together so none of them exceeds 100%.
            max = Math.max(Math.abs(frontLeftPower), Math.abs(frontRightPower));
            max = Math.max(max, Math.abs(backLeftPower));
            max = Math.max(max, Math.abs(backRightPower));

            if (max > 1.0) {
                frontLeftPower  /= max;
                frontRightPower /= max;
                backLeftPower   /= max;
                backRightPower  /= max;
            }

            frontLeftDrive.setPower(frontLeftPower);
            frontRightDrive.setPower(frontRightPower);
            backLeftDrive.setPower(backLeftPower);
            backRightDrive.setPower(backRightPower);

            telemetry.addData("Status", "Run Time: " + runtime.toString());
            telemetry.addData("Front left/Right", "%4.2f, %4.2f", frontLeftPower, frontRightPower);
            telemetry.addData("Back  left/Right", "%4.2f, %4.2f", backLeftPower, backRightPower);
            telemetry.update();
        }
    }
}
```

**Normalization.** Adding three inputs can produce a value above 1.0, which a motor cannot do. The SDK finds the largest of the four absolute powers and, only when that is over 1.0, divides all four by it. The ratios between wheels stay the same, so the robot still moves in the direction the sticks asked for.

**Reversals.** Which side needs reversing depends on how the motors are mounted. If the robot drives backward when you push forward, flip all four.

## Notes

- Weight has to be spread across all four wheels. A light corner loses traction and the robot drifts while strafing.
- The wheels must be mounted so the rollers form an X when viewed from above. If the robot rotates instead of strafing, one or more wheel is in the wrong position.
- Mecanum robots strafe slower than they drive forward. Some teams multiply the lateral input by about 1.1 to compensate. That is not in the SDK sample, and you should tune it for you're robot if you add it.
- Field-centric drive rotates the axial and lateral inputs by the IMU heading before the math above, so the robot moves relative to the field. The SDK sample for that is `RobotTeleopMecanumFieldRelativeDrive`.
