---
title: Color Sensor
panelCategory: "Sensors"
date: 2026-04-05
description: How to read RGB and HSV values from the REV Color Sensor.
tags: ["software", "completed", "beginner"]
author: Ishaan Desai
published: true
---

# Color Sensor Basics

The color sensor (most common being the REV Color/Range Sensor) allows your robot to detect colors, light levels, and even proximity. This is essential for detecting team props, game pieces, or tape on the field.

### Tip
> **Why use a Color Sensor?** Beyond just "seeing" color, these sensors are great for identifying the orientation of objects or ensuring a robot has correctly grabbed a specific game piece.

---

Add the sensor to your hardware map using the `NormalizedColorSensor` class. This interface is recommended because it provides consistent values (0.0 to 1.0) regardless of the sensor's internal resolution.

```java
import com.qualcomm.robotcore.hardware.NormalizedColorSensor;
import com.qualcomm.robotcore.hardware.NormalizedRGBA;

NormalizedColorSensor colorSensor = hardwareMap.get(NormalizedColorSensor.class, "colorSensor");
```

Read the colors into a `NormalizedRGBA` object.

```java
NormalizedRGBA colors = colorSensor.getNormalizedColors();

telemetry.addData("Red", "%.3f", colors.red);
telemetry.addData("Green", "%.3f", colors.green);
telemetry.addData("Blue", "%.3f", colors.blue);
```

## 3. Detecting Specific Colors

Comparing raw RGB values can be tricky because lighting conditions change. A common technique is to check which value is the highest.

```java
if (red > blue && red > green) {
    telemetry.addData("Color", "Red Detected");
} else if (blue > red && blue > green) {
    telemetry.addData("Color", "Blue Detected");
}
```

For more reliable color detection, it's recommended to convert your RGB values into **HSV** (Hue, Saturation, Value).

```java
float hsvValues[] = {0F, 0F, 0F};
NormalizedRGBA colors = colorSensor.getNormalizedColors();
Color.colorToHSV(colors.toColor(), hsvValues);

telemetry.addData("Hue", hsvValues[0]);
```
*Tip: Red is usually around 0 or 360, Blue is around 240, and Yellow is around 60.*

## 5. Built-in Distance Sensing

Many color sensors (like the REV V3) also function as distance sensors. This is great for "Check if a piece is in the intake" logic.

```java
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

double distance = ((DistanceSensor) colorSensor).getDistance(DistanceUnit.CM);
telemetry.addData("Distance (cm)", "%.2f", distance);
```

---

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.NormalizedColorSensor;
import com.qualcomm.robotcore.hardware.NormalizedRGBA;
import com.qualcomm.robotcore.hardware.DistanceSensor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;
import android.graphics.Color;

@TeleOp(name = "Normalized Color Sensor Example", group = "Sensor")
public class ColorSensorExample extends LinearOpMode {

    private NormalizedColorSensor colorSensor;

    @Override
    public void runOpMode() {
        colorSensor = hardwareMap.get(NormalizedColorSensor.class, "colorSensor");

        telemetry.addData("Status", "Initialized");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {
            // 1. Get normalized colors (0.0 to 1.0)
            NormalizedRGBA colors = colorSensor.getNormalizedColors();
            
            // 2. Convert to HSV
            float hsvValues[] = {0F, 0F, 0F};
            Color.colorToHSV(colors.toColor(), hsvValues);
            
            // 3. Read distance
            double dist = ((DistanceSensor) colorSensor).getDistance(DistanceUnit.CM);

            // 4. Detection Logic
            String detected = "NONE";
            if (dist < 5.0) {
                if (hsvValues[0] < 30 || hsvValues[0] > 330) {
                    detected = "RED";
                } else if (hsvValues[0] > 200 && hsvValues[0] < 260) {
                    detected = "BLUE";
                }
            }

            telemetry.addData("Object", detected);
            telemetry.addData("Hue", "%.1f", hsvValues[0]);
            telemetry.addData("Distance (cm)", "%.1f", dist);
            telemetry.update();
        }
    }
}
```

---

> **Lighting:** The REV Color Sensor has a built-in LED. You can turn it on or off using `colorSensor.enableLed(true)`. This is helpful for surface detection but might interfere with detecting distant objects.

