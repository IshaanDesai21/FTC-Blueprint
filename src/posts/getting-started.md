---
title: Getting Started
panelCategory: "Basics"
date: 2026-05-15
description: What FTC is and what you need before writing code.
tags: [completed, software, rookie guide, beginner]
author: Blueprint
published: true
---

## What FTC is

FIRST Tech Challenge is a robotics competition for students in grades 7 through 12. Each season has a new game. Teams build and program a robot to play it, and compete in alliances of two teams against another alliance.

## The control system

The **Control Hub** runs your code and connects to motors, servos, and sensors. The **Driver Station** is an Android phone or a REV Driver Hub that connect to the Control Hub over Wi-Fi and runs the Driver Station app. Gamepads plug into the Driver Station.

An **Expansion Hub** adds more ports and connects to the Control Hub with a cable.

## Programming options

The SDK supports three ways to write code:

- **Blocks**, a drag-and-drop editor in the browser.
- **OnBot Java**, a Java editor in the browser.
- **Android Studio**, a full Java IDE on your computer.

This site covers Android Studio. It is the option that works with libraries like Road Runner and FTC Dashboard, and it is what most teams end up using. See [Android Studio Setup](/software/basics-android-studio) to install it.

## Things to read

- The **Game Manual** for the current season. It defines what the robot can and cannot do. Read it before you build anything.
- The [FtcRobotController](https://github.com/FIRST-Tech-Challenge/FtcRobotController) repository, which has the SDK and sample OpModes in the `FtcRobotController/src/main/java/org/firstinspires/ftc/robotcontroller/external/samples` folder.

## Where to start

1. Install Android Studio and open the SDK.
2. Wire and configure a drivetrain. See [Wiring and Configuration](/software/basics-wiring).
3. Write a TeleOp that drives. See [Teleop Beginner](/software/teleop-beginner).
4. Once that works, move to sensors and then autonomous.
