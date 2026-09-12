---
title: Finite State Machines in TeleOp
panelCategory: "TeleOp"
date: 2026-06-05
description: Enums, rising edge detection, and a claw and slide state machine.
tags: [software, manual, intermediate, completed]
author: Blueprint
published: true
---

## The problem

You want A to toggle the claw.

```java
if (gamepad2.a) {
    clawServo.setPosition(0.8);
}
```

That only opens it. Adding an `else` that closes it means the claw is closed whenever A is not held. A boolean flag that flips when A is true flips on every loop while A is held, which is many times per press.

A state machine fixes both.

## States

The mechanism is in exactly one state at a time. A button press moves it to another state. Java enums are the natural way to write the states.

```java
enum ClawState {
    OPEN,
    CLOSED
}

enum SlideState {
    RETRACTED,
    LOW,
    HIGH
}
```

```java
ClawState clawState = ClawState.CLOSED;
SlideState slideState = SlideState.RETRACTED;
```

Each loop does two things: check inputs and change state if needed, then apply the current state to the hardware.

## Rising edge detection

`gamepad2.a` is true on every loop while the button is held. To act once per press, remember the value from the last loop and act only when it goes from false to true.

```java
boolean prevA = false;

// in the loop
boolean currA = gamepad2.a;

if (currA && !prevA) {
    // runs once per press
}

prevA = currA;
```

## Example: claw and slide

Controls:

- `gamepad2.a` toggles the claw.
- `gamepad2.dpad_up` sends the slide to HIGH.
- `gamepad2.dpad_down` sends the slide to LOW.
- `gamepad2.b` retracts the slide.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.Servo;

@TeleOp(name = "FSM TeleOp")
public class FSMTeleOp extends LinearOpMode {

    enum ClawState { OPEN, CLOSED }
    enum SlideState { RETRACTED, LOW, HIGH }

    DcMotor frontLeft, frontRight, backLeft, backRight;
    DcMotor slideMotor;
    Servo clawServo;

    ClawState clawState = ClawState.CLOSED;
    SlideState slideState = SlideState.RETRACTED;

    boolean prevA = false;
    boolean prevDUp = false;
    boolean prevDDown = false;
    boolean prevB = false;

    static final int SLIDE_RETRACTED = 0;
    static final int SLIDE_LOW = 600;
    static final int SLIDE_HIGH = 1400;

    static final double CLAW_OPEN = 0.7;
    static final double CLAW_CLOSED = 0.2;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        slideMotor = hardwareMap.get(DcMotor.class, "slideMotor");
        slideMotor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        slideMotor.setTargetPosition(SLIDE_RETRACTED);
        slideMotor.setMode(DcMotor.RunMode.RUN_TO_POSITION);
        slideMotor.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        clawServo = hardwareMap.get(Servo.class, "clawServo");
        clawServo.setPosition(CLAW_CLOSED);

        waitForStart();

        while (opModeIsActive()) {
            double y  = -gamepad1.left_stick_y;
            double x  =  gamepad1.left_stick_x;
            double rx =  gamepad1.right_stick_x;

            double denominator = Math.max(Math.abs(y) + Math.abs(x) + Math.abs(rx), 1);

            frontLeft.setPower((y + x + rx) / denominator);
            frontRight.setPower((y - x - rx) / denominator);
            backLeft.setPower((y - x + rx) / denominator);
            backRight.setPower((y + x - rx) / denominator);

            boolean currA = gamepad2.a;
            if (currA && !prevA) {
                clawState = (clawState == ClawState.CLOSED) ? ClawState.OPEN : ClawState.CLOSED;
            }
            prevA = currA;

            switch (clawState) {
                case OPEN:
                    clawServo.setPosition(CLAW_OPEN);
                    break;
                case CLOSED:
                    clawServo.setPosition(CLAW_CLOSED);
                    break;
            }

            boolean currDUp   = gamepad2.dpad_up;
            boolean currDDown = gamepad2.dpad_down;
            boolean currB     = gamepad2.b;

            if (currDUp && !prevDUp) {
                slideState = SlideState.HIGH;
            } else if (currDDown && !prevDDown) {
                slideState = SlideState.LOW;
            } else if (currB && !prevB) {
                slideState = SlideState.RETRACTED;
            }

            prevDUp   = currDUp;
            prevDDown = currDDown;
            prevB     = currB;

            int slideTarget;
            switch (slideState) {
                case HIGH: slideTarget = SLIDE_HIGH; break;
                case LOW:  slideTarget = SLIDE_LOW;  break;
                default:   slideTarget = SLIDE_RETRACTED; break;
            }

            slideMotor.setTargetPosition(slideTarget);
            slideMotor.setPower(0.8);

            telemetry.addData("Claw", clawState);
            telemetry.addData("Slide", slideState);
            telemetry.addData("Slide Pos", slideMotor.getCurrentPosition());
            telemetry.update();
        }
    }
}
```

## Notes

- The slide stays in `RUN_TO_POSITION` for the whole OpMode. The hub drives it to the target and holds it there. The OpMode only changes the target.
- `setTargetPosition()` is called before switching to `RUN_TO_POSITION` at init. The SDK requires a target to exist first.
- The slide uses one button per position instead of a toggle so the operator always knows where it will go.
- Servo positions are set every loop. That is fine, the servo just holds where it is.

## Sequences

A mechanism that has to do steps in order, like close the claw then raise the slide then open the claw, is also a state machine. Each step is a state, and the transition condition is either a timer or a sensor check.

```java
enum ScoreState { IDLE, CLOSING, RAISING, RELEASING }

ScoreState scoreState = ScoreState.IDLE;
ElapsedTime stateTimer = new ElapsedTime();

// in the loop
switch (scoreState) {
    case IDLE:
        if (currX && !prevX) {
            clawServo.setPosition(CLAW_CLOSED);
            stateTimer.reset();
            scoreState = ScoreState.CLOSING;
        }
        break;
    case CLOSING:
        if (stateTimer.seconds() > 0.4) {
            slideMotor.setTargetPosition(SLIDE_HIGH);
            scoreState = ScoreState.RAISING;
        }
        break;
    case RAISING:
        if (!slideMotor.isBusy()) {
            clawServo.setPosition(CLAW_OPEN);
            stateTimer.reset();
            scoreState = ScoreState.RELEASING;
        }
        break;
    case RELEASING:
        if (stateTimer.seconds() > 0.4) {
            scoreState = ScoreState.IDLE;
        }
        break;
}
```

The loop never blocks, so the driver keeps driving while the sequence runs. This is the reason to use a state machine instead of `sleep()` in TeleOp.

## When to use one

- A mechanism with a fixed set of modes.
- Any toggle button.
- A sequence of steps that should not be interupted by the next button press.
- Multiple mechanisms that each track their own state.
