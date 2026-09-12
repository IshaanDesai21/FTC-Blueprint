---
title: Wiring Best Practices
panelCategory: "Electronics"
date: 2026-05-01
description: Best practices for clean, reliable wiring on your FTC robot.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

Wiring might not be the most exciting part of building a robot, but it's one of the most important. A loose wire or a connector that wiggles free mid-match can stop your robot cold at the worst possible moment. Clean, well-organized wiring also makes it much faster to diagnose problems at a competition when you're on a tight timeline. Get the wiring right and you've eliminated an entire category of potential failures.

## Motor Wiring

Motors connect to the Control Hub using JST-VH connectors. Push the connector in firmly until it clicks. A connector that's partially seated will make intermittent contact and cause the motor to cut out unexpectedly.

After plugging in a motor cable, add a zip tie for strain relief. Loop the zip tie around the cable close to where it enters the port and attach it to a nearby standoff or frame member. This means if someone tugs the cable or it gets caught on something during a match, the force goes to the zip tie and the frame rather than pulling the connector out of the port.

Encoder cables (the small JST-PH connectors) also need to be secured. They're lightweight and easy to forget about, but a disconnected encoder means your code loses position tracking.

## Servo Wiring

Servo connectors are 3-pin connectors with signal, power (5V), and ground wires. The ground wire (black or brown) goes on the outside edge of the servo port, away from the center of the board. Check this every time you plug in a servo. The connectors are not keyed, so it's physically possible to plug them in backwards, which is bad for the servo.

Unlike motor connectors, servo connectors don't have a locking mechanism, so they can work loose if the cable is pulled or vibrates. Add a small piece of electrical tape over the connection, or use a servo wire retainer clip if your team has them.

## Power Wiring

The 12V battery connects to the Control Hub via an XT30 connector. The XT30 is a solid connector design, but it needs to be fully engaged: push it in until it seats firmly and the two halves are flush.

If you need to split power to multiple devices (like a servo power distribution board, or any 12V accessories), use the REV Power Distribution Block or a similar splitter. Don't try to daisy-chain XT30 connectors or splice wires without proper connectors. Loose or improvised power connections are one of the most common causes of robots losing power mid-match.

The main power switch (required by FTC rules) sits between the battery and the Control Hub. Make sure it's accessible and easy to hit quickly. Inspectors will check this.

## Sensor Wiring

I2C sensors (color sensors, distance sensors, etc.) use JST-SH 4-pin cables. These are the small, delicate connectors. A few things to keep in mind:

- Keep I2C cables short. Under about 1 meter is ideal. Long I2C cables are more susceptible to electrical noise, which can cause sensor readings to be unreliable or cause the sensor to drop off the bus entirely.
- Don't run I2C cables alongside high-current motor cables for long distances. The motor cables can induce noise into the sensor cables.
- When routing sensor cables near moving parts, leave enough slack that the cable doesn't get stressed when the mechanism moves.

## Cable Management Tips

Good cable management isn't just about looks. It directly affects reliability and repairability.

Use zip ties generously, but don't overtighten them. A zip tie that's cranked down too hard can cut into the cable insulation over time. Tighten them until they're snug and the cable doesn't move, then stop. Cut the tail flush with the zip tie head so there's no sharp point sticking out.

Route wires so they can't get caught in moving mechanisms. A spinning wheel or a sliding rail will shred a cable that gets in the way. Before you button up any mechanism, run through the full range of motion manually and watch every cable nearby.

Near rotating joints and sliding mechanisms, leave a small loop or arc of extra wire, not so much that it flops around, but enough that the cable doesn't pull tight as the mechanism moves. A cable under tension will eventually fail at the connector.

Label everything. A small piece of masking tape wrapped around a cable with a marker note ("FR Motor", "Color Sensor Left") makes debugging ten times faster at a competition when you're trying to figure out which wire goes where. You can also use colored electrical tape to color-code cables by function.

For bundles of wires running along the frame, cable spirals (split loom or spiral wrap) keep things tidy and protect the cables from rubbing against metal edges.

## Common Mistakes

A few mistakes that come up repeatedly on FTC robots:

**Plugging servo connectors in backwards.** As mentioned above, servo ports are not keyed. Always verify the ground wire (black) is on the outside before powering up. Running a servo backwards can damage it.

**Loose XT30 connections.** The robot runs fine at the workbench, then disconnects during a match. The XT30 that wasn't quite fully seated worked itself loose from the vibration and motion of the match. Check all XT30 connections before every match.

**Motor wires rubbing on the frame.** A cable routed over a sharp aluminum edge will wear through the insulation over the course of a season. Route cables through protected paths, add a piece of tape or heat shrink where a cable has to cross a sharp edge, and check cables periodically for signs of wear.

## Wiring Inspection

At FTC competitions, your robot will go through a technical inspection before you can compete. Inspectors look at wiring as part of this process. Loose wires, exposed conductors, and poorly secured cables can fail inspection and cost you time on competition day.

Keep wiring tidy, cover any exposed wire ends with heat shrink or electrical tape, and make sure no wire is able to contact another wire or the frame in a way that could cause a short. Clean wiring isn't just about passing inspection, it's about having a robot that actually works when it matters.
