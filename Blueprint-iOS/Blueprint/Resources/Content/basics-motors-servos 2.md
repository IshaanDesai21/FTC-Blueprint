---
title: Basics of Motors and Servos
panelCategory: "Basics"
date: 2026-03-28
description: Programming guide for DC motors and servos in FTC.
tags: [completed, software, beginner, completed]
author: Ishaan Desai
published: true
---

# Basics of Motors and Servos

Motors and servos are the primary actuators of an FTC robot. This guide covers how to program them in Java using the FTC Robot Controller app.

---

## DC Motors

DC motors provide the power for your drivetrain and other mechanisms like arms or linear slides.

### 1. Initialization
Use the `hardwareMap` to initialize your motor.

```java
DcMotor leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
```

### 2. Setting Direction
Depending on how your motor is oriented, you might need to reverse its direction.

```java
leftDrive.setDirection(DcMotor.Direction.REVERSE);
```

### 3. Basic Control
You can control the motor's power from -1.0 to 1.0.

```java
leftDrive.setPower(0.5); // 50% power forward
```

### 4. Zero Power Behavior
Choose how the motor should behave when power is set to zero.

- **Brake:** Resists movement (better for precision).
- **Float:** Free to spin (better for some intakes).

```java
leftDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
```

---

## Servos

Servos are used for precision movements, like grippers or small rotations.

### 1. Standard Servos
Standard servos move to a specific position from 0.0 to 1.0.

```java
Servo gripper = hardwareMap.get(Servo.class, "gripper");
gripper.setPosition(0.5); // Move to the middle position
```

### 2. Continuous Rotation (CR) Servos
CR servos rotate continuously and are controlled like a DC motor.

```java
CRServo intake = hardwareMap.get(CRServo.class, "intake");
intake.setPower(1.0); // Full speed forward
```

---

## Example Program: LinearOpMode

Here is a complete example of a `LinearOpMode` that initializes a motor and a servo, and allows you to control them.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.Servo;

@TeleOp(name = "Motor and Servo Example", group = "Tutorial")
public class MotorServoExample extends LinearOpMode {

    private DcMotor armMotor;
    private Servo gripper;

    @Override
    public void runOpMode() {
        // 1. Initialize hardware
        armMotor = hardwareMap.get(DcMotor.class, "armMotor");
        gripper = hardwareMap.get(Servo.class, "gripper");

        // 2. Set directions and behaviors
        armMotor.setDirection(DcMotor.Direction.FORWARD);
        armMotor.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        // Wait for the game to start (driver presses START)
        waitForStart();

        // Run until the end of the match (driver presses STOP)
        while (opModeIsActive()) {
            
            // 3. Control Motor (e.g., using left stick Y)
            double motorPower = -gamepad1.left_stick_y; 
            armMotor.setPower(motorPower);

            // 4. Control Servo (e.g., using buttons)
            if (gamepad1.a) {
                gripper.setPosition(1.0); // Open
            } else if (gamepad1.b) {
                gripper.setPosition(0.0); // Closed
            }

            // 5. Send telemetry to the driver station
            telemetry.addData("Motor Power", motorPower);
            telemetry.addData("Servo Position", gripper.getPosition());
            telemetry.update();
        }
    }
}
```

---

