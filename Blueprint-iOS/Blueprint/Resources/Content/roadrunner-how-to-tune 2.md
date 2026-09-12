---
title: Roadrunner How To Tune
panelCategory: "Roadrunner"
date: 2026-03-28
description: A step-by-step walkthrough of every Road Runner tuning OpMode, in order, with what "good" looks like on each graph.
tags: [software, manual, beginner, road runner, completed]
author: Blueprint
published: true
---

# Roadrunner How To Tune

> Tuning is not optional. Every constant Road Runner uses to predict your robot's motion comes from these OpModes - skip a step and every trajectory after it will be wrong in a way that's hard to diagnose.

---

## Before You Start

Tuning happens **in order**. Each OpMode either measures a physical constant used by the next one, or validates the constants you already found. Do not skip ahead.

```
1. Drive constants (inPerTick, track width geometry)
       ↓
2. ForwardRampLogger / LateralRampLogger  →  kS, kV
       ↓
3. AngularRampLogger  →  trackWidthTicks
       ↓
4. ManualFeedforwardTuner  →  refine kV, add kA
       ↓
5. LocalizationTest  →  verify odometry is honest
       ↓
6. FollowerPIDTuner (ManualFeedbackTuner)  →  path-following gains
       ↓
7. SplineTest  →  confirm everything together
```

All of these OpModes live in the [quickstart](https://github.com/acmerobotics/road-runner-quickstart) under `tuning/`, and every tunable constant is exposed through `@Config` - so tune with **FTC Dashboard** open. If you haven't set that up yet, see the [FTC Dashboard guide](/) first.

---

## 1. Set Physical Constants First

Before running any OpMode, fill in the values in your `MecanumDrive.Params` (or `TankDrive.Params`) that you can measure directly with calipers/a tape measure:

- **`inPerTick`** - inches traveled per encoder tick. Leave at `1` for now; the push test below finds this for you.
- **Odometry pod / wheel positions** - if you're on dead wheels, measure and enter the `par0`, `par1`, and `perp` offsets from the robot's center in the localizer params.

> **Note:** If you're using drive-encoder localization instead of dead wheels, you can skip pod offsets entirely - see the [Localization guide](/) for the difference.

---

## 2. Forward Push Test / Ramp Logger

**Purpose:** find `inPerTick` (and `kS`, `kV` if you're on dead wheels using `ForwardRampLogger`).

- **`ForwardPushTest`** - for robots without dead wheels: you physically push the robot forward a known distance and it reports ticks traveled. Divide distance by ticks to get `inPerTick`.
- **`ForwardRampLogger`** - for dead-wheel robots: the robot slowly ramps up drive power in a straight line while logging velocity vs. power.

**What good output looks like:** a clean, mostly-linear scatter plot of velocity vs. power with a tight regression line. The slope gives `kV`; the y-intercept gives `kS`.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Scattered, noisy points | Wheels slipping, loose belts, or dead wheel not touching the floor | Check mechanical slop before re-running |
| Curve instead of a line | Ramp too fast, or battery sagging mid-run | Charge battery fully, re-run |
| Negative or near-zero `kV` | Wrong direction wiring or reversed motor | Check motor directions in the drive class |

Repeat with **`LateralRampLogger`** to get `lateralInPerTick` for mecanum strafing.

---

## 3. Angular Ramp Logger

**Purpose:** find `trackWidthTicks` - the effective distance between your left and right wheels (or dead wheels), used to convert wheel velocities into angular velocity.

`AngularRampLogger` spins the robot in place while ramping power, logging both the ramp regression and a track-width regression.

**What good output looks like:** the track-width regression should also be a clean line. A track width wildly different from your physically-measured wheelbase width usually means dead-wheel spacing is entered wrong, not that the math is broken.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Robot drifts off-heading during straight-line trajectories later | `trackWidthTicks` too high or low | Re-measure dead wheel/wheel spacing, re-run |
| Robot spins faster/slower than commanded | Wrong `trackWidthTicks` | Adjust proportionally and re-test |

---

## 4. Manual Feedforward Tuner

**Purpose:** fine-tune `kS` and `kV`, and add `kA` (acceleration feedforward) - none of the ramp loggers measure `kA` directly.

`ManualFeedforwardTuner` drives the robot forward and backward repeatedly using your current feedforward constants and overlays **reference velocity (`vref`)** against **actual velocity (`v0`)** on the Dashboard graph.

**What good output looks like:** the `v0` curve tracks `vref` almost exactly, including during the acceleration ramps at the start/end of each cycle.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Actual velocity lags behind reference during acceleration | `kA` too low | Increase `kA` |
| Actual velocity overshoots reference, oscillates | `kA` too high | Decrease `kA` |
| Constant offset between curves | `kS`/`kV` off from the ramp test | Nudge `kS`/`kV` slightly, re-test |

---

## 5. Localization Test

**Purpose:** verify your localizer (dead wheels or drive encoders) reports **pose** - `x`, `y`, and heading - that matches reality, before you tune path-following on top of bad position data.

Run **`LocalizationTest`**, then manually drive the robot around with a gamepad:

- Push it in a straight line - does the reported `x`/`y` match a tape measure?
- Rotate it exactly one full turn by hand or with a jig - does heading return to (approximately) where it started?

**What good output looks like:** position and heading track your physical motion closely, with drift under roughly 1 inch and 1-2 degrees after a full lap around the field perimeter.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Heading drifts steadily even when driving straight | Wrong `trackWidthTicks`, or a dead wheel slipping | Re-run `AngularRampLogger`; check pod pressure against the floor |
| Position scales wrong (robot reports moving 2x the real distance) | Wrong `inPerTick` | Re-run the push test/ramp logger |
| Reported heading jumps or is `NaN` | Bad encoder wiring, disconnected dead wheel, or wrong port in config | Check hardware config names (`par0`, `par1`, `perp`) match your code |
| Position drifts sideways during straight pushes | Perpendicular ("perp") pod offset measured wrong | Re-measure and re-enter offset from robot center |

Do **not** move on until this step is clean - every later tuning step assumes localization is trustworthy.

---

## 6. Follower PID Tuner (Feedback Tuning)

**Purpose:** tune the feedback controller that corrects the robot back onto the path when it's pushed off by friction, battery sag, or bumps.

Run **`FollowerPIDTuner`** (also called `ManualFeedbackTuner` in some quickstart versions). It repeatedly drives a short forward/backward trajectory and graphs position/velocity error over time.

**What good output looks like:** a fast, clean convergence to near-zero error with no sustained oscillation.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Overshoots the target, oscillates before settling | `axialGain`/`lateralGain`/`headingGain` too high | Decrease the relevant gain |
| Slow to correct, robot "wanders" back to the path | Gains too low | Increase the relevant gain |
| Corrects along the path direction fine but drifts sideways | `lateralGain` too low relative to `axialGain` | Increase `lateralGain` |
| Heading overshoots on turns | `headingGain` too high | Decrease `headingGain` |

Raise gains gradually - just like PID tuning elsewhere, you want the largest gain that doesn't cause visible oscillation, then back off slightly.

---

## 7. Spline Test

**Purpose:** the final check. `SplineTest` commands a curved spline path and shows actual vs. desired trajectory on the field overlay in Dashboard.

**What good output looks like:** the actual path (drawn live) hugs the planned spline closely from start to finish, with the robot arriving at the correct final heading.

| Symptom | Likely Cause | Fix |
|---|---|---|
| Robot cuts corners on curves | Velocity/acceleration constraints too aggressive for feedback gains to correct | Lower `maxWheelVel`/`maxProfileAccel`, or increase feedback gains |
| Robot overshoots then snaps back onto the spline | Feedback gains too high | Revisit step 6 |
| Path is smooth but consistently offset to one side | Localization drift (step 5 wasn't actually clean) | Re-check `LocalizationTest` |

If `SplineTest` looks good, you're done - move on to [building your first autonomous](/).

---

> **Common mistake:** re-tuning feedback gains to "fix" a problem that's actually bad localization. If your robot is inconsistent between runs, always re-check `LocalizationTest` before touching PID gains again.
