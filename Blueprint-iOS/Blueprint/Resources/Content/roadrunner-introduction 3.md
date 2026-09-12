---
title: Roadrunner Introduction
panelCategory: "Roadrunner"
date: 2026-03-28
description: The essential first steps for implementing Road Runner for advanced autonomous navigation in FTC.
tags: [software, manual, beginner, road runner]
author: Blueprint
published: true
---

# Roadrunner Introduction

Road Runner is the most powerful and widely used autonomous navigation library in FIRST Tech Challenge. It allows for advanced path following, localization, and trajectory generation.

---

## Why Road Runner?

- **Precision:** Road Runner uses odometry-based localization, which is far more accurate than plain drive-encoder dead reckoning.
- **Complexity:** Easily create complex paths like splines and strafing-intensive movements.
- **Speed:** Faster and more reliable than simple timer-based or sensor-limited auton.

---

## Prerequisites

Before you dive in, ensure your robot meets these hardware requirements:

### 1. Odometry
While Road Runner can work with basic drivetrain encoders, **three-wheel odometry** is strongly recommended for the best accuracy.

### 2. Control Hub
Ensure your REV Control Hub is updated to the latest firmware.

### 3. DriveTrain
Your drivetrain must be built solidly. Any mechanical slop or loose chains will make tuning much harder.

---

## Getting Started

The first step is to download the Road Runner quickstart project from the [official GitHub repository](https://github.com/acmerobotics/road-runner-quickstart).

Once you have the code, you'll need to go through a series of tuning OpModes to tell Road Runner about your robot's physics.

- **DriveVelocityTuner:** Find your robot's maximum velocity and acceleration.
- **LocalizationTest:** Ensure your odometry pods are reporting correctly.
- **FollowerPIDTuner:** Tune the "feedback" that keeps your robot on the path.

---

> **Tuning is everything.** A poorly tuned Road Runner will perform worse than a simple timer-based autonomous. Dedicate several hours to your initial tuning process.
