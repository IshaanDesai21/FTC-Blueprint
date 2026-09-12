---
title: FTC Dashboard & Live PID Tuning
date: 2026-06-01
panelCategory: "Miscellaneous"
description: Changing constants and graphing telemetry from a browser while the OpMode runs.
tags: [intermediate, pid, dashboard, completed, software]
author: Blueprint
published: true
---

FTC Dashboard is a web page served by the robot. It lets you edit `public static` fields while an OpMode runs, graph telemetry, and draw on a field view. Official docs are at [acmerobotics.github.io/ftc-dashboard](https://acmerobotics.github.io/ftc-dashboard/).

To open it, connect to the Control Hub's Wi-Fi and go to `http://192.168.43.1:8080/dash`.

## Installation

The Road Runner quickstart already includes it. For a plain FtcRobotController project, open `build.dependencies.gradle` in the project root and add the repository and the dependency. Get the current version number from the [getting started page](https://acmerobotics.github.io/ftc-dashboard/gettingstarted).

```gradle
repositories {
    maven { url = 'https://maven.brott.dev/' }
}

dependencies {
    implementation 'com.acmerobotics.dashboard:dashboard:VERSION'
}
```

Then sync Gradle.

## Tunable variables

A field shows up in the dashboard when:

1. The class is annotated with `@Config`.
2. The field is `public static`.

```java
import com.acmerobotics.dashboard.config.Config;
import com.qualcomm.robotcore.hardware.PIDFCoefficients;

@Config
public class LiftConstants {
    public static PIDFCoefficients PIDF = new PIDFCoefficients(0.05, 0, 0.002, 0);
    public static int TARGET_TICKS = 800;
}
```

Static fields belong to the class, not an instance, so when the dashboard writes a new value the running OpMode reads it on its next loop.

`PIDFCoefficients` is an SDK class with `p`, `i`, `d`, and `f` fields. The dashboard shows each one as its own editable value.

Put the constants class in its own file. Keep all tunable values in one or two `@Config` classes so there is one place to look.

## Telemetry to the dashboard

`FtcDashboard.getInstance().getTelemetry()` returns a `Telemetry` that sends to the dashboard. `MultipleTelemetry` sends to both the dashboard and the Driver Station at once.

```java
MultipleTelemetry tel = new MultipleTelemetry(telemetry, FtcDashboard.getInstance().getTelemetry());
```

Numeric values sent this way are graphed in the dashboard's graph view.

## Example: lift tuner

```java
package org.firstinspires.ftc.teamcode;

import com.acmerobotics.dashboard.FtcDashboard;
import com.acmerobotics.dashboard.telemetry.MultipleTelemetry;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.PIDFCoefficients;
import com.qualcomm.robotcore.util.ElapsedTime;

@TeleOp(name = "Lift PID Tuner")
public class LiftPIDTuner extends LinearOpMode {

    @Override
    public void runOpMode() {
        DcMotor lift = hardwareMap.get(DcMotor.class, "liftMotor");
        lift.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        lift.setMode(DcMotor.RunMode.RUN_WITHOUT_ENCODER);

        MultipleTelemetry tel = new MultipleTelemetry(telemetry, FtcDashboard.getInstance().getTelemetry());

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

            integralSum = Math.max(-1, Math.min(1, integralSum + error * dt));
            double derivative = (error - lastError) / dt;
            lastError = error;

            PIDFCoefficients c = LiftConstants.PIDF;
            double power = c.p * error + c.i * integralSum + c.d * derivative + c.f;

            lift.setPower(Math.max(-1, Math.min(1, power)));

            tel.addData("Target", LiftConstants.TARGET_TICKS);
            tel.addData("Position", currentPos);
            tel.addData("Error", error);
            tel.addData("Power", power);
            tel.update();
        }
    }
}
```

`c.f` here is a constant added to hold the lift against gravity. `LiftConstants.PIDF` is read every loop, so changes in the dashboard apply immediately.

## Tuning

1. Set `i`, `d`, and `f` to zero. Raise `p` until the lift reaches the target with a small oscillation.
2. Raise `d` until the oscillation stops.
3. If the lift settles below the target, raise `f` until it holds.
4. Leave `i` at zero unless there is still a steady error after `f`.

Watch the Error line in the graph. The goal is a fast drop to zero with no bounce.

| Graph | Cause | Change |
|---|---|---|
| Slow approach, never quite reaches | `p` too low | Raise `p` |
| Oscillates around target | `p` too high | Lower `p` |
| Overshoots then settles | `d` too low | Raise `d` |
| Jittery power | `d` too high | Lower `d` |
| Settles short | Gravity | Raise `f` |

## Values are not saved

Dashboard edits live in memory only. When the robot restarts their gone. Copy the final numbers back into the source file.
