---
title: Touch Sensor
panelCategory: "Sensors"
date: 2026-05-03
description: Reading the REV Touch Sensor and using it as a limit switch.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The touch sensor is a digital switch. It reports pressed or not pressed.

## Setup

Configure it as a REV Touch Sensor on a digital port. In code, use `TouchSensor` and `isPressed()`.

```java
import com.qualcomm.robotcore.hardware.TouchSensor;

TouchSensor touchSensor = hardwareMap.get(TouchSensor.class, "touchSensor");
```

```java
if (touchSensor.isPressed()) {
    telemetry.addData("Touch", "Pressed");
} else {
    telemetry.addData("Touch", "Not pressed");
}
```

## Limit switch

Mount the sensor at the bottom of a lift or arm's travel. When it is pressed:

1. Stop the motor so it does not drive into the hard stop.
2. Reset the encoder to zero so the position is known.

```java
if (touchSensor.isPressed() && slidePower < 0) {
    slideMotor.setPower(0);
    slideMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
    slideMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
}
```

Resetting on every bottom-out means the encoder stays correct even if the belt slips during a match.

## Acting once per press

`isPressed()` is true for every loop while the button is held. To do something once per press, compare to the value from the last loop and act only when it changes from false to true.

```java
boolean lastPressed = false;
boolean clawOpen = false;

// inside the loop
boolean pressed = touchSensor.isPressed();
if (pressed && !lastPressed) {
    clawOpen = !clawOpen;
}
lastPressed = pressed;
```

This is rising edge detection. The same pattern works for gamepad buttons.

## Example

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.TouchSensor;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Touch Sensor Limit Switch")
public class TouchSensorExample extends LinearOpMode {

    private TouchSensor limitSwitch;
    private DcMotor liftMotor;

    @Override
    public void runOpMode() {
        limitSwitch = hardwareMap.get(TouchSensor.class, "touchSensor");
        liftMotor = hardwareMap.get(DcMotor.class, "liftMotor");

        waitForStart();

        while (opModeIsActive()) {
            double liftPower = -gamepad1.left_stick_y;
            boolean pressed = limitSwitch.isPressed();

            if (pressed && liftPower < 0) {
                liftMotor.setPower(0);
                liftMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
                liftMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
            } else {
                liftMotor.setPower(liftPower);
            }

            telemetry.addData("Lift Power", "%.2f", liftPower);
            telemetry.addData("Pressed", pressed);
            telemetry.addData("Position", liftMotor.getCurrentPosition());
            telemetry.update();
        }
    }
}
```

The lift can still move up while the switch is pressed, only downward power is blocked.
