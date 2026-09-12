---
title: Drivetrain Overview
panelCategory: "Drivetrain"
date: 2026-05-08
description: A comprehensive overview of FTC drivetrain types and selection.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

The drivetrain is the system that moves your robot around the field. It's the foundation everything else sits on, and the choice you make here shapes what your robot can and can't do for the entire season. A good drivetrain lets you get where you need to go quickly and reliably. A bad one means you spend half the match fighting the field instead of scoring.

Choosing a drivetrain is genuinely one of the most important decisions your team makes each year. It affects your maneuverability, your ability to push or resist being pushed, how hard your robot is to build and program, and how much space is left over for your scoring mechanisms. Think it through carefully before you start cutting metal.

## Common Drivetrain Types in FTC

### Mecanum Drive

Mecanum drive uses four mecanum wheels (each with angled rollers around the outside) to allow the robot to move in any direction without rotating the chassis. You can drive forward, backward, and sideways, and you can even combine directions to move diagonally. This is called omnidirectional movement, and it's a major advantage in FTC where precise positioning matters a lot.

Mecanum drivetrains use four motors, one per wheel, making them power-hungry but very capable. The tradeoff is that strafing sideways loses some efficiency compared to forward/backward movement, and mecanum wheels generate less pushing force than simpler wheel setups because the angled rollers let the wheels slip sideways under heavy lateral loads.

For most competitive FTC teams, mecanum drive is the right choice. It gives you the flexibility to position the robot anywhere on the field quickly, which is almost always worth the slight reduction in raw pushing power.

### Differential Drive (Skid Steer)

A differential drive (also called skid steer) uses two sets of wheels on either side of the robot. To turn, the two sides run at different speeds. To go straight, both sides run at the same speed. It's the simplest drivetrain to build and to program.

The advantages are real: differential drive is mechanically robust, generates strong pushing force because all wheel friction is directed forward and backward, and has fewer parts to fail. The big limitation is that it cannot strafe. To move sideways, the robot has to rotate first, which costs time and makes precise field positioning harder.

Skid steer is a good choice for teams that want simplicity and pushing power, and whose game strategy doesn't require rapid lateral repositioning. In many FTC seasons, though, the ability to strafe makes mecanum the more competitive option.

### X-Drive

X-Drive also achieves omnidirectional movement, but it uses four standard omni wheels mounted at 45-degree angles to the chassis (forming an X shape when viewed from above). Like mecanum, it can strafe and move in any direction.

X-Drive is actually very fast when strafing, sometimes faster than mecanum. The downsides are that it's weaker in pushing force than mecanum, the angled mounting requires a non-rectangular chassis frame which is harder to design, and fitting mechanisms onto an X-drive chassis is often more complicated.

X-drive is used by some experienced teams but is generally considered harder to execute well than mecanum for the performance you get.

### Swerve Drive

Swerve drive is the most capable drivetrain type, but also the most complex by a significant margin. In a swerve drive, each wheel module can independently rotate to face any direction. This means the robot can move in any direction at full speed without the efficiency losses of mecanum's angled rollers.

In FTC, swerve drive is rare. Building a reliable swerve module that fits within the constraints of FTC (18x18x18 starting volume, limited motors) is a serious engineering challenge. Programming it is equally complex. A few high-level teams have built swerve drivetrains successfully, but for most teams the cost in time and complexity isn't worth it compared to a well-built mecanum drive.

## Which Drivetrain Should You Choose?

Here's a simple way to think about it.

If you're a rookie team or are building your first competitive robot: **build mecanum**. It's the industry standard for a reason. The omnidirectional movement pays off in almost every FTC game, and there's a huge amount of community knowledge, tutorials, and code support for mecanum drivetrains. You can buy complete mecanum kits from goBILDA or REV that make the build straightforward.

If you want maximum simplicity and don't need to strafe: skid steer is a legitimate option, especially for teams with limited build time. It won't be as maneuverable, but it's reliable and easy to build.

If you're an experienced team looking for a project: X-drive or swerve might be worth exploring, but make sure you have the time and skills to execute well. A mediocre swerve drive will lose to a well-built mecanum drive every time.

## Key Factors to Consider

When evaluating drivetrain options, think through these four things:

**Maneuverability**: how easily can the robot get to where it needs to be? Mecanum and X-drive win here. Skid steer and swerve (if done well) are somewhere in the middle.

**Pushing power**: how much force can the robot exert against field elements or other robots? Skid steer wins here. Mecanum is decent. X-drive is weaker.

**Complexity**: how hard is it to build and maintain? Skid steer is simplest. Mecanum is moderate. X-drive and swerve are the hardest.

**Chassis space**: how much room is left for your mechanisms? This depends heavily on the specific chassis design, not just the drivetrain type. A compact parallel plate mecanum chassis (see the Parallel Plate Drivetrain guide) leaves a large, flat top surface that's easy to build on.

Getting the drivetrain right is the first step toward building a competitive robot. Spend the time to understand your options, pick the one that fits your team's goals, and build it well.
