---
title: Teleop Introduction
panelCategory: "TeleOp"
date: 2026-05-30
description: The TeleOp period, gamepads, and the structure of a TeleOp OpMode.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

## The TeleOp period

An FTC match has a 30 second autonomous period followed by a 2 minute driver-controlled period. The last 30 seconds of the driver-controlled period is the end game. TeleOp is the OpMode that runs during the driver-controlled period.

The OpMode loops continuously, reading the gamepads and updating motors and servos each pass.

## Gamepads

Two gamepads connect to the Driver Station. By convention `gamepad1` is the driver, who moves the robot, and `gamepad2` is the operator, who runs the mechanisms.

```java
double forward = -gamepad1.left_stick_y;
boolean clawClose = gamepad2.a;
```

Inputs:

- Sticks: `left_stick_x`, `left_stick_y`, `right_stick_x`, `right_stick_y`. Range -1.0 to 1.0.
- Triggers: `left_trigger`, `right_trigger`. Range 0.0 to 1.0.
- Bumpers: `left_bumper`, `right_bumper`. Boolean.
- Buttons: `a`, `b`, `x`, `y`, `dpad_up`, `dpad_down`, `dpad_left`, `dpad_right`, `start`, `back`. Boolean.

Pushing a stick forward gives a **negative** Y value. Negate it when you mean forward.

```java
double forward = -gamepad1.left_stick_y;
```

## Structure

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;

@TeleOp(name = "My TeleOp")
public class MyTeleOp extends LinearOpMode {

    @Override
    public void runOpMode() {
        // get hardware from hardwareMap here

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            // read gamepads, set motor and servo outputs

            telemetry.update();
        }
    }
}
```

Three parts:

1. **Before `waitForStart()`.** Get devices from `hardwareMap`, set directions, set servos to known positions. This runs when the driver presses Init. The robot should not move here.
2. **`waitForStart()`.** Blocks until the driver presses Start.
3. **`while (opModeIsActive())`.** The main loop. Runs until Stop is pressed or the match timer ends. All driving code goes here.

Add `@TeleOp` so the OpMode shows up under the TeleOp list on the Driver Station. Autonomous OpModes use `@Autonomous`.

## Telemetry

Telemetry sends text to the Driver Station screen.

```java
telemetry.addData("Forward Power", forward);
telemetry.addData("Slide Position", slide.getCurrentPosition());
telemetry.update();
```

Nothing shows until `update()` is called. Call it once per loop at the end. Use it to show motor powers, sensor values, and mechanism states while testing, and to show drivers things they need mid-match like wether the claw is open.

## Next

[Teleop Beginner](/software/teleop-beginner) builds a complete mecanum TeleOp with a slow mode. [Finite State Machines in TeleOp](/software/teleop-fsm) covers mechanisms with multiple steps.
