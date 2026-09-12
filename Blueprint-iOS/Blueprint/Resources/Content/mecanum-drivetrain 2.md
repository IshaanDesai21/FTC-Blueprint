---
title: Mecanum Drivetrain
panelCategory: 'Miscellaneous'
date: 2026-03-28
description: Learn the kinematics and programming behind a 4-motor mecanum drivetrain.
tags: [completed, software, beginner, kinematics]
author: Blueprint
published: true
---

# Mecanum Drivetrain

Mecanum wheels are a popular choice in FTC because they allow a robot to move in any direction (omnidirectional) without changing its orientation. This is achieved by the specialized rollers on the wheels, which are oriented at a 45-degree angle.

---

## Kinematics: The Math Behind the Movement

To control a mecanum drivetrain, we need to calculate the correct power for each of the four motors based on the desired movement (forward/backward, strafe left/right, and rotation).

### The Formulas

- **Front Left** = $y + x + r$
- **Front Right** = $y - x - r$
- **Back Left** = $y - x + r$
- **Back Right** = $y + x - r$

Where:

- $y$ is the forward/backward movement.
- $x$ is the strafing movement (sideways).
- $r$ is the rotational movement.

---

## Implementation in Java

Here is a basic implementation of mecanum drive control in an OpMode:

```java
@TeleOp
public class MecanumDrive extends LinearOpMode {
    @Override
    public void runOpMode() {
        DcMotor frontLeft = hardwareMap.get(DcMotor.class, "frontLeft");
        DcMotor frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        DcMotor backLeft = hardwareMap.get(DcMotor.class, "backLeft");
        DcMotor backRight = hardwareMap.get(DcMotor.class, "backRight");

        // Reverse the left side if necessary
        frontLeft.setDirection(DcMotorSimple.Direction.REVERSE);
        backLeft.setDirection(DcMotorSimple.Direction.REVERSE);

        waitForStart();

        while (opModeIsActive()) {
            double y = -gamepad1.left_stick_y; // Remember, y is reversed!
            double x = gamepad1.left_stick_x * 1.1; // Counteract imperfect strafing
            double rx = gamepad1.right_stick_x;

            // Denominator is the largest motor power (absolute value) or 1
            // This ensures all the powers maintain the same ratio,
            // but only if at least one is out of the range [-1, 1]
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

---

## Tips for Better Mecanum Drive

- **Weight Distribution:** Mecanum wheels work best when the weight is evenly distributed across all four wheels. If one wheel has less weight, it will slip.
- **Strafing Correction:** Because of the friction of the rollers, strafing often requires more power than moving forward. The `1.1` multiplier in the code above is a common way to compensate for this.
- **Field-Centric Drive:** For advanced drivers, converting the movement to be relative to the field (not the robot) makes maneuvering much more intuitive.
