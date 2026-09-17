---
title: Subsystem Architecture and Code Organization
panelCategory: "Basics"
date: 2026-06-29
description: Splitting robot code into one class per mechanism.
tags: [software, intermediate, completed]
author: Blueprint
published: true
---

## What a subsystem is

A subsystem is a class for one mechanism. It owns the motors, servos, and sensors for that mechanism, and the methods that move it.

```java
public class Intake {
    private DcMotor motor;

    public Intake(HardwareMap hardwareMap) {
        motor = hardwareMap.get(DcMotor.class, "intake_motor");
    }

    public void intake() {
        motor.setPower(1.0);
    }

    public void outtake() {
        motor.setPower(-1.0);
    }

    public void stop() {
        motor.setPower(0);
    }
}
```

TeleOp and autonomous both create an `Intake` and call `intake()`, `outtake()`, or `stop()`. Neither OpMode knows the motor name or the power values. Changing how the intake works is one edit in one file.

## Why

- **One copy of each mechanism's logic.** Without subsystems, TeleOp and autonomous each get their own copy and they drift apart.
- **Easier debugging.** If the intake is wrong, the intake code is in one file.
- **Easier testing.** A small OpMode can exercise one subsystem on its own.
- **Parallel work.** Two programmers can work on `Intake` and `Lift` without editing the same file.

## Robot class

Many teams add a `Robot` class that constructs every subsystem, so an OpMode makes one object.

```java
public class Robot {
    public Drivetrain drivetrain;
    public Intake intake;
    public Lift lift;

    public Robot(HardwareMap hardwareMap) {
        drivetrain = new Drivetrain(hardwareMap);
        intake = new Intake(hardwareMap);
        lift = new Lift(hardwareMap);
    }
}
```

```java
Robot robot = new Robot(hardwareMap);

// in the loop
robot.intake.intake();
robot.lift.moveToPosition(Lift.Position.HIGH);
```

The OpMode decides what happens and when. The subsystems handle how.

## Subsystems with state

A mechanism that has to reach a position needs an `update()` method the OpMode calls every loop, so the subsystem can run its controller.

```java
public class Lift {
    public enum Position { LOW, HIGH }

    private DcMotor motor;
    private int target = 0;

    public Lift(HardwareMap hardwareMap) {
        motor = hardwareMap.get(DcMotor.class, "lift_motor");
    }

    public void moveToPosition(Position p) {
        target = (p == Position.HIGH) ? 1800 : 0;
    }

    public void update() {
        double error = target - motor.getCurrentPosition();
        motor.setPower(error * 0.005);
    }

    public boolean atTarget() {
        return Math.abs(target - motor.getCurrentPosition()) < 20;
    }
}
```

The OpMode calls `robot.lift.update()` once per loop. It must not be skipped or the lift stops being controlled.

## How far to go

A single servo that opens and closes does not need its own class. Two constants and a method on the OpMode are enough. A mechanism with a motor, an encoder, a limit switch, and a target position does. The more a mechanism has to track, the more a class for it is worth it.

## Mistakes

- **Public motor fields.** If other code can call `lift.motor.setPower()` directly, the subsystem is not controlling anything. Expose methods, keep the hardware private.
- **Copying `hardwareMap.get()` calls between OpModes.** That is the sign a subsystem is missing.
- **Forgetting `update()`.** A subsystem with a controller does nothing if the OpMode never calls it.
