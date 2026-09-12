---
title: PID Control
panelCategory: "Control"
date: 2026-03-28
description: A comprehensive guide to proportional, integral, and derivative control in FTC.
tags: [completed, software, intermediate, control, completed]
author: Ishaan Desai
published: true
---

<script>
    import PIDVisualizer from '$lib/components/PIDVisualizer.svelte';
</script>

PID (Proportional, Integral, Derivative) control is the most common control algorithm used in FTC for precise movements, whether it's for a drivetrain, an arm, or a slide.

<div class="tuner-callout" style="padding: 1.5rem; background: rgba(116, 215, 237, 0.05); border-radius: var(--radius-md); border-left: 4px solid var(--accent-cyan); margin: 2rem 0;">
    <p> 🚀 <strong>Try our new full-page <a href="/simulators/pid">PID Simulator</a></strong> for a deeper understanding of PID!</p>
</div>

<PIDVisualizer />

---

## The Three Components

### 1. Proportional (P)
The **Proportional** term is the simplest. It produces an output that is proportional to the current error.

- **Error** = `Target - Current Position`
- **Output** = `Kp × Error`

If you are far from the target, the output is large. As you get closer, the output decreases.

### 2. Integral (I)
The **Integral** term accounts for the accumulation of past errors. If the proportional term isn't enough to reach the target (due to friction or gravity), the Integral term will slowly increase the output over time until the target is reached.

- **Output** = `Kp × Error + Ki × Σ Error × dt`

### 3. Derivative (D)
The **Derivative** term predicts future error based on the current rate of change. It acts as a "brake," dampening the movement to prevent overshoot and oscillations.

- **Output** = `Kp × Error + Kd × d(Error)/dt`

---

## Implementation in Java

Here is a simple PID class you can use in your FTC code:

```java
public class PIDController {
    private double Kp, Ki, Kd;
    private double target;
    private double integralSum = 0;
    private double lastError = 0;
    private ElapsedTime timer = new ElapsedTime();

    public PIDController(double Kp, double Ki, double Kd) {
        this.Kp = Kp;
        this.Ki = Ki;
        this.Kd = Kd;
    }

    public double calculate(double currentPosition) {
        double error = target - currentPosition;
        double derivative = (error - lastError) / timer.seconds();
        integralSum += error * timer.seconds();

        // Anti-windup for the integral term
        if (Math.abs(error) < 1) { // Threshold
             integralSum = 0;
        }

        double output = (Kp * error) + (Ki * integralSum) + (Kd * derivative);

        lastError = error;
        timer.reset();

        return output;
    }

    public void setTarget(double target) {
        this.target = target;
    }
}
```

---

## Tuning Your PID

Tuning is the process of finding the right values for $K_p$, $K_i$, and $K_d$.

1. **Set K_i and K_d to zero.**
2. **Increase K_p** until the system starts to oscillate steadily.
3. **Increase K_d** to dampen the oscillations and reach the target quickly without overshooting.
4. **Increase K_i** only if you have a steady-state error (the robot stops just before the target).
