---
title: Design Principles
panelCategory: "General"
date: 2026-05-16
description: Core mechanical design principles every FTC builder should know.
tags: [hardware, intermediate, completed]
author: Blueprint
published: true
---

The robots that do well in FTC aren't always the ones with the most complex mechanisms. Usually, they're the ones that work consistently. A robot that scores 80% of the time every match will beat a robot that scores 100% in practice but breaks during elimination rounds. The gap between good robots and great robots often comes down to a set of design habits that experienced builders have picked up over years of competing. This guide covers the most important ones.

## Keep It Simple

Every component you add to a mechanism is another thing that can break, bind, fall off, or behave unexpectedly. The more moving parts you have, the harder it is to debug problems and the more likely something goes wrong during a match.

Before you add anything to your design, ask yourself: does this actually need to be here? Can I get the same result with fewer parts? A mechanism that achieves its goal in three steps is almost always better than one that achieves the same goal in seven steps. Simple designs are faster to build, easier to fix, and more reliable under stress.

This doesn't mean your robot has to be primitive. It means you should earn every piece of complexity you add. If a component isn't doing clear, useful work, take it out.

## Build for Robustness

FTC robots get bumped, pushed, dropped, and knocked around a lot, in the shop during testing and on the field during matches. If your mechanism only works when everything is perfect, it's going to fail at the worst time.

Think about your worst case, not your best case. When you're testing, don't just run the mechanism gently and see if it works. Push it hard. Hit it from the side. Run it repeatedly. See what breaks. If something breaks in your shop, that's good. You found it before a match. If it only breaks at competition, that's a very bad day.

Overbuilt is usually better than underbuilt, within reason. Add gussets to joints that see a lot of stress. Use multiple bolts where one bolt is borderline. If a mechanism feels flimsy when you shake it, fix it before you compete with it.

## Design for Replaceability

Things will break at competition. That is not a pessimistic statement. It is just the reality of running robots through multiple matches in a row under pressure. What separates experienced teams from new ones is how fast they can get a broken robot back on the field.

Design your mechanisms so that broken parts can be swapped in minutes, not hours. That means bolts instead of glue, standard off-the-shelf hardware instead of one-of-a-kind custom parts, and clear assembly order so a tired student at 10pm can still figure out how to put it back together.

Label your spare parts bin. Bring extras of the things most likely to break: motors, gears, the small structural pieces around high-stress joints, zip ties, and bolts. If you've ever had to skip a match because you were still fixing your robot, you understand why this matters.

## Weight Distribution

Where your weight sits on the robot affects how it handles on the field. A robot that's very heavy in the back will pitch forward when it brakes. A robot that's heavy on one side will drift and be harder to drive straight.

As a general rule, keep heavy things low and centered. The battery is usually the heaviest single item on an FTC robot. Try to mount it as low as possible in the chassis. The Control Hub and other electronics are lighter but should still be placed with balance in mind.

High center of gravity is especially bad if your robot is tall. A tall, top-heavy robot can tip over when it runs into another robot or drives over a field element. Keep mass close to the ground whenever you have a choice.

## Tolerances and Slop

Metal parts wear against each other over time. Bolts loosen from vibration. Bearings develop play from repeated loading. On a brand-new robot everything feels tight, but after 20 matches things start to rattle and drift.

A few habits will keep things tight longer. Use nylock nuts (the ones with a nylon insert that grips the bolt threads) on anything that vibrates or rotates. They won't back off on their own the way standard hex nuts do. For critical bolts, a drop of thread-locker like Loctite Blue 242 works well. It holds the bolt in place but can still be removed with a wrench if you need to.

For bearings, add a small amount of preload so there's no free play in the radial direction. On many FTC bearing blocks, eccentric nuts let you adjust the bearing position to dial this in.

Check all your hardware before competition. Run your mechanism, then go around with a wrench and feel for anything that's gotten loose. It takes five minutes and catches a lot of problems before they become match problems.

## Iteration Is Part of the Process

Your first design will not be your best design. That's true for experienced engineers too. The goal of your first build is to have something you can test and learn from, not to have the final answer.

When you test, watch what breaks or underperforms. Make one change at a time so you know what's making the difference. Document what you tried and what happened. Over multiple iterations, your design will get better and better, and you'll start to understand why it works instead of just hoping it does.

Budget time for this. If you spend the first eight weeks of build season perfecting CAD and only have two weeks to test, you're going to compete with your first physical design. That's almost always worse than building something rough early and iterating for six weeks. Build. Test. Fix. Repeat.

## Respect the Size Limit

FTC robots must fit inside an 18 by 18 by 18 inch cube at the start of the match. That's your starting configuration. Once the match starts, mechanisms can extend beyond that footprint, but they have to start inside it.

Plan your starting configuration before you start building. Sketch out where every mechanism sits when the robot is compacted. If you add a new mechanism late in the season without checking, you might find out at inspection that you can't fit in the sizing box, and then you're making emergency cuts on match day.

Use your full allowed volume. 18 inches in each direction is actually a decent amount of space. A common mistake is building a small, tight robot that doesn't take advantage of the allowed size, leaving performance on the table for no reason.

## Don't Overengineer

A mechanism that does one thing well is almost always better than a mechanism that tries to do five things and sort of does all of them. It's tempting to design something clever that handles every situation, but complex multi-function mechanisms are hard to build, hard to tune, and hard to fix when something goes wrong.

Look at the game and figure out what scores the most points. Build mechanisms that do those specific things really well. Resist the urge to add features just because they seem cool. If a feature doesn't directly help you score more points or play better defense, ask seriously whether you need it.

## Use Standard Hardware

goBILDA, REV Robotics, and Andymark all sell standardized parts designed to work in FTC robots. These parts are designed to work together, they're in stock (most of the time), and there's a large community of teams who have used them and can help you troubleshoot.

Custom machined parts look impressive, but they take a long time to design and make, they can't be replaced quickly at competition, and if the design is wrong you have to start over. Standard hardware can be reordered, borrowed from another team, or bought at a competition if you break something.

Use standard hardware as your default. Go custom only when standard parts genuinely can't do the job you need.
