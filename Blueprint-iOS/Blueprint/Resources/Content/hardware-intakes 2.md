---
title: Intakes
panelCategory: "Mechanisms"
date: 2026-04-22
description: Designing effective intake mechanisms for collecting game elements.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

An intake is the part of your robot that picks up game elements from the field. In FTC, those elements vary season to season - balls, rings, cubes, cones, specimens - but the job of the intake stays the same: grab the element reliably, get it into the robot, and don't drop it. A good intake works quickly, handles imperfect positioning, and almost never jams. A bad intake costs you points every single match, even if every other mechanism on your robot is perfect.

## Types of Intakes

There are a few main intake styles you'll see in FTC. Each one has situations where it works well, and situations where it doesn't.

### Roller Intakes

Roller intakes are the most common style in competitive FTC. The idea is simple: a spinning roller or set of rollers sits at the front of the robot. When you drive toward a game element, the rollers spin inward and pull it in. The spinning action does the work for you, so you don't have to align perfectly - the roller grabs the element and drags it in even if your approach angle is a little off.

Roller intakes are almost always the first choice for picking up small, round elements like balls or rings. They're fast, reliable, and pretty forgiving. The downside is that they need a motor, and they can sometimes spit elements back out if the geometry isn't set up right.

### Claw and Scoop Intakes

A scoop or passive intake doesn't have any spinning parts. Instead, the robot literally drives into the element and scoops it up. Think of a shovel - you push it under the element and it comes along for the ride.

These are simpler to build because there's no motor involved. But they require much more precise driving, and they don't work well for elements that are round or that roll away easily. You'll usually see scoop-style intakes for blocks or other elements that sit flat on the ground and don't move much when you approach.

### Belted Intakes

A belt intake works a lot like a roller intake, but instead of a spinning cylinder, you have a flat belt moving in a loop. The belt surface contacts the element and carries it inward. Belted intakes can cover more surface area than a single roller, which helps with elements that are larger or oddly shaped. They're a bit more complex to build and tension correctly, but they're worth knowing about.

## Roller Intake Details

Since roller intakes are the most widely used, let's go deeper on how they actually work.

### Compliant Wheels vs. Hard Wheels

The material of your rollers matters a lot. Hard plastic or metal rollers can work, but they're unforgiving - if your geometry is slightly off or the element isn't perfectly positioned, the roller just pushes it away instead of grabbing it.

Compliant wheels are much better for most intake applications. These are wheels made from rubber, foam, or flexible plastic (like goBILDA's flex wheels). When they contact a game element, they squish slightly and wrap around it a little. That squish creates more surface contact and grips the element even when the fit isn't perfect. Think of it like grabbing something with a soft hand versus a metal clamp.

For foam rollers, you can cut foam pool noodles to length and slide them over a dowel or axle. They work surprisingly well for soft, grippy contact. For something more durable, flex wheels from goBILDA are a popular choice on competitive teams.

### Motor and Gear Ratio

You want your intake rollers spinning fast enough to reliably pull elements in. Too slow and the element barely moves; too fast and it might bounce right through. A typical intake runs somewhere in the range of 200 to 400 RPM at the rollers, but the right speed depends on your element and your design - you'll tune this during testing.

Don't over-torque a small motor. Intake motors are usually not stalled, so you can use a motor with a light gearbox. A 3:1 or 5:1 external gear ratio is common. If you find your intake is jamming and killing the motor, either widen the intake opening, choose softer rollers, or reduce the gear ratio.

### Direction Control

The rollers need to spin inward, toward the robot, when you're collecting. During teleop, you'll usually map this to a button that runs the intake forward. You'll also want a button to reverse the intake - sometimes elements get stuck, and running the roller backward clears the jam.

If your intake is at the end of an arm or a flipper, the inward direction depends on the current position of the mechanism. This is worth thinking about in your code.

## Width and Geometry

A wider intake is more forgiving. If your intake is only two inches wide and you're trying to pick up a ball, you need to be very precise with your driving. If your intake is eight inches wide, you have a lot more room to be a little off and still collect the element.

The catch is that FTC robots must start within an 18 by 18 by 18 inch cube. That's your size limit at the beginning of the match. A wide intake might fold in or retract for your starting configuration, then extend out when the match starts. Many competitive teams build intakes that flip out from the robot's footprint during initialization.

Plan your geometry before you build. Think about where the element sits on the field, how high off the ground it is, and what angle your roller needs to be at to meet it. Sketch it out or model it in CAD if you can.

## Intake Speed and Reliability

Fast intakes feel satisfying, but speed isn't everything. What you really want is consistent collection. An intake that picks up the element 95% of the time is much more valuable than one that picks it up instantly 60% of the time and misses the rest.

Test your intake at different approach angles, different speeds, and with elements in slightly different positions. Watch for elements that bounce out, get redirected sideways, or cause the robot to push the element away instead of collecting it. Each of these failure modes has a fix, but you have to see them first.

## Common Problems

**Elements bouncing out.** This usually means the intake opening is too wide, or there's nothing stopping the element after it enters. Add a funnel shape or side walls to guide the element inward. A second roller or a curved surface that deflects the element deeper into the robot can also help.

**Jamming.** If elements get stuck in the intake, the opening geometry is probably too tight. Widen the entrance, add a chamfer or angled surface to guide elements in, or try softer rollers that compress instead of blocking.

**Inconsistent collection.** Sometimes the intake works and sometimes it doesn't. This is usually a geometry problem - the rollers aren't positioned right relative to where the element sits. Adjust the height or angle of your roller until it makes consistent contact with every element you approach.

## Testing and Iterating

The best teams rebuild their intake multiple times before they lock in a design. That's normal. After your first version is built, set up a simple test: put elements on the floor and drive toward them at different angles and speeds. Count your successes and failures. Identify what's going wrong, make one change at a time, and test again.

Make sure your intake is easy to adjust. Use slots instead of fixed holes where you can, so you can slide the roller forward or backward to tune the position. The faster you can make and test changes, the faster you'll land on a design that actually works.
