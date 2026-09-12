---
title: "Pedro Pathing: How to Tune"
panelCategory: "Pedro Pathing"
date: 2026-03-28
description: Step-by-step guide to tuning your robot for Pedro Pathing.
tags: [completed, software, intermediate]
author: Ishaan Desai
published: true
---

# Tuning Your Robot for Pedro Pathing

Tuning is the most critical part of setting up Pedro Pathing. A well-tuned robot will follow paths with high precision, while a poorly tuned one will struggle.

## The Tuning Process

### 1. Drivetrain Tuning

- **Max Velocity:** Find the maximum speed your robot can achieve while maintaining control.
- **Acceleration:** Find the maximum acceleration the robot should use for smooth movements.

### 2. Odometry Calibration

- **Encoder Resolution:** Ensure your odometry pods are providing the correct number of pulses per unit of distance.
- **Track Width:** Precisely measure the physical distance between your tracking wheels.

### 3. PID and Feedforward Tuning

- **Follower PID:** Tune the PID controllers within Pedro to maintain path accuracy.
- **Feedforward Constants:** Find the _K_s_, _K_v_, and _K_a_ values for your drivetrain motors.

## Using Panels

Pedro Pathing includes a built-in dashboard called **Panels** for real-time tuning and visualization.

1.  Connect to your robot's Control Hub via Wi-Fi.
2.  Open Panels in your web browser.
3.  Use the tuning tools to adjust constants and see the robot's performance live.

## Common Issues

- **Overshooting:** Increase K_d or decrease K_p in your follower PID.
- **Inconsistent Paths:** Check your odometry hardware for any mechanical issues.
- **Slow Response:** Increase your K_p or K_v values.
