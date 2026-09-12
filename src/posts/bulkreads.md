---
title: Bulk Reads
panelCategory: "Miscellaneous"
date: 2026-05-18
description: Reading all hub motor data in one command with LynxModule bulk caching.
tags: [completed, software, intermediate, performance]
author: Blueprint
published: true
---

Every call like `motor.getCurrentPosition()` sends a separate command to the hub and waits for the reply. A loop that reads four encoders and four velocities spends most of its time waiting.

Bulk reads fetch all of a hub's motor and digital data in one command. Later reads in the same loop come from that cached copy. The SDK sample is `ConceptMotorBulkRead`, which times all three modes against each other.

## Setup

Use `DcMotorEx` for the motors, then get the list of hubs.

```java
private DcMotorEx m1, m2, m3, m4;

m1 = hardwareMap.get(DcMotorEx.class, "m1");
m2 = hardwareMap.get(DcMotorEx.class, "m2");
m3 = hardwareMap.get(DcMotorEx.class, "m3");
m4 = hardwareMap.get(DcMotorEx.class, "m4");

List<LynxModule> allHubs = hardwareMap.getAll(LynxModule.class);
```

Keep `allHubs` as a field if the loop needs it.

## Modes

**OFF** is the default. Each encoder position is its own command, and each velocity read triggers a bulk read. This is the worst case.

**AUTO** does one bulk read per cycle, unless you read the same item twice in that cycle. The second read of the same item forces another bulk read.

```java
for (LynxModule module : allHubs) {
    module.setBulkCachingMode(LynxModule.BulkCachingMode.AUTO);
}
```

**MANUAL** does exactly one read per cycle and never refreshes on its own. You clear the cache at the top of every loop. There is no penalty for reading the same value repeatedly, they all return the same data. If you forget to clear it, every read returns the same stale values for the rest of the OpMode.

```java
for (LynxModule module : allHubs) {
    module.setBulkCachingMode(LynxModule.BulkCachingMode.MANUAL);
}

while (opModeIsActive()) {
    // Clear once per control cycle.
    for (LynxModule module : allHubs) {
        module.clearBulkCache();
    }

    e1 = m1.getCurrentPosition();
    e2 = m2.getCurrentPosition();
    e3 = m3.getCurrentPosition();
    e4 = m4.getCurrentPosition();
}
```

## Which mode to use

Use `AUTO` unless you have a reason not to. Use `MANUAL` when you want exactly one hub read per cycle regardless of how your code is structured, which matters for odometry and any code that reads the same encoder in more then one place.

## Read each input once

This matters whichever mode you pick. Read every input once at the top of the loop into a variable, then use that variable for both the control code and telemetry. Putting `getCurrentPosition()` inside a `telemetry.addData()` call fetches another copy and costs time. Reading a saved variable costs nothing.

## What is covered

Bulk reads cover the data the hub reports in its bulk packet: motor encoder positions, motor velocities, digital inputs, and analog inputs. I2C sensors like the color sensor and distance sensor are not included and still cost a separate transaction each.
