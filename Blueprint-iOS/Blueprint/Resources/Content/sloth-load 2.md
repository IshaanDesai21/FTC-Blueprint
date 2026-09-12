---
title: Sloth Load
panelCategory: "Miscellaneous"
date: 2026-03-28
description: High-speed code deployment and hot-reloading for FTC using Sloth.
tags: [completed, software, beginner, tools]
author: Ishaan Desai
published: true
---

# Sloth Load

Sloth is a game-changing tool for FTC development that allows for specialized "hot-reloading" of your code. Instead of waiting 30-60 seconds for a full Gradle build and upload, Sloth can push changes to your robot in under a second.

---

## Why Use Sloth?

- **Speed:** Instant deployments mean you can iterate on PID values or autonomous paths much faster.
- **Efficiency:** No more staring at the progress bar in Android Studio.
- **Reliability:** Developed by the Dairy Foundation, it's designed specifically for the unique constraints of the Control Hub.

---

## Installation

Sloth is installed as a Gradle plugin in your **`TeamCode/build.gradle`** file (not the root project file).

First, add the Dairy Foundation repository to your buildscript's `repositories` block:

```gradle
buildscript {
    repositories {
        mavenCentral()
        maven { url = 'https://repo.dairy.foundation/releases' }
    }
    dependencies {
        classpath "dev.frozenmilk:Load:0.2.4"
    }
}
```

Then apply the plugin **after** your existing `apply plugin:` lines:

```gradle
apply plugin: 'dev.frozenmilk.sinister.sloth.load'
```

Sync Gradle, then do one normal build-and-install to the robot. Check the [Dairy Foundation Sloth repo](https://github.com/Dairy-Foundation/Sloth) for the latest version number before adding it.

---

## Usage

Once installed, every subsequent build and deploy from Android Studio automatically uses Sloth's fast-reload path instead of a full APK reinstall.

> **Ensure your robot is connected via ADB (Wi-Fi or USB) for the fastest results.**
