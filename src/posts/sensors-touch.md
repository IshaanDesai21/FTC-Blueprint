---
title: Touch Sensor
panelCategory: "Sensors"
date: 2026-05-03
description: Reading the REV Touch Sensor as a digital channel and using it as a limit switch.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The touch sensor is a digital switch. It reports pressed or not pressed. The SDK sample is `SensorDigitalTouch`.

## Reading it

Configure the port as a Digital Device and name it `digitalTouch`. In code it is a `DigitalChannel` set to `INPUT`.

The state is **false when the button is pressed**. The switch pulls the line low, so a pressed button reads LOW. This catches people out.

```java
@TeleOp(name = "Sensor: digital channel", group = "Sensor")
public class SensorDigitalTouch extends LinearOpMode {
    DigitalChannel digitalTouch;

    @Override
    public void runOpMode() {

        digitalTouch = hardwareMap.get(DigitalChannel.class, "digitalTouch");
        digitalTouch.setMode(DigitalChannel.Mode.INPUT);

        telemetry.addData("DigitalTouchSensorExample", "Press start to continue...");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {

            // The button is pressed when the state reads false.
            if (digitalTouch.getState() == false) {
                telemetry.addData("Button", "PRESSED");
            } else {
                telemetry.addData("Button", "NOT PRESSED");
            }

            telemetry.update();
        }
    }
}
```

If you configure the port as a REV Touch Sensor instead, you can use the `TouchSensor` interface and `isPressed()`, which returns true when pressed. The examples below use that form because the logic reads the way you expect.

## Limit switch

Mount the sensor at the bottom of a lift or arm's travel. When it is pressed:

1. Stop the motor so it does not drive into the hard stop.
2. Reset the encoder to zero so the position is known.

```java
if (limitSwitch.isPressed() && liftPower < 0) {
    liftMotor.setPower(0);
    liftMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
    liftMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
}
```

Resetting on every bottom-out means the encoder stays correct even if the belt slips during a match.

## Acting once per press

`isPressed()` is true for every loop while the button is held. To do something once per press, compare to the value from the last loop and act only when it changes from false to true.

```java
boolean lastPressed = false;
boolean clawOpen = false;

// inside the loop
boolean pressed = limitSwitch.isPressed();
if (pressed && !lastPressed) {
    clawOpen = !clawOpen;
}
lastPressed = pressed;
```

This is rising edge detection. The same pattern works for gamepad buttons, and the SDK has a sample for it called `ConceptGamepadEdgeDetection`.

## Full example

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.TouchSensor;

@TeleOp(name = "Touch Sensor Limit Switch", group = "Sensor")
public class TouchSensorExample extends LinearOpMode {

    private TouchSensor limitSwitch;
    private DcMotor liftMotor;

    @Override
    public void runOpMode() {
        limitSwitch = hardwareMap.get(TouchSensor.class, "touch_sensor");
        liftMotor = hardwareMap.get(DcMotor.class, "lift_motor");

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
