---
title: Bulk Reads
panelCategory: "Miscellaneous"
date: 2026-03-28
description: Optimizing your FTC robot's control loop with LynxModule bulk reading.
tags: [completed, software, intermediate, performance]
author: Ishaan Desai
published: true
---

Bulk reading is the most effective way to optimize your robot's loop time. In a standard FTC OpMode, every sensor or motor read (like `motor.getCurrentPosition()`) triggers a separate and slow I2C/Serial communication with the Control or Expansion Hub.

Bulk reads allow you to capture **all** of the hub's data (encoder positions, sensor values, etc.) in a single, efficient command.

## Setting Up Bulk Reads

To use bulk reads, you need to access the `LynxModule` (the Rev Hub) in your code.

```java
public void initBulkReads() {
    List<LynxModule> allHubs = hardwareMap.getAll(LynxModule.class);

    for (LynxModule hub : allHubs) {
        hub.setBulkCachingMode(LynxModule.BulkCachingMode.AUTO);
    }
}
```

## The Three Modes

There are three different ways to handle bulk reads in FTC:

### 1. OFF (Default)

This is the default mode. No bulk reading is performed. Every single sensor or motor read triggers a new communication request with the hub, which is slow.

### 2. AUTO (Recommended)

This mode automatically performs a bulk read whenever it needs data and clears the cache once per control loop. This is the easiest mode to use and provides a massive speed boost with almost zero effort.

### 3. MANUAL (Most Accurate)

Manual mode gives the most control. You must manually call `hub.clearBulkCache()` at the beginning of each loop. This ensures you are always using the latest data and that the cache is handled exactly when you want it.

```java
// At the start of your while(opModeIsActive()) loop:
for (LynxModule hub : allHubs) {
    hub.clearBulkCache();
}
```

## Why This Matters

Without bulk reads, a typical control loop might run at **40-60 Hz**. With bulk reads enabled, you can easily reach **100 Hz** or even **200 Hz**, depending on the complexity of your code. Faster loops lead to more responsive control, especially for PID and odometry.
