---
title: CAD Introduction
panelCategory: "CAD & Design"
date: 2026-05-23
description: Getting started with CAD for FTC robot design.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

CAD stands for Computer-Aided Design. It's a way to design your robot on a computer before you build anything. Instead of figuring out where things fit by holding parts up next to each other, you build the whole robot digitally first. This saves a ton of time, catches problems early, and gives you a clear picture of what you're building.

Most competitive FTC teams use CAD extensively. It's also something judges notice. Your Engineering Notebook looks a lot more polished when it includes CAD renderings of your robot's design process.

## Why Onshape?

There are many CAD programs out there: SolidWorks, Fusion 360, Inventor, and others. For FTC specifically, **Onshape** is the most popular choice, and for good reason:

- **It's free for students.** Onshape offers free education accounts. No license fees.
- **It runs in your browser.** Nothing to download or install. You just log in at onshape.com and start designing. Works on any computer.
- **It saves automatically to the cloud.** No losing your work to a hard drive failure. Every change is saved instantly.
- **Multiple people can work on the same file.** Like Google Docs but for 3D models. Your whole team can collaborate in real time.

Other software can work, but Onshape's accessibility makes it the standard recommendation for new teams.

## Setting Up Onshape

Go to onshape.com and create a free education account using your school email. Once you're in, you'll see your dashboard where you can create and manage documents.

Each Onshape document contains **Part Studios** (where you model individual parts) and **Assemblies** (where you put parts together into a full robot).

## Using FTC Part Libraries

Here's a big shortcut: you don't have to model every screw, bracket, and motor from scratch. Both goBILDA and REV Robotics publish official Onshape libraries with accurate 3D models of all their parts. You can import those directly into your designs.

To access them:
1. In Onshape, go to the "Public" tab in your document browser.
2. Search for "goBILDA" or "REV Robotics" to find their official libraries.
3. Once you find a library, you can link parts from it directly into your assembly.

This is a massive time-saver. Instead of drawing a goBILDA motor from scratch, you just insert the pre-made model and position it where you need it.

## Basic Workflow

Here's how most FTC teams approach CAD:

**Step 1: Sketch the concept.** Before opening Onshape, sketch your idea on paper. Know roughly what you're trying to build. CAD is faster when you have a clear direction.

**Step 2: Model custom parts.** If you're cutting custom plates or brackets, model those in a Part Studio. Most FTC teams work primarily with off-the-shelf hardware, so you might not need many custom parts.

**Step 3: Build the assembly.** Create a new Assembly and start inserting parts. Add your extrusion lengths, motors, wheels, and mechanisms. Use the "Mate" tools to constrain parts together the way they'd be bolted in real life.

**Step 4: Check clearances.** One of the biggest benefits of CAD is being able to spot collisions before they happen. Rotate the model, move joints, and make sure nothing runs into anything else during operation.

**Step 5: Export to your notebook.** Take screenshots or render images of the finished assembly for your Engineering Notebook. Judges appreciate clear visual documentation of your design.

## Learning Resources

Onshape has a built-in learning center called **Onshape Learning**. Their beginner courses cover the basics of modeling and assemblies in a few hours. For FTC-specific tutorials, the goBILDA and REV YouTube channels have videos showing how to use their parts in Onshape.

The biggest thing is to just start. CAD feels overwhelming at first, but once you've modeled a few simple parts and put them together, the workflow becomes natural quickly. Don't try to learn everything at once. Model something small and real, like your drivetrain chassis, and build from there.

## Tips for Beginners

Keep your assemblies organized by giving parts descriptive names. "Motor_FrontLeft" is much easier to work with than "Part 1 (1) (3)".

Learn keyboard shortcuts early. `C` for Circle, `L` for Line, `D` for Dimension. They speed up Part Studio work dramatically.

Use the "Section View" tool in assemblies to see inside your robot. This helps you check that wires and cables have clearance in tight spaces.

Save a version of your design before making major changes. Onshape keeps version history, but it's good practice to add manual version markers with a short note about what state the design was in.
