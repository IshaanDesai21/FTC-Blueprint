---
title: Telemetry and Debugging Best Practices
panelCategory: "Basics"
date: 2026-06-30
description: Finding problems with telemetry, isolation, and Logcat.
tags: [software, beginner, completed]
author: Blueprint
published: true
---

## Telemetry

Telemetry is text sent from the robot to the Driver Station screen.

```java
telemetry.addData("Motor Power", motor.getPower());
telemetry.addData("Distance", distanceSensor.getDistance(DistanceUnit.CM));
telemetry.update();
```

It is the fastest way to see what the code thinks is happening.

## Debugging with telemetry

Print the values that should explain the behavior, then compare them to what you expected.

- An arm is not reaching its position. Print the target and the current encoder value. If they match, the problem is mechanical. If they do not, the problem is in the code.
- A color sensor is not detecting a piece. Print the raw reading. That tells you if the sensor sees anything or if the threshold is wrong.
- A button does nothing. Print the gamepad value. If it is true and nothing happens, the problem is after the read.

Adding two telemetry lines for the specific thing you are chasing is faster than reading the whole file.

## Isolating the problem

- **One mechanism at a time.** Write a small OpMode that only runs the mechanism in question.
- **Bisect.** Comment out half the logic and see if the rest works. Narrow it down from there.
- **Check the value, don't assume it.** A lot of bugs are a value that was not what the programmer thought.
- **Check hardware first.** A loose cable, a motor in the wrong port, or a wrong name in the configuration looks like a code bug.

## Logcat

Telemetry disappears when the OpMode stops. If the OpMode crashed, the stack trace is in Logcat. In Android Studio, open the Logcat tab while the Control Hub is connected over ADB. Filter by `RobotCore` or by your class name.

`RobotLog.d("message")` writes to Logcat from your code. `System.out.println()` also shows up there. Use these for values that are to detailed for the Driver Station screen.

## FTC Dashboard

For graphs of values over time, and for changing constants without redeploying, use [FTC Dashboard](/software/ftc-dashboard).

## Intermittent bugs

- Log the normal case too, so good runs and bad runs can be compared.
- Write down the conditions when it happens: battery voltage, what the driver pressed, where the robot was.
- If it happens at low battery, the hub may be browning out under load. Check the voltage in telemetry.

```java
VoltageSensor battery = hardwareMap.voltageSensor.iterator().next();
telemetry.addData("Battery", "%.2f V", battery.getVoltage());
```

## Mistakes

- **Removing debug telemetry too soon.** Keep a few key values in place. They help when something regresses.
- **Debugging only on the field.** Test mechanisms on a bench where only one thing is running.
