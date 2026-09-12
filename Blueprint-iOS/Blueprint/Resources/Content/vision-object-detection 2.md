---
title: Vision Object Detection
panelCategory: "Vision"
date: 2026-03-28
description: Using the FTC SDK's TfodProcessor (TensorFlow Object Detection) to detect and rank game pieces.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

# Vision Object Detection (TFOD)

The FTC SDK includes a built-in TensorFlow-based object detector, exposed through the `TfodProcessor` class. It runs a neural network model against the camera feed and returns bounding boxes and confidence scores for whatever objects the model was trained to recognize, most commonly game pieces from the current season.

> **TFOD vs. AprilTag vs. OpenCV color detection:** Use `AprilTagProcessor` for fixed field fiducials, `TfodProcessor` for recognizing game pieces (which don't have a fiducial marker on them), and a custom EasyOpenCV pipeline when you need detection logic the built-in processors don't cover (e.g. a very specific color/shape combo).

---

## 1. Setting Up the VisionPortal with TFOD

Like `AprilTagProcessor`, `TfodProcessor` attaches to a `VisionPortal`.

```java
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.firstinspires.ftc.vision.VisionPortal;
import org.firstinspires.ftc.vision.tfod.TfodProcessor;
import org.firstinspires.ftc.vision.tfod.Recognition;

import java.util.List;

private TfodProcessor tfod;
private VisionPortal visionPortal;

private void initTfod() {
    // Create the TensorFlow processor.
    tfod = new TfodProcessor.Builder()
            // Use the season's built-in model, or point to a custom-trained one:
            //.setModelAssetName("MyCustomModel.tflite")
            //.setModelLabels(Arrays.asList("PieceA", "PieceB"))
            .build();

    // Create the vision portal.
    VisionPortal.Builder builder = new VisionPortal.Builder();
    builder.setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"));
    builder.addProcessor(tfod);

    visionPortal = builder.build();
}
```

If you're using the season's default game-piece model, `TfodProcessor.Builder().build()` with no arguments is usually enough, since the SDK ships with the current season's model built in. For a custom-trained model, point `.setModelAssetName()` (for models bundled as Android assets) or `.setModelFileName()` (for models loaded from a file on the Control Hub) at your `.tflite` file, and supply the matching label list with `.setModelLabels()`.

### Tip
> **Confidence threshold:** `.setMinResultConfidence(0.75f)` on the builder filters out low-confidence noise before it ever reaches `getRecognitions()`, which is usually simpler than filtering manually in your loop.

---

## 2. Reading Recognitions

Each call to `tfod.getRecognitions()` returns a `List<Recognition>`, one entry per detected object in the current frame.

```java
List<Recognition> currentRecognitions = tfod.getRecognitions();
telemetry.addData("# Objects Detected", currentRecognitions.size());

for (Recognition recognition : currentRecognitions) {
    double x = (recognition.getLeft() + recognition.getRight()) / 2;
    double y = (recognition.getTop() + recognition.getBottom()) / 2;

    telemetry.addData("Label", "%s (%.0f %% Conf.)",
            recognition.getLabel(), recognition.getConfidence() * 100);
    telemetry.addData("Position", "%.0f, %.0f", x, y);
    telemetry.addData("Box (L,T,R,B)", "%.0f, %.0f, %.0f, %.0f",
            recognition.getLeft(), recognition.getTop(),
            recognition.getRight(), recognition.getBottom());
}
```

| Method | Meaning |
|---|---|
| `getLabel()` | The class name the model assigned (e.g. `"YellowPixel"`). |
| `getLeft()`, `getRight()`, `getTop()`, `getBottom()` | Bounding box edges in pixel coordinates of the camera frame. |
| `getConfidence()` | Model confidence for this detection, from 0.0 to 1.0. |

The bounding box coordinates are in the camera's pixel space (e.g. 0-640 horizontally at 640x480), not real-world units. You use them to compute where in the frame the object is (for steering) or how large it appears (as a rough distance proxy), not an exact physical position.

---

## 3. Practical Example: Picking the Best Detection

Multiple objects are often visible at once. A common pattern is to filter by label and pick the highest-confidence match, then steer toward its horizontal position in frame.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;
import org.firstinspires.ftc.robotcore.external.hardware.camera.WebcamName;
import org.firstinspires.ftc.vision.VisionPortal;
import org.firstinspires.ftc.vision.tfod.TfodProcessor;
import org.firstinspires.ftc.vision.tfod.Recognition;

import java.util.List;

@TeleOp(name = "TFOD Best Detection Example", group = "Vision")
public class TfodBestDetectionExample extends LinearOpMode {

    private static final String TARGET_LABEL = "GamePiece";

    private TfodProcessor tfod;
    private VisionPortal visionPortal;
    private DcMotor leftDrive, rightDrive;

    @Override
    public void runOpMode() {
        leftDrive = hardwareMap.get(DcMotor.class, "leftDrive");
        rightDrive = hardwareMap.get(DcMotor.class, "rightDrive");

        tfod = new TfodProcessor.Builder()
                .setMinResultConfidence(0.7f)
                .build();

        visionPortal = new VisionPortal.Builder()
                .setCamera(hardwareMap.get(WebcamName.class, "Webcam 1"))
                .addProcessor(tfod)
                .build();

        waitForStart();

        while (opModeIsActive()) {
            List<Recognition> recognitions = tfod.getRecognitions();

            Recognition best = null;
            for (Recognition recognition : recognitions) {
                if (!recognition.getLabel().equals(TARGET_LABEL)) {
                    continue;
                }
                if (best == null || recognition.getConfidence() > best.getConfidence()) {
                    best = recognition;
                }
            }

            if (best != null) {
                double centerX = (best.getLeft() + best.getRight()) / 2;
                double frameCenterX = 320; // half of a 640-wide frame
                double error = centerX - frameCenterX;

                double turn = error * 0.005; // proportional steering
                leftDrive.setPower(turn);
                rightDrive.setPower(-turn);

                telemetry.addData("Target", "%s (%.0f%%)", best.getLabel(), best.getConfidence() * 100);
                telemetry.addData("Center X", "%.0f", centerX);
            } else {
                leftDrive.setPower(0);
                rightDrive.setPower(0);
                telemetry.addData("Target", "None visible");
            }

            telemetry.update();
        }

        visionPortal.close();
    }
}
```

---

### Tip
> **Model performance:** TFOD is more CPU-intensive than AprilTag or simple OpenCV thresholding. If telemetry feels laggy with TFOD running, try lowering camera resolution via `.setCameraResolution(new Size(640, 480))` on the `VisionPortal.Builder`, or disable other processors you aren't actively using with `visionPortal.setProcessorEnabled(processor, false)`.

> **Warning:** Bounding boxes are only as good as the model's training data. Lighting, background clutter, and partially-occluded pieces can all reduce confidence or produce false positives, so always test detection against the actual game pieces under actual field/practice lighting before relying on it in a match.
