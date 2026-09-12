---
title: Vision Opencv
panelCategory: "Vision"
date: 2026-03-28
description: How to build custom color and shape detection pipelines in FTC using EasyOpenCV.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Vision OpenCV (EasyOpenCV)

The FTC SDK's built-in `AprilTagProcessor` and `TfodProcessor` cover most teams' needs, but sometimes you need to detect something neither one handles well: a specific colored game piece, a shape, or a custom field element. **EasyOpenCV** is the standard FTC wrapper around OpenCV that makes writing your own frame-processing pipeline straightforward.

> **Why EasyOpenCV?** Raw OpenCV/Android camera integration in FTC is finicky. EasyOpenCV handles camera lifecycle, threading, and the live preview for you, so you only need to write the actual image processing logic.

---

## 1. Adding EasyOpenCV

Add the EasyOpenCV dependency to your `TeamCode` module's `build.gradle` (check the [EasyOpenCV GitHub](https://github.com/OpenFTC/EasyOpenCV) for the current version number):

```groovy
dependencies {
    implementation 'org.openftc:easyopencv:1.7.0'
}
```

---

## 2. Writing a Pipeline

Every pipeline extends `OpenCvPipeline` and overrides `processFrame(Mat input)`. Whatever `Mat` you return from this method is what gets drawn to the Driver Station's live camera preview, so you can draw debug rectangles/text directly onto it.

```java
import org.opencv.core.Mat;
import org.openftc.easyopencv.OpenCvPipeline;

class EmptyPipeline extends OpenCvPipeline {
    @Override
    public Mat processFrame(Mat input) {
        return input; // pass the frame through unmodified
    }
}
```

### Tip
> **Reuse your `Mat` objects.** Declare working `Mat`s (like an HSV conversion buffer or a mask) as instance fields instead of creating new ones inside `processFrame()`. Allocating a new `Mat` every frame at 30 FPS creates garbage collection pressure and can visibly lag your telemetry and driver preview.

---

## 3. HSV Color Detection Example

A common task is detecting a colored game piece and reporting which region of the camera frame it's in (left/center/right), so your robot can steer toward it. The standard approach: convert the frame to HSV color space, then threshold for your target color's hue range.

```java
import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.Scalar;
import org.opencv.imgproc.Imgproc;
import org.openftc.easyopencv.OpenCvPipeline;

public class ColorDetectionPipeline extends OpenCvPipeline {

    // Reused every frame -- avoid allocating new Mats in processFrame().
    private final Mat hsvMat = new Mat();
    private final Mat mask = new Mat();

    // Example: detecting a yellow game piece.
    private final Scalar lowerYellow = new Scalar(20, 100, 100);
    private final Scalar upperYellow = new Scalar(30, 255, 255);

    public volatile double leftPercent = 0;
    public volatile double centerPercent = 0;
    public volatile double rightPercent = 0;

    @Override
    public Mat processFrame(Mat input) {
        // EasyOpenCV feeds frames in as RGBA -- convert to HSV for thresholding.
        Imgproc.cvtColor(input, hsvMat, Imgproc.COLOR_RGB2HSV);

        // Build a binary mask: white where the color is within range, black elsewhere.
        Core.inRange(hsvMat, lowerYellow, upperYellow, mask);

        int width = mask.cols();
        int height = mask.rows();

        // Split the frame into three vertical regions and measure how much of
        // the target color is in each one.
        Mat left = mask.submat(0, height, 0, width / 3);
        Mat center = mask.submat(0, height, width / 3, 2 * width / 3);
        Mat right = mask.submat(0, height, 2 * width / 3, width);

        leftPercent = Core.countNonZero(left) / (double) left.total();
        centerPercent = Core.countNonZero(center) / (double) center.total();
        rightPercent = Core.countNonZero(right) / (double) right.total();

        left.release();
        center.release();
        right.release();

        // Return the mask itself so you can visually confirm the threshold
        // is picking up the right pixels on the Driver Station preview.
        return mask;
    }

    public String getRegion() {
        if (Math.max(leftPercent, Math.max(centerPercent, rightPercent)) < 0.05) {
            return "NONE";
        }
        if (leftPercent > centerPercent && leftPercent > rightPercent) return "LEFT";
        if (rightPercent > centerPercent) return "RIGHT";
        return "CENTER";
    }
}
```

> **Warning:** Any `Mat` produced by `submat()` shares memory with its parent, but is still its own object that must be released with `.release()` once you're done with it, or you'll leak native memory frame after frame.

---

## 4. Camera Setup

Initialize the webcam and attach your pipeline before `waitForStart()`.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.openftc.easyopencv.OpenCvCamera;
import org.openftc.easyopencv.OpenCvCameraFactory;
import org.openftc.easyopencv.OpenCvCameraRotation;
import org.openftc.easyopencv.OpenCvWebcam;

@TeleOp(name = "OpenCV Color Detection Example", group = "Vision")
public class OpenCvColorExample extends LinearOpMode {

    private OpenCvWebcam webcam;
    private ColorDetectionPipeline pipeline;

    @Override
    public void runOpMode() {
        int cameraMonitorViewId = hardwareMap.appContext.getResources()
                .getIdentifier("cameraMonitorViewId", "id", hardwareMap.appContext.getPackageName());

        webcam = OpenCvCameraFactory.getInstance().createWebcam(
                hardwareMap.get(WebcamName.class, "Webcam 1"), cameraMonitorViewId);

        pipeline = new ColorDetectionPipeline();
        webcam.setPipeline(pipeline);

        webcam.setMillisecondsPermissionTimeout(5000);
        webcam.openCameraDeviceAsync(new OpenCvCamera.AsyncCameraOpenListener() {
            @Override
            public void onOpened() {
                webcam.startStreaming(320, 240, OpenCvCameraRotation.UPRIGHT);
            }

            @Override
            public void onError(int errorCode) {
                telemetry.addData("Camera Error", errorCode);
                telemetry.update();
            }
        });

        waitForStart();

        while (opModeIsActive()) {
            telemetry.addData("Region", pipeline.getRegion());
            telemetry.addData("Left %", "%.2f", pipeline.leftPercent);
            telemetry.addData("Center %", "%.2f", pipeline.centerPercent);
            telemetry.addData("Right %", "%.2f", pipeline.rightPercent);
            telemetry.addData("FPS", "%.1f", webcam.getFps());
            telemetry.update();
        }

        webcam.stopStreaming();
    }
}
```

---

## 5. Performance Considerations

`processFrame()` runs on a dedicated vision thread, but it still has to keep up with the camera's frame rate, usually 320x240 or 640x480 at 30 FPS. Slow processing doesn't crash your OpMode, but it does silently drop your effective FPS, which makes your detection laggy and your driver-facing telemetry feel stale.

- **Keep resolution low.** 320x240 is usually plenty for color/shape detection and is dramatically faster than 640x480 or higher.
- **Avoid unnecessary color space conversions.** Only convert once per frame, and reuse the buffer.
- **Prefer `Core.inRange` + `countNonZero`** over pixel-by-pixel loops in Java. OpenCV's native functions are far faster than manual iteration over `Mat` data.
- **Watch `webcam.getFps()` and `webcam.getPipelineTimeMs()`** in telemetry during testing. If pipeline time is eating into your frame budget, simplify the pipeline (smaller submats, fewer operations) before adding more logic.

### Tip
> **Tune HSV ranges with a live preview.** Point the robot's camera at the actual game piece under actual field lighting (LED strips and gym lighting shift hue significantly) and adjust your `lowerYellow`/`upperYellow`-style bounds while watching the returned mask on the Driver Station. A range tuned at your shop under different lighting will often fail on the actual field.
