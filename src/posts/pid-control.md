---
title: PID Control
panelCategory: "Control"
date: 2026-05-28
description: Proportional, integral, and derivative control with a Java implementation and tuning steps.
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

**Proportional.** Output is `Kp * error`. Far from the target the output is large. Close to the target it is small. P alone usually stops short of the target or oscillates around it.

**Integral.** Output is `Ki * (sum of error over time)`. If the mechanism sits just below the target because of gravity or friction, the sum grows until the output is enough to close the gap.

**Derivative.** Output is `Kd * (rate of change of error)`. When the mechanism is moving toward the target quickly, this term pushes back and reduces overshoot.

The total output is the sum of the three.

## Java implementation

```java
import com.qualcomm.robotcore.util.ElapsedTime;

public class PIDController {
    private double kP, kI, kD;
    private double target;
    private double integralSum = 0;
    private double lastError = 0;
    private double maxIntegral = 1.0;
    private ElapsedTime timer = new ElapsedTime();

    public PIDController(double kP, double kI, double kD) {
        this.kP = kP;
        this.kI = kI;
        this.kD = kD;
    }

    public void setTarget(double target) {
        this.target = target;
    }

    public double calculate(double current) {
        double dt = timer.seconds();
        timer.reset();
        if (dt <= 0) dt = 0.001;

        double error = target - current;

        integralSum += error * dt;
        integralSum = Math.max(-maxIntegral, Math.min(maxIntegral, integralSum));

        double derivative = (error - lastError) / dt;
        lastError = error;

        return kP * error + kI * integralSum + kD * derivative;
    }
}
```

The integral sum is clamped so it cant grow without bound while the mechanism is blocked. Without that, the stored error keeps building and the mechanism overshoots hard once it is free.

Using it:

```java
PIDController armPid = new PIDController(0.005, 0, 0.0002);
armPid.setTarget(1200);

while (opModeIsActive()) {
    double power = armPid.calculate(armMotor.getCurrentPosition());
    armMotor.setPower(power);
}
```

The output is in motor power units, so the constants are small when the error is measured in encoder ticks.

## Tuning

1. Set `kI` and `kD` to zero.
2. Raise `kP` until the mechanism reaches the target and oscillates a little.
3. Raise `kD` until the oscillation stops.
4. If the mechanism settles short of the target, add a small `kI`. Most mechanisms do not need it.

Use [FTC Dashboard](/software/ftc-dashboard) to change the constants without redeploying.
