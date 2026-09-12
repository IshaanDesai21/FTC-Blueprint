---
title: Weight Distribution and Center of Gravity
panelCategory: "Design Principles"
date: 2026-06-28
description: Why your robot's center of gravity matters for stability, traction, and mechanism design.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

A robot's center of gravity (CG) is the single point where its total weight can be thought of as concentrated. Where that point sits, both horizontally and vertically, has a bigger effect on how your robot drives and behaves than most teams expect until they run into a problem caused by it.

## Why CG Height Matters

A robot with a high CG (weight concentrated up high, like a fully extended slide with a heavy mechanism at the top) is more prone to tipping. Tipping risk goes up during fast direction changes, sudden stops, and driving over field elements like ramps or uneven surfaces. A lower CG makes a robot more stable and predictable to drive, especially at higher speeds.

This is one of the reasons heavy components (battery, control hub, heavy motors) are often mounted low in the chassis when possible, while lighter components go higher up. It's also why a fully extended lift carrying a heavy game piece can make a robot noticeably more tippy than the same robot with the lift retracted.

## Why Horizontal CG Position Matters

Where the CG sits horizontally (front-to-back and side-to-side) affects traction and wheelie risk. If the CG is too far toward one end of the robot, that end carries more weight and has more traction, while the opposite end carries less weight and can lift or lose traction more easily.

This matters directly for mechanisms that extend outward, like an arm or slide reaching forward. As the mechanism extends, it shifts the effective CG of the whole robot (mechanism plus base) further in that direction. Extend far enough with enough weight at the end, and the robot can tip forward, especially if it's also trying to accelerate or decelerate at the same time.

## Estimating Tip Risk

A simple way to think about tip risk: draw a line between the ground-contact points on the side of the robot that could tip (for example, the front two wheels if you're worried about tipping forward). If the CG's horizontal position moves past that line, the robot will tip under gravity alone, no other forces required. If the CG stays behind that line but close to it, the robot is stable at rest but can still tip under additional forces like acceleration, deceleration, or an external bump.

The practical takeaway: the closer your CG gets to the edge of your wheelbase, the more vulnerable you are to being tipped by momentum, contact with another robot, or an uneven driving surface, even if the robot seems stable when sitting still.

## Managing CG in Mechanism Design

A few practical strategies teams use to manage CG, especially for mechanisms that extend or lift:

**Counterweighting.** Adding weight opposite the direction a mechanism extends can keep the overall CG closer to the center of the robot. This costs you total weight budget, so it's a tradeoff, not a free fix.

**Widening the wheelbase.** A wider or longer wheelbase pushes the tip-over line further from the center, giving you more margin before the CG crosses it. This has its own tradeoffs in maneuverability and legal size limits.

**Keeping heavy components low and central.** Batteries, control hardware, and other heavy but non-extending components are usually placed as low and as centered as reasonably possible, so they don't contribute extra tip risk.

**Limiting extension under load.** Some teams use software limits to prevent a slide or arm from extending to its full range while carrying a heavy game piece, if full extension would create real tip risk, trading maximum reach for stability when it matters.

## CG and Driving Feel

Beyond outright tipping, CG position affects how a robot "feels" to drive even when it's in no danger of tipping over. A robot with a CG shifted heavily toward the back can feel like it wants to spin out or lose front traction during hard acceleration. A robot with a CG shifted to one side can pull slightly in turns or feel unbalanced. These effects are usually minor compared to outright tipping, but drivers do notice them, especially in a robot they've driven extensively.

## Common Mistakes

**Not testing at full extension.** A robot that seems perfectly stable with all mechanisms retracted can be surprisingly tippy with a slide fully extended and a game piece in the mechanism. Always test stability in the actual worst-case configuration, not just the resting state.

**Ignoring dynamic forces.** A robot can be stable sitting still but still tip during a fast stop or a hard turn, because acceleration effectively shifts the "felt" CG in the direction opposite the acceleration. If your robot is borderline stable at rest, it may not be stable during aggressive driving.

**Adding weight high up without thinking about it.** It's easy to bolt an extra component onto the top of a robot late in the build season without considering what that does to CG height. Small additions add up, especially near the top of a tall robot.

Thinking about CG early, and re-checking it whenever you add a mechanism or extend your reach, is a cheap way to avoid a robot that tips over at the worst possible moment in a match.
