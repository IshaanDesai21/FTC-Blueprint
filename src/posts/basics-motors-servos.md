---
title: Basics of Motors and Servos
panelCategory: "Basics"
date: 2026-04-15
description: Controlling DC motors, servos, and continuous rotation servos in Java.
tags: [completed, software, beginner]
author: Blueprint
published: true
---

## DC Motors

DC motors are used for drivetrains and for high-torque mechanisms like arms, slides, and intakes.

### Getting the motor

Every device comes from `hardwareMap`. The string must match the name in the robot configuration.

```java
DcMotor leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
```

### Direction

If a motor spins the wrong way for how it is mounted, reverse it.

```java
leftDrive.setDirection(DcMotor.Direction.REVERSE);
```

On a drivetrain, the motors on one side are usually reversed because they face the opposite direction from the other side.

### Power

Power ranges from -1.0 to 1.0. Zero stops the motor.

```java
leftDrive.setPower(0.5);
```

### Zero power behavior

`BRAKE` resists movement when power is zero. `FLOAT` lets the motor spin freely.

```java
leftDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
```

Use `BRAKE` for arms and slides so they hold position. For drivetrains either works.

## Servos

### Standard servos

A standard servo moves to a position between 0.0 and 1.0 and holds it.

```java
Servo gripper = hardwareMap.get(Servo.class, "gripper");
gripper.setPosition(0.5);
```

The actual angle for 0.0 and 1.0 depends on the servo and it's range setting. Find the positions you need by testing.

### Continuous rotation servos

A CR servo spins like a motor. You set power, not position.

```java
CRServo intake = hardwareMap.get(CRServo.class, "intake");
intake.setPower(1.0);
```

## Example OpMode

An arm motor on the left stick and a gripper servo on the A and B buttons.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.Servo;

@TeleOp(name = "Motor and Servo Example")
public class MotorServoExample extends LinearOpMode {

    private DcMotor armMotor;
    private Servo gripper;

    @Override
    public void runOpMode() {
        armMotor = hardwareMap.get(DcMotor.class, "armMotor");
        gripper = hardwareMap.get(Servo.class, "gripper");

        armMotor.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        waitForStart();

        while (opModeIsActive()) {
            double motorPower = -gamepad1.left_stick_y;
            armMotor.setPower(motorPower);

            if (gamepad1.a) {
                gripper.setPosition(1.0);
            } else if (gamepad1.b) {
                gripper.setPosition(0.0);
            }

            telemetry.addData("Motor Power", motorPower);
            telemetry.addData("Servo Position", gripper.getPosition());
            telemetry.update();
        }
    }
}
```

The left stick Y value is negated because the gamepad reports up as negative. Negating it makes pushing forward give positive power.
