---
title: Mecanum Wheels
panelCategory: "Drivetrain"
date: 2026-04-18
description: Understanding and building with mecanum wheels in FTC.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

Mecanum wheels are one of the most recognizable pieces of hardware in competitive FTC. They look like regular wheels, but each one has a row of small rollers mounted at a 45-degree angle around its outer edge. Those rollers are what makes the magic happen. By spinning the four wheels at different speeds and directions, you can make the robot move forward, backward, sideways, and diagonally, all without ever rotating the chassis. This is called omnidirectional movement.

## How the Physics Work

When a mecanum wheel spins, the rollers on its surface redirect the force at an angle. Each wheel pushes the robot at roughly 45 degrees relative to its own spin direction. When you combine four wheels all doing this at the same time, the sideways components can either cancel out or add together depending on which direction each wheel is spinning.

Driving forward is simple: all four wheels spin the same direction. Strafing sideways is where it gets interesting. Two diagonal wheels spin one way, and the other two spin the opposite way. The forward/backward forces cancel each other out, but the sideways forces all point the same direction, so the robot slides to the side. The math behind it is straightforward once you see it, and your drive code handles it automatically.

## Correct Wheel Placement

This is the most critical part of building a mecanum drivetrain. If the wheels are oriented wrong, strafing won't work at all.

When you look down at the top of the robot, the rollers on all four wheels should form an X or diamond shape, with the rollers pointing toward the center of the robot. A good way to check: pick up a wheel and hold it so you're looking at it from above. The rollers diagonal pattern should tell you which corner it belongs in.

Here's the orientation for each corner (imagine looking down at the top of the robot):

- **Front-left**: the rollers run diagonally like a `/` (from bottom-left to top-right)
- **Front-right**: the rollers run diagonally like a `\` (from top-left to bottom-right)
- **Back-left**: the rollers run diagonally like a `\` (from top-left to bottom-right)
- **Back-right**: the rollers run diagonally like a `/` (from bottom-left to top-right)

Another way to think about it: the front-left and back-right wheels are a matched pair, and the front-right and back-left wheels are a matched pair. Most mecanum wheel sets come in two types, often labeled "A" and "B" or distinguished by which direction the rollers lean. Make sure you get the right wheel on the right corner.

If you're unsure, set all four wheels on a flat surface in their mounting positions and look at the roller pattern from above. You should see the X or diamond shape clearly.

## Common Wheel Options in FTC

There are a handful of popular mecanum wheel choices for FTC teams:

- **goBILDA Mecanum Wheels**: probably the most popular choice for teams using goBILDA hardware. They come in 96mm and 100mm diameter options and bolt directly onto goBILDA hubs. They're well-built and widely used at the competitive level.
- **REV Robotics Mecanum Wheels**: designed to work with REV's channel and extrusion system. A good choice if your chassis is built around REV hardware.
- **Andymark Mecanum Wheels**: another solid option, available in multiple sizes. Andymark has been around in FTC for a long time and their products are reliable.

Any of these will work well. The main thing is to make sure your wheel hub matches the motor output shaft, and that the wheel diameter is consistent across all four corners.

## Weight Distribution

For mecanum wheels to perform well, all four wheels need to be carrying roughly equal weight from the robot. If the robot is heavy in the back, the front wheels might lose traction and strafing will become inconsistent.

Try to keep heavy components (battery, Control Hub, heavy mechanisms) centered in the chassis, or at least balanced front-to-back and left-to-right. Perfect balance isn't always possible, but it's worth thinking about during the design phase.

## Common Problems and Fixes

Even with a good build, mecanum drivetrains can have issues. Here are the most common ones:

**Robot doesn't strafe at all.** This almost always means a wheel is oriented the wrong way. Double-check each wheel's roller direction against the X pattern described above. Flip the offending wheel to its correct orientation and try again.

**Robot drifts when strafing.** The robot moves sideways but also slowly rotates or curves. This is usually caused by uneven weight distribution, or by one or more motors running at slightly different actual speeds than the others. Some weight redistribution and motor power tuning in code can help.

**Wheels slip during strafing.** If the robot slides around more than expected, check that all four wheels are making good contact with the floor. If the robot is rocking on its chassis, the wheels aren't all loaded evenly. Adjusting the chassis flatness or adding a small amount of weight to the lighter corners can help.
