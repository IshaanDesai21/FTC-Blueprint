---
title: Belts, Chains, and Pulleys
panelCategory: "Mechanisms"
date: 2026-06-26
description: When to use belt, chain, or direct gear power transmission in an FTC mechanism.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

Once you decide how much reduction a mechanism needs, you still have to decide how to physically get power from the motor to the mechanism. Direct gearing is one option, but belts and chains let you transmit power across a distance, around obstacles, or between components that aren't lined up on the same axis. Each has different tradeoffs.

## Direct Gear Meshing

The simplest way to transmit rotational power is to mesh two gears directly. This works well when the motor and the driven shaft are close together and you want a compact, rigid connection. Gear meshing has very little slop when the gears are good quality and properly spaced, which makes it a solid choice for anything needing precise position control.

The downside is that gears need to be positioned at an exact center distance to mesh correctly, and they reverse the direction of rotation with each stage. If your motor and mechanism aren't naturally positioned to mesh directly, you'll need an idler gear or a different transmission method.

## Chain Drives

Chain (commonly #25 roller chain in FTC) connects two sprockets that don't need to be directly adjacent. Chain is strong, handles high torque well, and doesn't slip under load the way a belt can. It's a common choice for drivetrains, especially tank drives with multiple wheels on a shaft, because a single chain loop can drive several sprockets at once.

Chain does need proper tensioning. Too loose, and it can skip teeth or fall off the sprockets, especially under sudden torque changes. Too tight, and it adds unnecessary friction and wears out the sprocket teeth faster. Most teams use a tensioner (an idler sprocket that presses against the chain) or design their mounting holes as slots so a motor or shaft can be shifted slightly to set tension by hand.

Chain also transmits some vibration and noise, and it needs occasional lubrication to run smoothly and last through a season.

## Belt Drives

Timing belts (toothed belts that mesh with matching toothed pulleys) are lighter than chain and run quieter. Like chain, the teeth mean a timing belt doesn't slip under normal loads, unlike a plain flat or V-belt. Timing belt is a common choice for linear slide carriages and lighter mechanisms where weight savings matter.

The main tradeoff versus chain is strength: for very high-torque applications, chain generally holds up better. Belts are also somewhat more sensitive to precise pulley alignment; a pulley that's slightly twisted relative to its mate can cause the belt to walk to one side over time.

Like chain, belts need correct tension. A belt that's too loose can skip teeth under load; too tight adds friction and stresses the bearings on either end.

## Pulleys and Mechanical Advantage

Beyond just redirecting motion, a pulley system can also provide mechanical advantage, similar to a gear ratio, by using different sized pulleys or multiple wraps of string/cable. This shows up most often in string-driven linear slides, where the ratio between the spool diameter and the pulley layout affects both the speed and the force the slide can exert.

A larger spool moves more string per rotation, extending the slide faster but with less pulling force for a given motor torque. A smaller spool moves less string per rotation, extending slower but with more force. This is the same speed-versus-torque tradeoff as a gear ratio, just applied to a spool and string system instead of meshing teeth.

## Choosing Between Them

A rough way to decide:

- **Need maximum strength and can tolerate some noise and weight?** Chain.
- **Need to save weight and want quieter operation, with moderate loads?** Timing belt.
- **Need a compact, precise, low-slop connection and the geometry allows it?** Direct gear mesh.
- **Need to redirect a string or cable around a corner, or want mechanical advantage in a slide?** Pulley.

Many robots use a mix of all of these across different mechanisms. A drivetrain might use chain, a slide might use belt or string over pulleys, and a compact turret might use direct gears. Pick based on what each mechanism actually needs, not out of habit.

## Common Mistakes

**Wrong chain or belt length.** Measure the actual center distance between your sprockets or pulleys before ordering. A chain or belt that's slightly too short or too long either won't fit or won't tension properly.

**Misaligned sprockets or pulleys.** If the sprockets aren't in the same plane, the chain will rub against the sprocket flanges and wear unevenly, sometimes throwing itself off entirely. Double check alignment with a straightedge before running the mechanism under power.

**No tensioning method.** Chains and belts stretch slightly over time and with use. If you don't build in a way to adjust tension (slotted mounting holes, an idler sprocket, or a similar mechanism), you'll eventually have a loose, unreliable drive that needs to be rebuilt instead of just adjusted.

Picking the right transmission method, and setting it up carefully, saves a lot of maintenance headaches later in the season.
