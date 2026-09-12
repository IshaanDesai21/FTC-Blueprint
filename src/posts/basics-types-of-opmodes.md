---
title: Types of OpModes
panelCategory: "Basics"
date: 2026-04-22
description: The difference between OpMode and LinearOpMode.
tags: [completed, software, beginner]
author: Blueprint
published: true
---

Every program you write for the robot is an OpMode. The SDK gives you two base classes: `OpMode` and `LinearOpMode`.

## OpMode

`OpMode` (also called an iterative OpMode) splits your program into methods the SDK calls for you:

- `init()` runs once when the driver presses Init.
- `init_loop()` runs repeatedly until Start is pressed.
- `start()` runs once when Start is pressed.
- `loop()` runs repeatedly until the OpMode is stopped.
- `stop()` runs once at the end.

You do not write your own loop. The SDK calls `loop()` over and over, and each call should handle one pass of logic and return.

Do not put a `while` loop or `sleep()` inside `loop()`. It blocks the SDK from running and the robot stops responding.

## LinearOpMode

`LinearOpMode` has one method, `runOpMode()`, that runs top to bottom. You initialize hardware, call `waitForStart()`, then write your own loop with `while (opModeIsActive())`.

Blocking calls like `sleep()` are allowed here. That makes it easier to write autonomous routines where steps happen in order.

Most teams use `LinearOpMode` for both TeleOp and autonomous. The examples on this site use it.

## Same program, both ways

### OpMode

```java
@TeleOp(name = "Basic Iterative")
public class BasicIterative extends OpMode {
    DcMotor motor;

    @Override
    public void init() {
        motor = hardwareMap.get(DcMotor.class, "motor");
    }

    @Override
    public void loop() {
        motor.setPower(1.0);
    }
}
```

### LinearOpMode

```java
@TeleOp(name = "Basic Linear")
public class BasicLinear extends LinearOpMode {
    DcMotor motor;

    @Override
    public void runOpMode() {
        motor = hardwareMap.get(DcMotor.class, "motor");

        waitForStart();

        while (opModeIsActive()) {
            motor.setPower(1.0);
        }
    }
}
```

Both do the same thing. The iterative version seperates init and runtime into methods. The linear version keeps it in one place and you control the loop.
