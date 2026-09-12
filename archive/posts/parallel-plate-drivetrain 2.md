---
title: Parallel Plate Drivetrain
panelCategory: "Drivetrain"
date: 2026-05-12
description: Building a parallel plate chassis for your FTC mecanum drivetrain.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

The parallel plate drivetrain is a chassis design used by a large number of competitive FTC teams. It's not a drivetrain type by itself (it's almost always paired with mecanum wheels), but rather a way to build the physical structure that holds everything together. Once you understand why it works and how to build one well, it becomes a go-to approach for a reason: it's rigid, compact, and leaves a huge clean surface on top for all your scoring mechanisms.

## What Is a Parallel Plate Drivetrain?

The core idea is simple. Two flat plates run along the left and right sides of the robot, parallel to each other. The motors and wheels mount between these plates, with the wheels poking out to the sides. Cross-members (structural pieces running left-to-right between the plates) connect the two sides and hold everything at the correct width.

That's it. Two plates, some cross-members, four motors, four wheels. The result is a very stiff, low-profile chassis that can be sized to fit neatly within FTC's 18x18x18 inch starting volume constraint.

## Why Teams Use It

The parallel plate design has a few properties that make it popular at the competitive level.

The chassis is extremely rigid. Because the side plates are continuous flat sheets of material, they resist twisting and flexing much better than a frame built from individual tubes or channel pieces joined at corners. Rigidity matters for mecanum wheels: if the chassis can twist, the wheels don't all stay in the same plane, and strafing performance suffers.

The top surface is completely open. There are no cross-members running across the top (they run underneath, between the plates). This gives you a large, flat, unobstructed area to mount your mechanisms, electronics, and battery. Teams often drop a flat plate across the top as a "second floor" for even more mounting space.

Motors are easy to swap. They mount to the inside faces of the side plates with bolts. Replacing a motor takes a few minutes, which matters at competition when you're between matches.

## Materials

The side plates are most commonly made from one of three materials:

**Aluminum** (typically 1/8" or 1/4" thick) is the most popular choice. It's stiff, strong, machinable with standard shop tools, and light enough for FTC. 1/8" aluminum is sufficient for most builds. 1/4" adds weight but virtually no flex.

**Polycarbonate** (Lexan) is lighter than aluminum and tough enough to absorb impacts without cracking, but it's not as stiff. Some teams use it for weight savings, accepting a small amount of flex.

**HDPE plastic** (high-density polyethylene) is easy to cut and drill, and it doesn't rust or corrode. It's less rigid than aluminum but works well for teams without metal cutting equipment.

For cross-members, REV 15mm extrusion, goBILDA channel, or aluminum standoffs are all common. REV and goBILDA hardware both have standardized hole patterns that make attaching things straightforward.

## How to Build One

Here's the basic sequence for putting together a parallel plate drivetrain.

**Design the plates first.** Decide on your chassis dimensions (more on that below) and lay out the hole pattern. You need holes for the motor mounts, for the cross-member attachment points, and for any electronics or mechanism mounts you already know you'll need. Many teams use CAD software (Onshape is free and popular in FTC) to design the plates before cutting them.

**Cut and drill the side plates.** If you have access to a CNC router or laser cutter, use it. The hole patterns need to be accurate. Hand drilling with a drill press is also fine, but take your time and use a center punch to prevent the drill bit from wandering.

**Install the motors.** The motors mount to the inside face of each side plate. The motor's output shaft pokes through a hole in the plate to reach the wheel on the outside. Make sure the motors are aligned properly: the shaft should be perpendicular to the plate face, not at an angle.

**Attach the wheels.** The mecanum wheels go on the outside of the plates. Use the correct wheel on each corner (see the Mecanum Wheels guide for the X-pattern orientation).

**Connect the cross-members.** Attach your cross-members (extrusion, channel, or standoffs) between the two plates to lock the width. The cross-members typically run under the chassis (bottom) and sometimes at the top rear. The goal is to hold the two plates exactly parallel and square to each other.

## Common Dimensions

FTC robots must fit in an 18x18x18 inch cube at the start of a match. Most parallel plate mecanum drivetrains end up somewhere in the range of 13 to 16 inches wide and 13 to 16 inches long. This leaves room in all directions for expansion once the match starts.

A common configuration is around 14 inches wide (outside of wheels to outside of wheels) and 14 to 15 inches long. This gives you a reasonably compact footprint while still leaving enough room to mount 4-inch mecanum wheels comfortably.

## Things to Watch Out For

**The plates must be parallel and square.** If one plate is even slightly tilted relative to the other, the wheels won't run in true parallel planes. The result is a robot that drifts or doesn't strafe cleanly. Use a machinist's square or a flat reference surface to verify alignment when assembling. If you're using a drill press to make the hole patterns, drilling a matched set of holes in both plates at the same time (clamped together) is the most reliable way to ensure they match.

**Motor shaft alignment matters.** The shaft needs to pass cleanly through its hole in the side plate without rubbing. A misaligned motor will bind, run hot, or wear through the bearing over time. Check that each motor sits flush against the plate with the shaft centered in its hole.

**Leave room for wiring.** The inside of the chassis, between the plates, is where your motor cables live. Plan cable paths before finalizing the design. Motor cables need to reach the Control Hub (which is typically mounted on top of the chassis), and they shouldn't be pinched between the motor body and the plate.

## A Design That Scales

One of the reasons the parallel plate drivetrain has stayed popular for years is that it scales well. Once your team has built one and understands how it works, the next season's version gets faster to design and build. The core structure is always the same, just tuned for the new game's requirements. That accumulated knowledge is valuable, and the parallel plate chassis is a design worth investing in.
