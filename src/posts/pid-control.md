---
title: PID Control
panelCategory: "Control"
date: 2026-05-28
description: Proportional, integral, and derivative control, the PIDF built into the SDK, and writing your own loop.
tags: [completed, software, intermediate, control]
author: Blueprint
published: true
---

<script>
    import PIDVisualizer from '$lib/components/PIDVisualizer.svelte';
</script>

PID is the standard way to move a mechanism to a target position and hold it there. It works for arms, slides, turrets, and drivetrain heading.

The [PID Simulator](/simulators/pid) lets you change the constants and watch the response.

<PIDVisualizer />

## The three terms

Error is the distance from the target.

```
error = target - current
```

**Proportional.** Output is `kP * error`. Far from the target the output is large. Close to the target it is small. P alone usually stops short of the target or oscillates around it.

**Integral.** Output is `kI * (sum of error over time)`. If the mechanism sits just below the target because of gravity or friction, the sum grows until the output is enough to close the gap.

**Derivative.** Output is `kD * (rate of change of error)`. When the mechanism is moving toward the target quickly, this term pushes back and reduces overshoot.

The total output is the sum of the three.

## PIDF built into the SDK

The SDK does not include a PID controller class. Names like `PIDController` and `calculate()` come from third-party libraries.

What the SDK does have is PIDF control that runs on the hub for each motor. `RUN_USING_ENCODER` uses it to hold a velocity, and `RUN_TO_POSITION` uses it to reach a target position. You read and change the coefficients through `DcMotorEx`.

```java
DcMotorEx arm = hardwareMap.get(DcMotorEx.class, "left_arm");

PIDFCoefficients velocityPIDF = arm.getPIDFCoefficients(DcMotor.RunMode.RUN_USING_ENCODER);
PIDFCoefficients positionPIDF = arm.getPIDFCoefficients(DcMotor.RunMode.RUN_TO_POSITION);

telemetry.addData("Velocity PIDF", "%.3f %.3f %.3f %.3f",
        velocityPIDF.p, velocityPIDF.i, velocityPIDF.d, velocityPIDF.f);
telemetry.addData("Position P", "%.3f", positionPIDF.p);
telemetry.update();
```

To change them:

```java
// Velocity loop used by RUN_USING_ENCODER.
arm.setVelocityPIDFCoefficients(p, i, d, f);

// Position loop used by RUN_TO_POSITION. Only P is set here.
arm.setPositionPIDFCoefficients(p);

// How close, in ticks, counts as reaching the target in RUN_TO_POSITION.
arm.setTargetPositionTolerance(10);
```

`setPIDFCoefficients(DcMotor.RunMode mode, PIDFCoefficients coefficients)` does the same thing with the mode passed in.

Read the current values before changing anything and adjust from there. For most drivetrains and simple mechanisms the built-in controller is enough, and `RUN_TO_POSITION` with a good target is simpler than writing your own loop.

`setVelocity()` on a `DcMotorEx` commands a velocity in ticks per second, using the velocity loop above.

## Writing your own loop

Write your own when the built-in controller cannot do what you need. Examples are adding a gravity term for an arm, or controlling a mechanism from a sensor other than its motor encoder.

The motor runs in `RUN_WITHOUT_ENCODER` so the hub's own loop stays out of the way. The encoder still counts in that mode.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.DcMotorEx;
import com.qualcomm.robotcore.util.ElapsedTime;
import com.qualcomm.robotcore.util.Range;

@TeleOp(name = "Arm PID", group = "Linear OpMode")
public class ArmPID extends LinearOpMode {

    static final double kP = 0.005;
    static final double kI = 0.0;
    static final double kD = 0.0002;

    // Largest power the integral term is allowed to add.
    static final double MAX_I_POWER = 0.25;

    @Override
    public void runOpMode() {
        DcMotorEx arm = hardwareMap.get(DcMotorEx.class, "left_arm");
        arm.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        arm.setMode(DcMotor.RunMode.RUN_WITHOUT_ENCODER);
        arm.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        ElapsedTime timer = new ElapsedTime();
        double target = 0;
        double integralSum = 0;
        double lastError = 0;

        waitForStart();
        timer.reset();

        while (opModeIsActive()) {
            if (gamepad1.y) target = 1200;
            if (gamepad1.a) target = 0;

            double dt = timer.seconds();
            timer.reset();

            double position = arm.getCurrentPosition();
            double error = target - position;

            integralSum += error * dt;
            if (kI != 0) {
                double limit = MAX_I_POWER / kI;
                integralSum = Range.clip(integralSum, -limit, limit);
            }

            double derivative = (dt > 0) ? (error - lastError) / dt : 0;
            lastError = error;

            double power = kP * error + kI * integralSum + kD * derivative;
            arm.setPower(Range.clip(power, -1.0, 1.0));

            telemetry.addData("Target", target);
            telemetry.addData("Position", position);
            telemetry.addData("Power", "%.2f", power);
            telemetry.update();
        }
    }
}
```

The integral sum is clamped so the integral term cant add more than `MAX_I_POWER`. Without that, a mechanism held against a hard stop keeps building up error and overshoots hard once it is free.

`dt` is measured each loop with `ElapsedTime` instead of assumed, so the math stays correct when the loop time changes. See [Understanding Loop Times](/software/software-loop-times).

The output is in motor power, so the gains are small when the error is in encoder ticks.

## Tuning

1. Set `kI` and `kD` to zero.
2. Raise `kP` until the mechanism reaches the target and oscillates a little.
3. Raise `kD` until the oscillation stops.
4. If the mechanism settles short of the target, add a small `kI`. Most mechanisms do not need it. For an arm or slide, a gravity term usually fixes this better, see [Feedforward Control](/software/feed-forward).

Use [FTC Dashboard](/software/ftc-dashboard) to change the gains without redeploying.
