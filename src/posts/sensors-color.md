---
title: Color Sensor
panelCategory: "Sensors"
date: 2026-05-06
description: Reading RGB, HSV, and distance from the REV Color Sensor.
tags: [software, completed, beginner]
author: Blueprint
published: true
---

The REV Color Sensor V3 reads color and short-range distance over I2C. Common uses are checking whether a game piece is in the intake and detecting field tape. The SDK sample is `SensorColor`.

## Reading it

Use `NormalizedColorSensor`, not `ColorSensor`. Normalized values always run 0 to 1, while raw `ColorSensor` values depend on the specific sensor. The sample names the device `sensor_color`.

```java
colorSensor = hardwareMap.get(NormalizedColorSensor.class, "sensor_color");

NormalizedRGBA colors = colorSensor.getNormalizedColors();

telemetry.addLine()
        .addData("Red", "%.3f", colors.red)
        .addData("Green", "%.3f", colors.green)
        .addData("Blue", "%.3f", colors.blue);
```

## Gain

The V3 returns very low numbers in dim light, using only a little of the 0 to 1 range. Gain multiplies the raw value before normalizing. Use a higher gain in dark conditions and a lower one in bright conditions. Never go below 1. If the gain is too high every channel reads near 1 and you cannot tell colors apart.

```java
float gain = 2;
colorSensor.setGain(gain);
```

Set it once during initialization.

## Hue

Comparing raw channels works in fixed lighting. Hue is more stable when lighting changes. Convert with `android.graphics.Color`.

```java
final float[] hsvValues = new float[3];

NormalizedRGBA colors = colorSensor.getNormalizedColors();
Color.colorToHSV(colors.toColor(), hsvValues);

telemetry.addLine()
        .addData("Hue", "%.3f", hsvValues[0])
        .addData("Saturation", "%.3f", hsvValues[1])
        .addData("Value", "%.3f", hsvValues[2]);
```

Hue runs 0 to 360. Red is near 0 or 360, yellow near 60, green near 120, blue near 240. Read the hue of your actual game pieces on telemetry before picking thresholds. The numbers move with distance and lighting.

## Light

The sensor has an LED. Check for `SwitchableLight` before using it, because not every color sensor has one.

```java
if (colorSensor instanceof SwitchableLight) {
    ((SwitchableLight) colorSensor).enableLight(true);
}
```

Leave it on for reading surfaces up close.

## Distance

The V3 also implements `DistanceSensor`. Check before casting.

```java
if (colorSensor instanceof DistanceSensor) {
    telemetry.addData("Distance (cm)", "%.3f", ((DistanceSensor) colorSensor).getDistance(DistanceUnit.CM));
}
```

The distance reading is only useful at very close range, and ambient light and surface reflectivity both affect it.

## Example

Reports red or blue only when something is within 5 cm.

```java
package org.firstinspires.ftc.teamcode;

import android.graphics.Color;
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DistanceSensor;
import com.qualcomm.robotcore.hardware.NormalizedColorSensor;
import com.qualcomm.robotcore.hardware.NormalizedRGBA;
import com.qualcomm.robotcore.hardware.SwitchableLight;
import org.firstinspires.ftc.robotcore.external.navigation.DistanceUnit;

@TeleOp(name = "Color Sensor Example", group = "Sensor")
public class ColorSensorExample extends LinearOpMode {

    private NormalizedColorSensor colorSensor;

    @Override
    public void runOpMode() {
        colorSensor = hardwareMap.get(NormalizedColorSensor.class, "sensor_color");
        colorSensor.setGain(2);

        if (colorSensor instanceof SwitchableLight) {
            ((SwitchableLight) colorSensor).enableLight(true);
        }

        final float[] hsvValues = new float[3];

        waitForStart();

        while (opModeIsActive()) {
            NormalizedRGBA colors = colorSensor.getNormalizedColors();
            Color.colorToHSV(colors.toColor(), hsvValues);

            double cm = 100;
            if (colorSensor instanceof DistanceSensor) {
                cm = ((DistanceSensor) colorSensor).getDistance(DistanceUnit.CM);
            }

            String detected = "none";
            if (cm < 5.0) {
                if (hsvValues[0] < 30 || hsvValues[0] > 330) {
                    detected = "red";
                } else if (hsvValues[0] > 200 && hsvValues[0] < 260) {
                    detected = "blue";
                }
            }

            telemetry.addData("Object", detected);
            telemetry.addData("Hue", "%.3f", hsvValues[0]);
            telemetry.addData("Distance (cm)", "%.3f", cm);
            telemetry.update();
        }
    }
}
```

The hue thresholds above are a starting point, adjust them for you're game pieces.
