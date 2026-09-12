---
title: Teleop Fsm
panelCategory: "TeleOp"
date: 2026-03-28
description: How to use finite state machines to control multi-step TeleOp mechanisms cleanly, with edge-detected button presses.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Teleop FSM

The [Teleop Beginner](/software/teleop-beginner) guide controlled a claw with a direct `if (gamepad2.right_bumper)` check. That works fine for a mechanism with two positions. But real robots often need mechanisms that move through several steps in sequence, and that's where simple `if` logic starts to fall apart.

---

## 1. Why Simple Toggles Break Down

Consider a claw that needs three states instead of two: **Open**, **Closing** (waiting for a servo to physically finish moving before doing anything else), and **Closed**. Or a scoring sequence: intake grabs a game piece, then automatically transfers it to an outtake mechanism, then releases it, all from a single button press.

A naive toggle looks like this:

```java
// Fragile: only works for two states, and re-triggers every loop iteration
if (gamepad2.a) {
    clawOpen = !clawOpen;
}
```

This has two serious problems:

1. **It re-triggers constantly.** The main loop runs hundreds of times per second. If the driver holds the button down for even a tenth of a second, this code sees `gamepad2.a == true` on dozens of consecutive iterations and toggles `clawOpen` back and forth uncontrollably.
2. **It has nowhere to put "in-between" logic.** There's no clean way to express "wait 300ms for the servo to finish closing before allowing the next action" or "don't start the transfer until the intake sensor confirms a game piece is present."

Both problems are solved by two techniques used together: **edge detection** for button presses, and a **finite state machine (FSM)** for the mechanism itself.

---

## 2. Edge Detection: Detecting a Press, Not a Hold

An "edge" is the moment a button transitions from not-pressed to pressed. To detect it, compare the button's state this loop iteration against its state last loop iteration:

```java
boolean currentA = gamepad2.a;
if (currentA && !lastA) {
    // This block runs exactly once per physical press,
    // not once per loop iteration while held
}
lastA = currentA;
```

This pattern (`current && !last`, then updating `last = current` at the end of the loop) is the standard way to turn a held button into a single discrete event in FTC TeleOp code.

> [!NOTE]
> You'll need one `lastX` boolean per button you want edge-detected, declared as a class field (outside the loop) so it persists between iterations.

---

## 3. The FSM Pattern: `enum` + `switch`

A finite state machine represents a mechanism as one of a fixed set of named states, and defines exactly which transitions between states are legal. In Java, this maps naturally onto an `enum` for the states and a `switch` statement inside the main loop.

```java
private enum ClawState {
    OPEN,
    CLOSING,
    CLOSED
}

private ClawState clawState = ClawState.OPEN;
private ElapsedTime clawTimer = new ElapsedTime();
```

Inside the loop, a `switch` on the current state decides what to do, and whether it's time to move to the next state:

```java
switch (clawState) {
    case OPEN:
        claw.setPosition(OPEN_POSITION);
        if (pressedA) {
            clawState = ClawState.CLOSING;
            clawTimer.reset();
        }
        break;

    case CLOSING:
        claw.setPosition(CLOSED_POSITION);
        // Give the servo time to physically reach position before
        // treating the claw as fully closed
        if (clawTimer.seconds() > 0.3) {
            clawState = ClawState.CLOSED;
        }
        break;

    case CLOSED:
        claw.setPosition(CLOSED_POSITION);
        if (pressedA) {
            clawState = ClawState.OPEN;
        }
        break;
}
```

Each `case` only reacts to the inputs and timers that matter for *that* state. `CLOSING` ignores button presses entirely until the timer confirms the servo has finished moving, something a flat `if` statement has no clean way to express.

---

## 4. Complete Example: Automated Intake-to-Outtake Transfer

Here's a full `LinearOpMode` that uses an FSM to run a common competitive mechanism: pressing one button starts an automated sequence that runs the intake, waits, then transfers the game piece to the outtake, without the driver needing to babysit every step.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.Servo;
import com.qualcomm.robotcore.util.ElapsedTime;

@TeleOp(name = "FSM Transfer Example", group = "Tutorial")
public class FsmTransferExample extends LinearOpMode {

    // Hardware
    private DcMotor intakeMotor;
    private DcMotor outtakeMotor;
    private Servo transferGate;

    // Timing constants (seconds)
    private static final double INTAKE_DURATION = 1.0;
    private static final double TRANSFER_DURATION = 0.5;
    private static final double OUTTAKE_DURATION = 0.75;

    // Servo positions
    private static final double GATE_CLOSED = 0.0;
    private static final double GATE_OPEN = 1.0;

    // FSM state
    private enum TransferState {
        IDLE,
        INTAKING,
        TRANSFERRING,
        OUTTAKING
    }

    private TransferState state = TransferState.IDLE;
    private final ElapsedTime stateTimer = new ElapsedTime();

    // Edge detection
    private boolean lastA = false;

    @Override
    public void runOpMode() {
        // 1. Initialize hardware
        intakeMotor  = hardwareMap.get(DcMotor.class, "intakeMotor");
        outtakeMotor = hardwareMap.get(DcMotor.class, "outtakeMotor");
        transferGate = hardwareMap.get(Servo.class, "transferGate");

        transferGate.setPosition(GATE_CLOSED);

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {

            // 2. Edge detection for the trigger button
            boolean currentA = gamepad2.a;
            boolean pressedA = currentA && !lastA;
            lastA = currentA;

            // 3. FSM: run the correct behavior for the current state,
            //    and decide when to transition to the next one
            switch (state) {
                case IDLE:
                    intakeMotor.setPower(0);
                    outtakeMotor.setPower(0);
                    transferGate.setPosition(GATE_CLOSED);

                    if (pressedA) {
                        state = TransferState.INTAKING;
                        stateTimer.reset();
                    }
                    break;

                case INTAKING:
                    intakeMotor.setPower(1.0);

                    if (stateTimer.seconds() > INTAKE_DURATION) {
                        state = TransferState.TRANSFERRING;
                        stateTimer.reset();
                    }
                    break;

                case TRANSFERRING:
                    intakeMotor.setPower(0);
                    transferGate.setPosition(GATE_OPEN);

                    if (stateTimer.seconds() > TRANSFER_DURATION) {
                        state = TransferState.OUTTAKING;
                        stateTimer.reset();
                    }
                    break;

                case OUTTAKING:
                    transferGate.setPosition(GATE_CLOSED);
                    outtakeMotor.setPower(1.0);

                    if (stateTimer.seconds() > OUTTAKE_DURATION) {
                        state = TransferState.IDLE;
                        stateTimer.reset();
                    }
                    break;
            }

            // 4. Allow the driver to cancel back to IDLE at any point
            if (gamepad2.b) {
                state = TransferState.IDLE;
            }

            // 5. Telemetry
            telemetry.addData("State", state);
            telemetry.addData("Timer", "%.2f", stateTimer.seconds());
            telemetry.update();
        }
    }
}
```

A single press of `gamepad2.a` kicks off the entire `INTAKING → TRANSFERRING → OUTTAKING → IDLE` sequence automatically, with each state controlling exactly the hardware it needs to and cleanly handing off to the next. The `gamepad2.b` escape hatch lets the operator abort back to `IDLE` if something goes wrong mid-sequence: a safety pattern worth including in any automated FSM.

> [!WARNING]
> Real competition code should replace fixed timers with sensor feedback wherever possible. For example, a color sensor can confirm a game piece has actually left the intake before transitioning out of `TRANSFERRING`. Timers are a reasonable starting point, but they assume every cycle takes exactly the same amount of time, which isn't always true.

---

## 5. Recap

- Flat `if` toggles work for single-button, two-state mechanisms, but break down for anything with intermediate steps or timing requirements.
- **Edge detection** (`current && !last`) turns a held button into a single discrete event, so one physical press doesn't trigger dozens of state changes.
- An **`enum` + `switch` FSM** gives each state its own isolated block of logic, and makes the legal transitions between states explicit and easy to reason about.
- Timers (`ElapsedTime`) and sensors can both be used as transition conditions, though sensors are more robust when available.

With driving covered in [Teleop Beginner](/software/teleop-beginner) and mechanism sequencing covered here, you now have the core tools to build a full competition TeleOp OpMode.

---
