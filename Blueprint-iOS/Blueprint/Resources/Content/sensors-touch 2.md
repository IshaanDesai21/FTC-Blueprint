---
title: Touch Sensor
panelCategory: "Sensors"
date: 2026-04-05
description: Simple digital inputs for limit switches and button presses.
tags: [software, completed, beginner]
author: Ishaan Desai
published: true
---

# Touch Sensor Guide

The touch sensor is a simple digital switch. It returns a boolean value: either **pressed** or **not pressed**.

> [!NOTE]
> Even though it's called a "Touch" sensor, it behaves exactly like a **limit switch** or a **button**. In code, it's a `DigitalChannel` that returns `true` or `false`.

---

To use a touch sensor as a digital input, use the `DigitalChannel` class.

```java
import com.qualcomm.robotcore.hardware.DigitalChannel;

DigitalChannel touchSensor = hardwareMap.get(DigitalChannel.class, "touchSensor");
// Important: Set the mode to INPUT
touchSensor.setMode(DigitalChannel.Mode.INPUT);
```

The `getState()` method returns the current electrical state. For most FTC sensors (like the REV Touch Sensor), **`false`** means the sensor is pressed (grounded), and **`true`** means it is open.

```java
if (touchSensor.getState() == false) {
    telemetry.addData("Touch", "IS PRESSED");
} else {
    telemetry.addData("Touch", "Not Pressed");
}
```

### Tip
> Use `!touchSensor.getState()` to get a "logic high" when the button is pressed.

If you have a lift or an arm, you can place a touch sensor at the extreme end of its range. When the mechanism hits the sensor, you can:
1. **Stop the motor** immediately to prevent damage.
2. **Reset the encoder** to zero to ensure your software stays calibrated.

```java
if (limitSwitch.getState() == false) {
    // Stop and reset encoder once it hits the bottom
    slideMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
    slideMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
}
```

## 4. Single-Press Logic (Debouncing)

If you want to toggle something (like a claw) when you press a touch sensor, you need to make sure it only triggers **once** per press.

```java
boolean lastState = false;
boolean clawOpen = false;

// Inside your loop:
boolean currentState = !touchSensor.getState(); // false = pressed
if (currentState && !lastState) {
    // This only runs the moment the sensor is FIRST pressed
    clawOpen = !clawOpen; 
}
lastState = currentState;
```

---

This example shows how to use a `DigitalChannel` as a limit switch for a simple motor-based lift.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DigitalChannel;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Digital Limit Switch Example", group = "Sensor")
public class TouchSensorExample extends LinearOpMode {

    private DigitalChannel limitSwitch;
    private DcMotor liftMotor;

    @Override
    public void runOpMode() {
        // 1. Initialize hardware
        limitSwitch = hardwareMap.get(DigitalChannel.class, "touchSensor");
        limitSwitch.setMode(DigitalChannel.Mode.INPUT);
        
        liftMotor = hardwareMap.get(DcMotor.class, "liftMotor");

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            // 2. Control Motor with joystick
            double liftPower = -gamepad1.left_stick_y;

            // 3. Limit Switch Logic:
            // State is 'false' when the sensor is pressed
            boolean isPressed = !limitSwitch.getState(); 

            if (isPressed && liftPower < 0) {
                 liftMotor.setPower(0);
                 liftMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
                 liftMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
                 telemetry.addData("Limit", "LIFT AT BOTTOM");
            } else {
                 liftMotor.setPower(liftPower);
                 telemetry.addData("Limit", "Normal Operation");
            }

            // 4. Telemetry output
            telemetry.addData("Lift Power", "%.2f", liftPower);
            telemetry.addData("Switch Pressed", isPressed);
            telemetry.update();
        }
    }
}
```

---
