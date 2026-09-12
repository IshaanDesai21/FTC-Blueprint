---
title: Linear Slides
panelCategory: "Mechanisms"
date: 2026-05-08
description: Building and using linear slide mechanisms for extending reach in FTC.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

Linear slides let your robot reach places it couldn't otherwise get to. Without them, your robot can only interact with things inside its own footprint. With them, you can extend an arm up to a high goal, push a scoring element onto an elevated shelf, or reach across a barrier. In almost every FTC season for the past several years, reaching something high has been a major part of scoring. If you want to be competitive, you almost certainly need some form of linear slide.

## What a Linear Slide Actually Is

A linear slide is a mechanism that extends in a straight line. The simplest version is two tubes or rails, where one slides inside or alongside the other. When powered, the inner stage moves outward along the outer stage. Add more stages and you get more total extension from the same starting length - this is called a cascade or telescoping slide.

The two most common configurations in FTC are vertical slides, where the robot extends upward to reach elevated goals, and horizontal slides, where the robot extends outward to reach across the field. Some robots use diagonal slides or combinations of both. The design you need depends on the game.

## Common Slide Options in FTC

### goBILDA V-Rail Slides

goBILDA's v-rail linear slides are probably the most popular choice in FTC right now. They use a v-shaped rail profile with matching v-groove bearings. The bearings ride in the groove, keeping the inner stage aligned as it moves. They're rigid, smooth, and available in standard lengths that work well with the rest of goBILDA's hardware ecosystem. If you're not sure what to use, start here.

### REV 15mm Extrusion

REV's 15mm aluminum extrusion can also be used as a slide rail with the right bearings or sliders. It's a bit lighter than the goBILDA v-rail system and integrates naturally with REV's other hardware. The tradeoff is that it takes a bit more setup to get running smoothly.

### Custom Slides

Some teams machine or fabricate their own slides from aluminum angle bracket or other material. This gives you full control over dimensions and geometry, but it takes more time and skill to build. Unless you have a specific reason to go custom, standard hardware will get you where you need to go faster.

## How to Power Your Slides

There are a few ways to move a linear slide. The method you choose affects how easy the mechanism is to build, how reliable it is, and how precisely you can control it.

### String-Driven Slides

String-driven (or cable-driven) slides are the most popular power method in FTC for good reason. A motor winds a string onto a spool. As the string gets shorter on one side, it pulls the slide stage outward. Another string handles retraction. It sounds simple because it is - and simple things break less often.

The main things to get right with string-driven slides are spool design and string tension. Your spool should have a lip on each side so the string winds on neatly without overlapping in ways that cause jumps. The string itself should have very little stretch - Dyneema or Spectra line works well. Monofilament fishing line also works and is cheap.

For retraction, you can either use a second string wound the opposite direction, or use gravity (on a vertical slide) to pull the slide back down when the motor releases tension. Gravity return is simpler but slower and less controlled. A second string gives you active retraction you can control.

Pulleys help redirect your string around corners. Use actual bearings-in-a-pulley if you can, rather than a fixed post - a rotating pulley has much less friction.

### Rack and Pinion

A rack and pinion drive uses a gear (the pinion) that rides along a toothed rail (the rack). The rack is attached to the moving slide stage. When the motor spins the pinion, it walks along the rack and pushes the stage outward.

Rack and pinion setups are very stiff and give you precise control over position because there's no string stretch involved. The downside is that they're heavier and harder to set up than string-driven systems. You'll see them on some high-end FTC builds, but string-driven is the more common choice for most teams.

## Bearing and Carriage Design

However you build your slides, the inner stage needs to stay aligned with the outer stage as it extends. If the inner stage can wobble or twist, you'll get binding, inconsistent extension, and eventually wear damage.

V-groove bearings are the standard solution on goBILDA v-rail slides. The bearings lock into the groove and prevent sideways movement. Make sure your bearing carriage is rigid - if the carriage itself flexes, you'll still get slop.

Nylon sliders are another option, where a low-friction plastic block rides between two rail surfaces. They're simple and work fine at low loads, but they wear down over time.

For multi-stage slides, the bearings on each stage need to be positioned so the slide loads them evenly. If the load point is way off center from your bearing positions, the stage will tilt under load.

## Position Control

Knowing where your slide is at any point in the match is really important. You have two main options.

The first is limit switches. A physical switch at the fully retracted and fully extended positions tells the code when the slide has hit its endpoints. This is simple and reliable for knowing the extremes, but it doesn't tell you anything about where the slide is in between.

The second is encoder counting. If your drive motor has an encoder (most FTC motors do), you can count the motor rotations to calculate how far the slide has moved. Pair this with a PID loop in your code and you can tell the slide to move to a specific position and hold there automatically. This is much more powerful and is how most competitive teams control their slides.

Always set a starting reference point. Usually you do this by fully retracting the slide at the start of the match and zeroing the encoder there.

## Weight and Load

The further your slide extends, the more torque it puts on your motor and on the slide mechanism itself. A heavy mechanism at the end of a fully extended two-stage slide creates a very large moment arm. This can bend your slides, strip your gears, or stall your motor.

Think about what you're putting at the end of your slides. A claw that weighs 200 grams is very different from an outtake system that weighs 800 grams. If your load is heavy, you may need stronger slides, a counterbalance, or a different overall approach to the mechanism.

## Common Mistakes

**Wobbly extension.** If your slide wobbles when extended, your bearings don't have enough preload, or the carriage is too short. Longer carriages give you more resistance to tilting. Add preload to your v-groove bearings by adjusting their eccentric nuts until there's slight friction on the rail.

**Binding.** If the slide catches or sticks partway through extension, the two stages aren't aligned. Check that your rails are parallel and that the carriage bearings aren't pinching the rail. Sometimes a single misaligned bolt is all it takes to cause binding.

**String slipping or skipping.** If your string slips off the spool or loses tension suddenly, check your spool lip height and make sure the string is anchored securely at both ends. A small amount of CA glue on the string anchor point can prevent it from slipping under load.

Getting linear slides right takes some patience. The first build probably won't be perfect, and that's fine. Test your slides under load, watch for where problems show up, and fix them one at a time. A smooth, reliable slide mechanism is one of the most satisfying things to get working on a competition robot.
