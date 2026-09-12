---
title: Bearings and Reducing Friction
panelCategory: "Mechanisms"
date: 2026-06-27
description: How bearings work, where to use them, and how friction quietly kills mechanism performance.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

Friction is one of the least visible causes of a robot mechanism performing worse than expected. A slide that feels sluggish, an arm that takes more power than it should to lift, or a shaft that wobbles and binds are all frequently friction problems, not motor or gearing problems. Bearings are the main tool for keeping friction under control.

## What a Bearing Actually Does

A bearing lets one part rotate or slide relative to another with much less friction than if the two surfaces were in direct contact. Instead of metal or plastic sliding directly against metal or plastic, a bearing places rolling elements (balls, rollers, or a low-friction sleeve) between the moving parts, so most of the resistance comes from rolling rather than sliding.

Without a bearing, a rotating shaft pressed directly into a hole in your chassis will generate a lot of friction, wear the hole larger over time, and eventually develop enough slop to cause real problems: wobble, misalignment, and inconsistent mechanism behavior.

## Common Bearing Types in FTC

**Ball bearings** are the most common type, used on drivetrain axles, shafts, and anywhere a smooth, low-friction rotation is needed. They handle radial loads (perpendicular to the shaft) well and are available in standard sizes that match common FTC shaft diameters.

**Flanged bearings** are ball bearings with a built-in lip (flange) that also helps locate the bearing in a mounting hole and can take a small amount of axial (sideways, along the shaft) load.

**V-groove bearings** ride in a v-shaped channel, commonly used on linear slide rails. Rather than supporting a rotating shaft, they support a carriage that needs to travel smoothly in a straight line while resisting side-to-side and tip-over forces.

**Thrust bearings** are designed specifically to handle axial load, like the downward force on a rotating turret sitting on top of a support structure. A standard ball bearing isn't well suited to heavy thrust loads; a thrust bearing is built for exactly that.

## Where Bearings Matter Most

Any shaft that carries significant load and needs to spin freely should be supported by at least one bearing, and ideally two, spaced apart along the shaft. Two bearings resist tilting far better than one, especially if there's any load applied off to the side of the shaft rather than perfectly centered.

Linear slides depend heavily on properly preloaded bearings (see the linear slides guide for more detail on preload) to stay aligned as they extend without wobbling or binding.

Any rotating joint that carries real load, like a turret base or an arm pivot, benefits from a bearing rather than a bare shaft in a hole, both for smoother motion and to prevent the mounting hole from wearing out and getting sloppy over time.

## Reducing Friction Beyond Bearings

Bearings solve rotational and linear-rail friction, but a few other things matter too:

**Alignment.** A bearing can only do its job if the shaft or rail it's supporting is actually straight and properly aligned. A bent shaft or misaligned rail will bind even with good bearings, because the bearing is fighting the misalignment instead of just supporting a clean rotation or slide.

**Lubrication.** A small amount of appropriate lubricant (like a light machine oil or grease meant for small bearings) on bearings and any sliding contact points reduces friction and wear. Too much lubricant can attract dust and debris, which then increases friction, so use a light touch.

**Load path.** Where possible, design so that load passes through your bearings rather than through unsupported plastic or unsupported fasteners. A shaft that's only held by a single screw with no bearing support will wear that connection point quickly under repeated load.

## Diagnosing Friction Problems

If a mechanism feels like it needs more power than it should to move, or moves inconsistently, friction is a common suspect before you assume the motor or gearing is undersized. A few checks:

- Disconnect the mechanism from the motor (or power it down) and try moving it by hand. It should move relatively freely with only the expected resistance from things like return springs or gravity. If it feels gritty, stiff, or catches at certain points, that's friction, not motor sizing.
- Look for visible wobble or misalignment in shafts and rails while the mechanism is running.
- Check whether bearings spin freely on their own, off the robot, by hand. A bearing that doesn't spin smoothly by itself is worn out or contaminated and should be replaced.

## Common Mistakes

**Skipping bearings to save weight or cost on a "low priority" mechanism.** Any mechanism that gets used repeatedly over a season benefits from proper bearing support. The wear and friction from bare shafts in holes adds up quickly, especially past just a few competitions.

**Over-tightening bearing preload.** Bearings (especially v-groove bearings on slides) need some preload to remove slop, but too much preload adds friction and can even damage the bearing over time. Preload should remove wobble without making the mechanism noticeably harder to move by hand.

**Ignoring a bearing that's starting to feel gritty.** A bearing that no longer spins smoothly is on its way to failing. Replacing it early, before it seizes or damages the shaft it's supporting, is much cheaper than dealing with the failure during a competition.

Good bearing choices and careful alignment are unglamorous but genuinely high-leverage: they're often the difference between a mechanism that feels crisp and reliable and one that feels sluggish and unpredictable for reasons that are hard to pin down.
