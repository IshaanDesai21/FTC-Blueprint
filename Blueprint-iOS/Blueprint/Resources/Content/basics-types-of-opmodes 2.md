---
title: Types of OpModes
panelCategory: "Basics"
date: 2026-03-28
description: The core differences between an OpMode and a LinearOpMode with Java examples.
tags: [completed, software, beginner, video]
author: Ishaan Desai
published: true
---

# Types of OpModes

In the FTC SDK, there are two primary classes you can inherit from to write your robot controller programs: `OpMode` and `LinearOpMode`. Choosing which one to use depends on how you want to structure your code and logic.

---

## OpMode

An `OpMode` (often called an Iterative OpMode) acts like a state machine. It has specific methods (`init()`, `init_loop()`, `start()`, `loop()`, and `stop()`) that are repeatedly called by the system in a non-blocking loop.

> [!WARNING]
> You must avoid using loops like `while()` or `Thread.sleep()` inside `loop()`, because it will freeze the robot and crash the app.

---

## Linear OpMode

A `LinearOpMode` runs your code linearly from top to bottom. Everything happens inside a single `runOpMode()` method. To keep the program running continuously throughout the match, you must manually use a loop (usually `while (opModeIsActive())`). 

It's easier for beginners to grasp because it acts like a traditional linear program and permits blocking code (like `sleep()`).

---

## The Difference in Code

Here is a side-by-side comparison of a simple robot waiting for start and then driving forward. Notice the structural and syntax differences between the two.

### Iterative OpMode Example

```java
@TeleOp(name="Basic Iterative")
public class BasicIterative extends OpMode {
    DcMotor motor;

    @Override
    public void init() {
        motor = hardwareMap.get(DcMotor.class, "motor");
    }

    @Override
    public void loop() {
        // This repeatedly runs incredibly fast! No while loops here.
        motor.setPower(1.0);
    }
}
```

### Linear OpMode Example

```java
@TeleOp(name="Basic Linear")
public class BasicLinear extends LinearOpMode {
    DcMotor motor;

    @Override
    public void runOpMode() throws InterruptedException {
        // 1. Initialization code
        motor = hardwareMap.get(DcMotor.class, "motor");

        // 2. Wait for the play button
        waitForStart();

        // 3. Loop while the match is running
        while (opModeIsActive()) {
            motor.setPower(1.0);
        }
    }
}
```
