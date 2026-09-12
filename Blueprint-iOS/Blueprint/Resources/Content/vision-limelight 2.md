---
title: Vision Limelight
panelCategory: "Vision"
date: 2026-03-28
description: Setting up a Limelight 3A camera with the Control Hub and reading targeting data in Java.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Vision Limelight

The Limelight 3A is a self-contained smart camera built for FTC/FRC. Unlike a plain webcam, it runs its own onboard processing (AprilTag detection, color/contour detection, neural networks) and hands your robot code pre-computed results over the network, instead of raw frames you have to process yourself.

> **Why Limelight over a webcam + EasyOpenCV?** The Limelight offloads all image processing to its own onboard chip, so it doesn't compete with your Control Hub's CPU. It also comes with a full web-based UI for tuning pipelines without redeploying code.

---

## 1. Wiring and Networking

The Limelight 3A connects to your robot two ways:

- **Power + data:** a single USB-C cable from the Limelight to the Control Hub (this also carries power in most configs, so check your specific wiring kit).
- **Network:** the Limelight communicates with your robot code over Ethernet-over-USB, appearing as a device on the Control Hub's network. No separate router or switch is needed for the robot connection.

Once wired, add the Limelight to your robot configuration in the Driver Station app like any other device, giving it a hardware map name (commonly `"limelight"`).

### Tip
> **Configuring over Wi-Fi first:** Before matches, it's often easier to connect a laptop to the Limelight's own configuration network (or your field/pit Wi-Fi, depending on firmware setup) to access its web UI at `limelight.local:5801` (or its IP address) rather than tethering directly every time you want to tweak a pipeline.

---

## 2. Pipeline Configuration (Web UI)

Nearly all Limelight tuning happens in its browser-based dashboard, not in Java:

1. Open the Limelight's web UI (typically `http://limelight.local:5801`, or the device's IP if `.local` resolution doesn't work on your network).
2. Under the **Pipelines** tab, choose a pipeline type: AprilTag, Python/SnapScript, Color, Classifier, or Detector (neural network), depending on your firmware and use case.
3. Configure detection parameters for that pipeline (e.g. HSV thresholds for a color pipeline, tag family for AprilTag, confidence threshold for a neural detector) while watching the live camera feed update in real time.
4. Save the pipeline to one of the numbered pipeline slots (0-9). Your robot code selects pipelines by this index number.

You can configure multiple pipelines (e.g. one for AprilTags, one for a game piece color) and switch between them from code during a match.

---

## 3. Reading Results in Java

Add the Limelight to your hardware map and pull results each loop using `getLatestResult()`.

```java
import com.qualcomm.hardware.limelightvision.Limelight3A;
import com.qualcomm.hardware.limelightvision.LLResult;

private Limelight3A limelight;

// In init():
limelight = hardwareMap.get(Limelight3A.class, "limelight");
limelight.pipelineSwitch(0);  // select pipeline slot 0
limelight.start();            // begin polling for data
```

`limelight.start()` must be called before results become available. It's easy to forget and then wonder why every result comes back invalid.

```java
LLResult result = limelight.getLatestResult();

if (result != null && result.isValid()) {
    double tx = result.getTx();  // degrees left/right of crosshair
    double ty = result.getTy();  // degrees up/down from crosshair

    telemetry.addData("tx", tx);
    telemetry.addData("ty", ty);
} else {
    telemetry.addData("Limelight", "No valid target");
}
```

`getTx()`/`getTy()` report how far off-center the primary target is, in degrees: exactly what you need for turning a drivetrain or turret to aim at it. `isValid()` tells you whether the Limelight currently sees a target for the active pipeline; **always check it** before trusting `tx`/`ty`, since a stale or empty result will otherwise silently feed garbage into your control loop.

### Tip
> **Poll rate:** `limelight.setPollRateHz(100)` controls how often the SDK fetches new results from the Limelight over the network. The default is reasonable for most uses, but raising it can reduce latency for fast aiming loops at the cost of more network traffic.

---

## 4. Practical Example: Aim-and-Range with Gamepad Override

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.hardware.limelightvision.LLResult;
import com.qualcomm.hardware.limelightvision.Limelight3A;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Limelight Aim Example", group = "Vision")
public class LimelightAimExample extends LinearOpMode {

    private Limelight3A limelight;
    private DcMotor leftDrive, rightDrive;

    @Override
    public void runOpMode() {
        limelight = hardwareMap.get(Limelight3A.class, "limelight");
        leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
        rightDrive = hardwareMap.get(DcMotor.class, "rightDrive");

        limelight.pipelineSwitch(0);
        limelight.start();

        waitForStart();

        while (opModeIsActive()) {
            double drive = -gamepad1.left_stick_y;
            double turn;

            LLResult result = limelight.getLatestResult();

            if (gamepad1.right_bumper && result != null && result.isValid()) {
                // Auto-aim: steer to reduce tx toward zero.
                turn = result.getTx() * 0.03;
                telemetry.addData("Mode", "AUTO-AIM");
                telemetry.addData("tx", "%.2f", result.getTx());
            } else {
                // Manual driver control.
                turn = gamepad1.right_stick_x;
                telemetry.addData("Mode", "MANUAL");
            }

            leftDrive.setPower(drive + turn);
            rightDrive.setPower(drive - turn);
            telemetry.update();
        }

        limelight.stop();
    }
}
```

---

> **Multiple result types:** Depending on the active pipeline, `LLResult` can also expose `getFiducialResults()` (AprilTags), `getColorResults()`, `getDetectorResults()` (neural network detections), and `getClassifierResults()`. Only the result types matching your currently-selected pipeline will contain data.

### Tip
> **Status telemetry while tuning:** `limelight.getStatus()` returns an `LLStatus` object with fields like temperature, CPU usage, and FPS, handy for confirming the Limelight is healthy and not overheating/throttling during a long pit-testing session.
