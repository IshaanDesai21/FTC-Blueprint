---
title: Feedforward Control
panelCategory: "Control"
date: 2026-03-28
description: A practical guide to feedforward control for FTC mechanisms.
tags: [completed, software, intermediate, control, completed]
author: Ishaan Desai
published: true
---

<script>
    import FeedforwardVisualizer from '$lib/components/FeedforwardVisualizer.svelte';
</script>

Feedforward control is a pro-active way of controlling mechanisms. Unlike PID, which reacts to errors, Feedforward uses a model of the physical system to pre-calculate the power needed to achieve a specific movement.

<div class="tuner-callout">
    <p> <strong>Try our <a href="/simulators/feedforward">Feedforward + PID Simulator</a></strong> for a deeper understanding of Feedforward!</p>
</div>

<FeedforwardVisualizer />

## Why use Feedforward?

With PID alone, if you have gravity or friction (like an arm or linear slide), the mechanism will likely sag or drop. You would have to use a high K_i to compensate, which makes the robot slower to respond.

Feedforward calculates the exact amount of power needed to maintain a certain position (against gravity) or speed (against friction).

### 1. Velocity Feedforward (K_v)

This is the amount of power needed per unit of velocity.

- **Output** = _K_v_ × **target velocity**

### 2. Static Friction Feedforward (K_s)

This is the "voltage jump" needed to overcome friction and get the robot moving.

- **Output** = _K_s_ (sign stays consistent with direction)

### 3. Gravity Feedforward (K_g)

Crucial for arms and slides.

- **For a linear slide:** Constant K_g to hold the weight.
- **For a rotating arm:** K_g × cos(θ) where θ is the arm's angle.

## Implementation in FTC

Here is how you can implement a standard Feedforward calculation for a linear slide:

```java
public class SlideFeedforward {
    private double ks, kg, kv, ka;

    public SlideFeedforward(double ks, double kg, double kv, double ka) {
        this.ks = ks;
        this.kg = kg;
        this.kv = kv;
        this.ka = ka;
    }

    public double calculate(double velocity, double acceleration) {
        return (ks * Math.signum(velocity)) + kg + (kv * velocity) + (ka * acceleration);
    }
}
```

## Combined PID and Feedforward

In a real FTC robot, you should use **PID + Feedforward**. The Feedforward does the "heavy lifting" by getting you near the target, and the PID handles the small corrections.

```java
double ff_power = feedforward.calculate(target_vel, target_accel);
double pid_power = pid.calculate(current_position);

motor.setPower(ff_power + pid_power);
```

## Tuning Feedforward

If your robot has Roadrunner or Pedro Pathing, they come with built-in tuning tools for K_s and K_v for the drivetrain. For your custom mechanisms, start with K_s (the minimum power to move the mechanism), then K_v (the relation between power and steady velocity), and finally K_g (the power to hold it still).
