---
title: FTC Dashboard & Live PID Tuning
date: 2026-04-05
panelCategory: "Miscellaneous"
description: Tune your robot's PID controller in real time using FTC Dashboard - No rebuilding required
tags: ["intermediate", "pid", "dashboard", "completed", "software"]
author: Ishaan Desai
published: true
---

# FTC Dashboard & PID Live Tuning

> Dial in your robot's motion without touching Android Studio - change constants live, graph your error in real time, and lock in values that actually work.

---

## What Is FTC Dashboard?

FTC Dashboard is a browser-based tool that connects to your Control Hub over Wi-Fi. It lets you:

- **Edit variables live** while your OpMode is running
- **Graph telemetry** (error, position, power) in real time
- **View a field overlay** of your robot's position

**To connect:** join the Control Hub's Wi-Fi network, then open `http://192.168.43.1:8080/dash` in your browser.

---

## Installation

> **Using the Road Runner quickstart?** FTC Dashboard is already included, so skip this section entirely.

If you're on a standard FTC project, open `build.dependencies.gradle` (in the root of your project, **not** `TeamCode/build.gradle`) and add two lines:

```gradle
// In the repositories block:
maven { url = 'https://maven.brott.dev/' }

// In the dependencies block:
implementation 'com.acmerobotics.dashboard:dashboard:0.5.1'
```

It should look roughly like this when done:

```gradle
repositories {
    maven { url = 'https://maven.brott.dev/' }  // add this
    // ... other repos
}

dependencies {
    implementation 'com.acmerobotics.dashboard:dashboard:0.5.1'  // add this
    // ... other dependencies
}
```

Then **sync Gradle** in Android Studio (the elephant icon, or File → Sync Project with Gradle Files). Check [acmerobotics.github.io/ftc-dashboard](https://acmerobotics.github.io/ftc-dashboard/gettingstarted) for the latest version number before adding it.

---

## How `@Config` Works

To make a variable tunable from the Dashboard, two things must be true:

1. The **class** is annotated with `@Config`
2. The **variable** is declared `public static`

```java
import com.acmerobotics.dashboard.config.Config;
import com.qualcomm.robotcore.hardware.PIDFCoefficients;

@Config
public class LiftConstants {
    public static PIDFCoefficients PIDF = new PIDFCoefficients(0.05, 0, 0.002, 0);
    public static int TARGET_TICKS = 800;
}
```

### Why `public static`?

Static variables live on the **class itself**, not on any object instance. When Dashboard updates a value, it writes directly to that memory location - and since your running code reads from the same place, the change takes effect **instantly** with no restart needed.

### Why `PIDFCoefficients`?

Instead of four separate `double` fields, the FTC SDK provides `PIDFCoefficients` - a single object with `.p`, `.i`, `.d`, and `.f` fields built in. Dashboard knows how to display and edit each field individually, so you get a clean set of sliders with no extra boilerplate.

---

## Organizing Your Constants

Keep all tunable values in a dedicated constants file. This keeps OpModes clean and gives you one place to look when something needs adjusting.

```java
@Config
public class RobotConstants {

    public static class Lift {
        public static PIDFCoefficients PIDF = new PIDFCoefficients(0.05, 0, 0.002, 0);
        public static int TARGET_TICKS = 800;
    }

    public static class Arm {
        public static PIDFCoefficients PIDF = new PIDFCoefficients(0.03, 0, 0.001, 0);
        public static double MAX_POWER = 0.8;
    }
}
```

Access coefficients anywhere with `RobotConstants.Lift.PIDF.p`, `.d`, etc.

---

## Understanding PD Control

For most FTC mechanisms, **P and D are all you need.** The integral term (I) sounds useful in theory but causes more problems than it solves in practice - windup, instability, and oscillation that's hard to debug. Also mainly, the loop times decrease a lot so leave it at zero.

| Term | What It Does | Too High → | Too Low → |
|------|-------------|-----------|----------|
| **P** (Proportional) | Pushes toward target based on current error | Oscillates, overshoots | Slow, never fully reaches target |
| **D** (Derivative) | Dampens motion as error shrinks | Jerky, erratic | Overshoots, takes long to settle |

**F** (feedforward) is for counteracting a constant force like gravity. This is useful on lifts and arms, but tune P and D first.

---

## Full Example: Live-Tunable Lift PID

This OpMode reads `PIDF` and `TARGET_TICKS` from the Dashboard in real time and graphs the error so you can watch it converge.

```java
package org.firstinspires.ftc.teamcode;

import com.acmerobotics.dashboard.FtcDashboard;
import com.acmerobotics.dashboard.config.Config;
import com.acmerobotics.dashboard.telemetry.MultipleTelemetry;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.PIDFCoefficients;
import com.qualcomm.robotcore.util.ElapsedTime;

@Config
class LiftConstants {
    public static PIDFCoefficients PIDF = new PIDFCoefficients(0.05, 0, 0.002, 0);
    public static int TARGET_TICKS = 800;
}

@TeleOp(name = "Lift PID Tuner")
public class LiftPIDTuner extends LinearOpMode {

    @Override
    public void runOpMode() {
        DcMotor lift = hardwareMap.get(DcMotor.class, "liftMotor");
        lift.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        lift.setMode(DcMotor.RunMode.RUN_WITHOUT_ENCODER);

        // Sends telemetry to both Driver Station and Dashboard
        MultipleTelemetry tel = new MultipleTelemetry(
            telemetry, FtcDashboard.getInstance().getTelemetry()
        );

        ElapsedTime timer = new ElapsedTime();
        double lastError = 0;
        double integralSum = 0;

        waitForStart();
        timer.reset();

        while (opModeIsActive()) {
            double dt = timer.seconds();
            timer.reset();

            int currentPos = lift.getCurrentPosition();
            double error = LiftConstants.TARGET_TICKS - currentPos;

            // Integral - clamped, but leave kI = 0 unless you have a specific reason
            integralSum = Math.max(-1, Math.min(1, integralSum + error * dt));

            // Derivative
            double derivative = (error - lastError) / dt;
            lastError = error;

            // PIDF output - read live from Dashboard each loop
            PIDFCoefficients c = LiftConstants.PIDF;
            double power = (c.p * error)
                         + (c.i * integralSum)
                         + (c.d * derivative)
                         + (c.f * Math.signum(error));

            lift.setPower(Math.max(-1, Math.min(1, power)));

            // Dashboard graphs these automatically
            tel.addData("Target", LiftConstants.TARGET_TICKS);
            tel.addData("Position", currentPos);
            tel.addData("Error", error);
            tel.addData("Power", power);
            tel.update();
        }
    }
}
```

### What to watch on the graph

| Pattern | Meaning | Fix |
|---------|---------|-----|
| Slowly creeps to target | `P` too low | Increase `P` |
| Bounces back and forth | `P` too high | Decrease `P` |
| Overshoots before settling | `D` too low | Increase `D` |
| Erratic, noisy movement | `D` too high | Decrease `D` |
| Stops just short of target (lift only) | Gravity load | Add a small `F` value |

---

## Tuning Workflow

```
1. Set D = 0, F = 0. Tune P alone first.
       ↓
2. Keep Raising P until it oscillates very slightly, or very slight overshoot. Then decrease it extremely slightly.
       ↓
3. Raise D to dampen overshoot and smooth out the approach.
       ↓
4. (Lifts/arms only) If it consistently falls slightly short at rest,
   add a small F to counteract gravity. A little goes a long way.
       ↓
5. Done when the error graph shows a clean, fast drop to ~0 with no bounce.
```

---

## WARNING: Dashboard changes are temporary.
Once you find values that work, copy them back into your code in Android Studio - they **will not be saved** when the robot restarts.

### Tip
Use `MultipleTelemetry` (shown above) instead of calling `FtcDashboard.getInstance().getTelemetry()` directly. It logs to both the Driver Station and the Dashboard graph simultaneously, with one line of code.