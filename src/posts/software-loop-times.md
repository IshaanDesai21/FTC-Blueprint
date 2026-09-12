---
title: Understanding Loop Times
panelCategory: "Control"
date: 2026-07-01
description: What loop time is, what makes it slow, and how to measure it.
tags: [software, intermediate, completed]
author: Blueprint
published: true
---

Loop time is how long one pass through `while (opModeIsActive())` takes. A slower loop means more delay between a stick input or a sensor change and the robot reacting to it. For PID and other feedback control, the loop rate limits how well the controller can hold a target.

## What slows a loop

- **Blocking calls.** `sleep(500)` stops everything for half a second. Nothing is read and nothing is updated.
- **Hardware reads.** Every encoder read, sensor read, and `setPower()` call is a command to the hub. I2C sensors like the color and distance sensors are slower than encoder reads. Reading the same device twice in one loop costs twice.
- **Telemetry.** `telemetry.update()` sends data to the Driver Station. Calling it more then once per loop, or sending a lot of lines, adds up.
- **Object creation in the loop.** Creating new objects every pass triggers garbage collection pauses.

## Measuring

```java
ElapsedTime loopTimer = new ElapsedTime();

while (opModeIsActive()) {
    // rest of the loop

    telemetry.addData("Loop Time (ms)", loopTimer.milliseconds());
    loopTimer.reset();
    telemetry.update();
}
```

Watch the number as you add or remove code to see what is expensive.

## Why it matters for controllers

PID and motion profiles use `dt`, the time since the last update. Measure it with `ElapsedTime` instead of assuming a fixed value, so the controller stays correct when the loop time changes. A measured `dt` does not fix a loop that is simply too slow to react, it only keeps the math consistent.

## Keeping loops fast

- Use [bulk reads](/software/bulkreads) so all encoder and digital reads on a hub happen in one command.
- Read each sensor once per loop and store the value.
- Replace `sleep()` with `ElapsedTime` checks or a state machine.
- Call `telemetry.update()` once, at the end of the loop.
- Only write to a motor or servo when the value changed. The SDK already skips repeated identical writes for motors, but skipping the call still saves time.

## Mistakes

- **Never measuring.** Add the loop time line to telemetry during development so slowdowns are visible.
- **Adding `sleep()` to fix timing.** It blocks the whole OpMode. Use a timer or a state.
- **Assuming it only matters for autonomous.** Driver response and sensor safety checks depend on the loop too.
