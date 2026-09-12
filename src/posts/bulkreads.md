---
title: Bulk Reads
panelCategory: "Miscellaneous"
date: 2026-05-18
description: Reading all hub sensor data in one command with LynxModule bulk caching.
tags: [completed, software, intermediate, performance]
author: Blueprint
published: true
---

Every call like `motor.getCurrentPosition()` sends a separate command to the hub and waits for the reply. A loop that reads several encoders and sensors spends most of its time waiting.

Bulk reads fetch all of a hub's encoder and sensor data in one command. Later reads in the same loop come from that cached snapshot.

## Setup

Each REV hub is a `LynxModule`. Set the caching mode on all of them during init.

```java
import com.qualcomm.hardware.lynx.LynxModule;
import java.util.List;

List<LynxModule> allHubs = hardwareMap.getAll(LynxModule.class);

for (LynxModule hub : allHubs) {
    hub.setBulkCachingMode(LynxModule.BulkCachingMode.AUTO);
}
```

That is all that is needed for `AUTO` mode.

## Modes

**OFF** is the default. Every read is its own command.

**AUTO** refreshes the cache whenever you read a value that has already been read from the current cache. If you read each encoder once per loop, you get one bulk read per loop. If you read the same encoder twice in one loop, the second read triggers another bulk read.

**MANUAL** never refreshes on its own. You clear the cache at the top of every loop. If you forget, every read returns the same stale values for the rest of the OpMode.

```java
while (opModeIsActive()) {
    for (LynxModule hub : allHubs) {
        hub.clearBulkCache();
    }

    // reads go here
}
```

Keep `allHubs` as a field so the loop can reach it.

## Which mode to use

Use `AUTO` unless you have a reason not to. Use `MANUAL` when you want exactly one hub read per loop no matter how your code is structured, which matters for odometry and any code that reads the same encoder in more then one place.

Bulk reads only cover data the hub reports in its bulk packet: motor encoders, motor velocity, digital inputs, and analog inputs. I2C sensors like the color sensor and distance sensor are not included and still cost a separate read each.
