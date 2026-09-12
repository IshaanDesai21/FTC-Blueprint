---
title: Gear Ratios and Mechanical Advantage
panelCategory: "Mechanisms"
date: 2026-06-25
description: How gear ratios trade speed for torque, and how to pick the right ratio for a mechanism.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

Every mechanism on your robot, from the drivetrain to a linear slide to an intake roller, is driven through some gear ratio. Understanding what a gear ratio actually does lets you pick the right motor and gearing for a mechanism instead of guessing and hoping it works.

## The Core Tradeoff

A gear ratio trades speed for torque, or torque for speed. You never get more of both at the same time from the same motor. This comes from a simple fact: the motor puts out a fixed amount of mechanical power (roughly speed multiplied by torque). Gearing changes how that power is split between speed and torque, but it can't create more power than the motor produces in the first place.

If you gear a motor down (output shaft turns slower than the motor shaft), you multiply torque and reduce speed. If you gear it up (output turns faster than the motor), you get more speed but less torque. In FTC, you are almost always gearing down, because motors are built to spin fast and mechanisms need torque to move real loads.

## Reading a Gear Ratio

A gear ratio like 20:1 means the input (motor) shaft turns 20 times for every 1 turn of the output shaft. Written as a fraction, that is output speed = input speed / 20, and output torque = input torque × 20 (ignoring friction losses, which are real but usually modest for a well-built gearbox).

For simple spur gears, the ratio is the number of teeth on the output gear divided by the number of teeth on the input gear. A 12-tooth pinion driving a 60-tooth gear gives a 60/12 = 5:1 reduction: the output turns 5 times slower and has roughly 5 times the torque.

For a chain of multiple gear stages (like inside a goBILDA or REV gearbox), multiply the individual stage ratios together to get the total ratio. Three stages of 4:1 each gives a total of 4 × 4 × 4 = 64:1.

## Why This Matters for Motor Selection

FTC legal motors come in a handful of common built-in gearbox ratios, each trading speed for torque differently. A high-RPM, low-torque motor is a good fit for something like a drivetrain wheel or an intake roller, where you want quick response and the load is relatively light per motor. A low-RPM, high-torque motor is a better fit for something like a linear slide lifting a heavy mechanism, where you need enough force to move the load reliably without stalling.

If you gear a fast motor down further with an external reduction (extra sprockets, pulleys, or gears), you can turn a fast motor into a slow, high-torque one. This is common when you need more torque than any single built-in gearbox option provides, or when you need a very specific ratio that doesn't come as a stock option.

## External Reductions

Beyond the motor's internal gearbox, you can add an external gear, chain, or belt reduction between the motor output and the mechanism. This is useful when:

- You need a ratio that isn't available as a stock gearbox option.
- You want to keep the motor itself in a different physical location than the mechanism it drives (for packaging or CG reasons).
- You need more total reduction than the built-in gearbox alone provides.

Keep in mind that every additional stage adds some friction loss and backlash (a small amount of "play" or slop between meshing teeth). More stages generally means slightly less efficiency and slightly more slop, so don't add reduction stages you don't actually need.

## Estimating What Ratio You Need

A rough way to think about it: figure out how much torque your mechanism actually needs to move its heaviest expected load with a reasonable safety margin, then compare that to the torque your motor produces at its available gearbox ratios. If the built-in torque is not enough, either choose a higher-reduction gearbox option or add external reduction.

It is easier to have slightly more torque than you need (the mechanism will simply move faster than the minimum) than to not have enough (the mechanism stalls under load). When in doubt, especially for lift and arm mechanisms carrying real weight, err toward more torque and tune speed down in software if the mechanism ends up moving faster than you want.

## Common Mistakes

**Under-gearing a lift.** If a linear slide or arm stalls or moves painfully slowly under load, it is very often under-geared: not enough torque for the weight being lifted. Adding more reduction (a higher ratio) is usually the fix.

**Over-gearing a drivetrain.** A drivetrain geared for maximum torque instead of speed will feel sluggish and slow to respond during driver control. Drivetrains generally favor speed over raw torque, since traction (not motor torque) is usually the limiting factor for how hard you can accelerate.

**Ignoring backlash in precision mechanisms.** For mechanisms that need to hold a precise position (like an arm that has to stop exactly on target), backlash across multiple gear stages can add up to a noticeable amount of play. Fewer, higher-quality gear stages will hold position more precisely than many cheap ones.

Getting gear ratios right is mostly about matching the mechanism's real-world load to what the motor and gearing combination can actually deliver. Do a rough torque estimate before you build, and you'll save yourself a lot of rebuilding later.
