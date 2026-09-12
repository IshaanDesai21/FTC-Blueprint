---
title: Feedforward Control
panelCategory: "Control"
date: 2026-05-22
description: Adding feedforward terms to hold position against gravity and track velocity.
tags: [completed, software, intermediate, control]
author: Blueprint
published: true
---

PID reacts to error after it appears. Feedforward adds the power you already know the mechanism needs, before any error builds up. The two are used together.

## Why it matters

An arm or slide under gravity sags below its target with PID alone, until the integral term winds up enough to lift it. That takes time and the mechanism feels slow. Adding a constant power to counter gravity removes most of that error up front, and PID only has to correct what is left.

## The terms

**Velocity (kV).** Power per unit of velocity. Multiply the target velocity by kV to get the power that roughly produces that speed.

**Static (kS).** The minimum power that makes the mechanism move at all. Applied in the direction of motion.

**Gravity (kG).** The power needed to hold the mechanism still against gravity. For a linear slide it is a constant. For a rotating arm it depends on angle: `kG * cos(angle)` where the angle is measured from horizontal.

**Acceleration (kA).** Power per unit of acceleration. Most FTC mechanisms do not need it.

## Implementation

```java
public class SlideFeedforward {
    private double kS, kG, kV, kA;

    public SlideFeedforward(double kS, double kG, double kV, double kA) {
        this.kS = kS;
        this.kG = kG;
        this.kV = kV;
        this.kA = kA;
    }

    public double calculate(double velocity, double acceleration) {
        return kS * Math.signum(velocity) + kG + kV * velocity + kA * acceleration;
    }
}
```

For an arm, replace `kG` with `kG * Math.cos(angleRadians)`.

## Combining with PID

```java
double ff = feedforward.calculate(targetVelocity, targetAccel);
double fb = pid.calculate(currentPosition);

motor.setPower(ff + fb);
```

If you only want to hold position, pass zero velocity and acceleration. The feedforward then reduces to `kG`.

## Tuning

1. **kG.** Set everything else to zero. Raise kG until the mechanism holds still at a mid-range position without PID. For an arm, do this with the arm horizontal.
2. **kS.** Raise kS until the mechanism just starts moving from rest.
3. **kV.** Command a constant velocity and adjust kV until the measured velocity matchs the target.
4. Add PID on top and tune it as described in [PID Control](/software/pid-control).

Road Runner has its own tuning routines for the drivetrain feedforward terms. Mechanisms are tuned by hand.
