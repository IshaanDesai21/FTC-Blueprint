---
title: Color Sensor
panelCategory: "Sensors"
date: 2026-05-06
description: Reading RGB, HSV, and distance from the REV Color Sensor.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The REV Color Sensor V3 reads color and short-range distance over I2C. Common uses are checking whether a game piece is in the intake and detecting field tape.

## Setup

Use `NormalizedColorSensor`. Red, green, blue, and alpha come back as values from 0.0 to 1.0.

```java
import com.qualcomm.robotcore.hardware.NormalizedColorSensor;
import com.qualcomm.robotcore.hardware.NormalizedRGBA;

NormalizedColorSensor colorSensor = hardwareMap.get(NormalizedColorSensor.class, "colorSensor");
```

```java
NormalizedRGBA colors = colorSensor.getNormalizedColors();

telemetry.addData("Red", "%.3f", colors.red);
telemetry.addData("Green", "%.3f", colors.green);
telemetry.addData("Blue", "%.3f", colors.blue);
```

If the values are all very small, raise the gain.

```java
colorSensor.setGain(10);
```

## Detecting a color

Comparing raw channels works in fixed lighting.

```java
if (colors.red > colors.blue && colors.red > colors.green) {
    // red
}
```

Hue is more stable when lighting changes. Convert to HSV with `android.graphics.Color`. Hue is 0 to 360: red is near 0 or 360, yellow near 60, green near 120, blue near 240.

```java
import android.graphics.Color;

float[] hsv = {0F, 0F, 0F};
Color.colorToHSV(colors.toColor(), hsv);

float hue = hsv[0];
```

Read the hue of the actual objects with telemetry before picking thresholds. The numbers vary with distance and lighting.

## Distance

The V3 also implements `DistanceSensor`.

```java
import com.qualcomm.robotcore.hardware.DistanceSensor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

double cm = ((DistanceSensor) colorSensor).getDistance(DistanceUnit.CM);
```

It only reads a few centimeters, which is enough for intake detection.

## LED

The sensor's LED can be turned on and off through `SwitchableLight`.

```java
import com.qualcomm.robotcore.hardware.SwitchableLight;

if (colorSensor instanceof SwitchableLight) {
    ((SwitchableLight) colorSensor).enableLight(true);
}
```

Leave it on for reading surfaces up close.

## Example

Reports red or blue only when something is within 5 cm.

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.NormalizedColorSensor;
import com.qualcomm.robotcore.hardware.NormalizedRGBA;
import com.qualcomm.robotcore.hardware.DistanceSensor;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;
import android.graphics.Color;

@TeleOp(name = "Color Sensor Example")
public class ColorSensorExample extends LinearOpMode {

    private NormalizedColorSensor colorSensor;

    @Override
    public void runOpMode() {
        colorSensor = hardwareMap.get(NormalizedColorSensor.class, "colorSensor");
        colorSensor.setGain(10);

        waitForStart();

        float[] hsv = {0F, 0F, 0F};

        while (opModeIsActive()) {
            NormalizedRGBA colors = colorSensor.getNormalizedColors();
            Color.colorToHSV(colors.toColor(), hsv);
            double cm = ((DistanceSensor) colorSensor).getDistance(DistanceUnit.CM);

            String detected = "none";
            if (cm < 5.0) {
                if (hsv[0] < 30 || hsv[0] > 330) {
                    detected = "red";
                } else if (hsv[0] > 200 && hsv[0] < 260) {
                    detected = "blue";
                }
            }

            telemetry.addData("Object", detected);
            telemetry.addData("Hue", "%.1f", hsv[0]);
            telemetry.addData("Distance (cm)", "%.1f", cm);
            telemetry.update();
        }
    }
}
```

The hue thresholds above are a starting point, adjust them for you're objects.
