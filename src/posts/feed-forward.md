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

## In code

The SDK has no feedforward class. The terms are a few lines of math added to the power you send the motor.

```java
static final double kS = 0.0;
static final double kG = 0.1;
static final double kV = 0.0;
```

For a linear slide holding or moving at a target velocity:

```java
double feedforward = kG + kS * Math.signum(targetVelocity) + kV * targetVelocity;
```

For an arm, gravity depends on the angle, so scale `kG` by the cosine of the angle from horizontal:

```java
static final double TICKS_PER_DEGREE = 537.7 * 5.0 / 360.0;   // motor ticks per rev * gear reduction / 360
static final int    HORIZONTAL_TICKS = 300;                   // encoder reading with the arm level

double angle = Math.toRadians((arm.getCurrentPosition() - HORIZONTAL_TICKS) / TICKS_PER_DEGREE);
double feedforward = kG * Math.cos(angle);
```

Measure `HORIZONTAL_TICKS` by holding the arm level and reading the encoder on telemetry. Change the gear reduction to match your arm.

## Combining with PID

Add the feedforward to the output of the PID loop from [PID Control](/software/pid-control).

```java
double position = arm.getCurrentPosition();
double error = target - position;

double pid = kP * error + kI * integralSum + kD * derivative;
double angle = Math.toRadians((position - HORIZONTAL_TICKS) / TICKS_PER_DEGREE);
double feedforward = kG * Math.cos(angle);

arm.setPower(Range.clip(pid + feedforward, -1.0, 1.0));
```

If you only want to hold position, the target velocity is zero and the feedforward reduces to the gravity term.

## Tuning

1. **kG.** Set everything else to zero. Raise kG until the mechanism holds still at a mid-range position without PID. For an arm, do this with the arm horizontal.
2. **kS.** Raise kS until the mechanism just starts moving from rest.
3. **kV.** Command a constant velocity and adjust kV until the measured velocity matchs the target.
4. Add PID on top and tune it as described in [PID Control](/software/pid-control).

Road Runner has its own tuning routines for the drivetrain feedforward terms. Mechanisms are tuned by hand.
