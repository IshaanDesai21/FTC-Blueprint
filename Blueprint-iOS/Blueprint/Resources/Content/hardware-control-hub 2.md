---
title: Control Hub
panelCategory: "Electronics"
date: 2026-04-10
description: Setting up and understanding the REV Control Hub.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

The REV Control Hub is the brain of your FTC robot. It's a single board that combines a robot controller computer with a built-in expansion hub, so you can plug motors, servos, and sensors directly into it without needing a separate phone. Understanding what it does and how to set it up correctly is one of the first things any FTC team should tackle.

## Physical Overview

The Control Hub has a lot of ports packed into a small package. Here's what you're working with:

- **4 motor ports** (labeled 0 through 3): these use JST-VH connectors and connect to your DC motors
- **6 servo ports** (labeled 0 through 5): standard 3-pin servo connectors for servos
- **4 I2C ports**: for sensors like color sensors, distance sensors, and IMUs from external sources
- **4 digital ports**: for limit switches and digital sensors
- **4 analog ports**: for sensors that output a voltage signal
- **USB 3.0 port**: for connecting a webcam or other USB accessories
- **USB-C port**: used to connect to a computer for programming and ADB access
- **XT30 power connector**: where the 12V battery plugs in
- **Built-in IMU**: a gyroscope and accelerometer are built right into the hub, so you don't need an external one for basic orientation tracking

The hub itself is designed to be mounted on your robot with the ports accessible. The label on the board makes it pretty clear which port is which, but always double-check the numbers before you plug things in.

## Powering the Control Hub

The Control Hub runs on 12V power from your robot's battery. The battery connects via the XT30 connector on the side of the hub. Make sure the XT30 is fully seated: a loose connection here is one of the most common causes of robots cutting out mid-match.

If you just want to push code or check logs without the battery attached, you can power the hub via USB-C from your laptop. This is convenient during programming sessions, but the motor and servo ports won't be powered, so nothing will actually move. For any real testing, use the battery.

## Connecting to the Control Hub

There are two ways to talk to the Control Hub, and you'll use both depending on what you're doing.

**Over Wi-Fi Direct (for the Driver Station)**

The Control Hub creates its own Wi-Fi network. The network name (SSID) follows the format `FTC-XXXX-RC`, where XXXX is your team number or a name you configure. Your Driver Hub (or an Android phone running the Driver Station app) connects to this network to communicate with the robot during operation and matches.

To set this up, go into the Robot Controller app on the hub (accessible via a connected phone or the hub's own app interface) and configure your team number. The hub will broadcast the network automatically whenever it's powered on.

**Via USB (for programming)**

Plug a USB-C cable from the Control Hub into your laptop. This gives you an ADB (Android Debug Bridge) connection, which is what Android Studio uses to push your OpModes onto the hub. This is how you deploy code. Make sure you have ADB drivers installed and that your laptop recognizes the device.

## What the LED Lights Mean

The Control Hub has an LED status light that tells you what's going on at a glance. Here's a quick breakdown:

- **Solid green**: the hub is running normally and the Robot Controller app is active
- **Blinking green**: the hub is booting up or the app is starting
- **Solid red**: something is wrong, often a configuration issue or the app has crashed
- **Blinking red/orange**: usually indicates a battery issue or that the hub is in a fault state
- **Blue light**: the hub is in pairing mode or updating firmware

When in doubt, a steady green light is what you want to see before a match. If you're seeing red, check the Driver Hub for error messages.

## The Expansion Hub

The Expansion Hub is a separate REV device that gives you additional ports when the Control Hub's built-in ports aren't enough. It connects to the Control Hub via an RS-485 cable (a 4-pin JST-PH cable that plugs into the RS-485 port on both devices).

Once connected, the Expansion Hub shows up as a second hub in your robot configuration, and you can assign motors, servos, and sensors to it just like the Control Hub's own ports. This is useful for robots with a lot of mechanisms that need more than 4 motors or 6 servos.

The Expansion Hub does not have its own computer. It's just extra I/O. All the intelligence still lives in the Control Hub.

## Important Tips

A few things to keep in mind as you work with the Control Hub.

Mount the Control Hub somewhere protected. It shouldn't be hanging off the edge of the robot or in a spot where it could take a direct hit. The inside of the chassis or a protected top plate are common choices.

Make sure your battery connections are solid. The XT30 connector should click in firmly. This is worth checking before every match.

Never unplug the battery while the robot is running (or while OpModes are active). This can corrupt data or cause the hub to behave unpredictably. Always stop the OpMode first, then power down.

Keep the USB-C port clear and accessible. You'll be plugging in frequently during development, and it's frustrating if it's buried behind a wall of wiring.

Updating the Control Hub firmware and the Robot Controller app is also important. REV releases updates that fix bugs and add features. Check for updates at the start of each season.
