---
title: Android Studio Setup
panelCategory: "Basics"
date: 2026-03-28
description: Complete set up guide for Android Studio on both Windows and Mac.
tags: ["completed", "software", "beginner", "rookie", "video"]
author: Ishaan Desai
published: true
---

![image.png](/images/posts/basics-android-studio/1775352929725_image.png)

This guide will walk you through setting up Android Studio for your FTC Robot Controller projects. It is essential to get your development environment properly installed and configured to begin writing and deploying Opmode code.

## Windows Setup

To install Android Studio on a Windows machine:

1. Visit the [Android Studio Download page](https://developer.android.com/studio).
2. Download the executable installer for Windows.
3. Once downloaded, run the installer and ensure you check the options for "Android SDK" and "Android Virtual Device" if prompted.
4. Follow the setup wizard, accepting the default locations.
5. Clone or download your desired FTC SDK repository and open the folder from the Android Studio splash screen.
6. The IDE will take some time to fetch Gradle dependencies. Once the build finishes and syncs, you're ready to start programming.

## Mac Setup

To install Android Studio on a macOS machine:

1. Visit the [Android Studio Download page](https://developer.android.com/studio).
2. Choose the download button for your processor type (Intel or Apple Silicon).
3. Once downloaded, open the `.dmg` file and drag the Android Studio icon into the Applications folder.
4. Open the application. On first launch, Android Studio will present a Setup Wizard. Like on Windows, proceed with standard choices, letting it download the necessary SDK platforms.
5. Open your cloned FTC SDK directory via the Welcome window (`Open...`).
6. After establishing the project structure and finishing gradle indexing, your setup is complete.

_Ensure that you have set up ADB (Android Debug Bridge) or allowed sufficient permissions for your OS to detect your Rev Control Hub over Wi-Fi or USB!_
