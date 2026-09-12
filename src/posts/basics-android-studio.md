---
title: Android Studio Setup
panelCategory: "Basics"
date: 2026-04-02
description: Installing Android Studio and opening the FTC SDK on Windows and Mac.
tags: [completed, software, beginner, rookie]
author: Blueprint
published: true
---

![Android Studio](/images/posts/basics-android-studio/1775352929725_image.png)

Android Studio is the IDE used to write and deploy FTC code. It is built on IntelliJ IDEA and ships with the Android SDK and Gradle, which the FTC SDK needs to build.

## Windows

1. Download the Windows installer from the [Android Studio download page](https://developer.android.com/studio).
2. Run the installer and accept the defaults.
3. Clone or download the [FtcRobotController](https://github.com/FIRST-Tech-Challenge/FtcRobotController) repository.
4. On the welcome screen, choose Open and select the repository folder.
5. Wait for the Gradle sync to finish. The first sync downloads dependencies and can take serveral minutes.

## Mac

1. Download the Mac build from the [Android Studio download page](https://developer.android.com/studio). Pick Apple Silicon for M-series chips and Intel for older Macs.
2. Open the `.dmg` and drag Android Studio into Applications.
3. Launch it and let the setup wizard install the SDK with the standard options.
4. Clone or download the [FtcRobotController](https://github.com/FIRST-Tech-Challenge/FtcRobotController) repository.
5. Open the repository folder from the welcome screen and wait for the Gradle sync to finish.

## Deploying to the Control Hub

You can deploy over USB or over Wi-Fi.

For Wi-Fi, connect your computer to the Control Hub's Wi-Fi network, then run this in the Android Studio terminal:

```bash
adb connect 192.168.43.1:5555
```

The hub should then show up as a run target. Press Run to build and install the app.

If the hub does not appear over USB on Windows, install the REV Hardware Client, which includes the USB driver.

## Common problems

- **Gradle sync fails.** Check your internet connection and make sure you opened the repository folder itself, not a folder inside it.
- **Hub not found.** Make sure you are on the hub's Wi-Fi network and re-run the `adb connect` command. The connection drops when the hub reboots.
- **Build error after updating the SDK.** Use File > Invalidate Caches and restart Android Studio, then sync again.
