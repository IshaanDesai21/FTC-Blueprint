---
title: 'Motors & Servos Guide'
panelCategory: "Electronics"
date: 2026-04-25
description: A hardware guide to selecting and using motors and servos in FTC.
tags: [hardware, beginner, completed]
author: Blueprint
published: true
---

Motors and servos are how your robot actually moves things. Choosing the right one for the job makes a huge difference in how well your mechanisms perform. This guide covers the physical hardware side: what the different options are, how to pick them, and how they connect to your robot. Programming them is a separate topic covered in the software guides.

## DC Motors

DC motors are the workhorses of FTC robots. They spin continuously in either direction, and you control how fast and which way by sending a power signal from the Control Hub. Motors are used for drivetrains, arms, lifts, intakes, and pretty much anything that needs continuous rotation or a lot of force.

### Gear Ratios and the RPM vs. Torque Tradeoff

Most FTC motors come with a built-in gearbox. The gear ratio determines the tradeoff between speed and torque. A high gear ratio (like 223:1 or 435:1) means the output shaft spins slowly but with a lot of turning force. A low gear ratio (like 30:1 or 60:1) means the shaft spins fast but with less force.

This tradeoff matters a lot for how you use the motor:

- **Drivetrain motors** want to be fast. A 312 RPM or 435 RPM motor gets your robot moving quickly across the field.
- **Arm and linear slide motors** need torque to lift things. A 60 RPM or 117 RPM motor gives you the force you need without stalling out.

A motor stalling (being held from moving by a load that's too heavy) draws a lot of current and generates heat. Choosing the right gear ratio means you're not fighting the load with an underpowered setup.

### Popular Motor Options

**goBILDA Yellow Jacket Motors** are the most popular choice in FTC right now. They come in a wide range of gear ratios: 30, 43, 60, 84, 117, 223, 312, 435, and 1150 RPM. They use a 6mm D-shaft output and the JST-VH connector for power. The mounting holes and shaft are standardized across all their ratios, which makes swapping ratios easy if you need to retune a mechanism.

**REV HD Hex Motor** runs at 6000 RPM unloaded (before gearing) and uses REV's hex shaft system. It's a good motor that pairs naturally with REV hardware and hex shaft components.

**REV Core Hex Motor** is a lower-power option with a built-in 72:1 gearbox. It's simpler and a bit cheaper, but it's not as capable as the HD Hex for demanding mechanisms.

### Stall Torque

Stall torque is the maximum amount of rotational force a motor can produce before it stops moving. It's listed in the motor's specs and gives you an upper bound on what the motor can handle. If you're trying to lift a heavy arm, you need a motor with enough stall torque at your chosen gear ratio to handle the load.

### Built-In Encoders

Most FTC motors have built-in quadrature encoders. These are sensors inside the motor that count how far the shaft has rotated. The encoder connects to the Control Hub through an additional encoder cable, and it lets you track position precisely. Encoders are what make it possible to drive to a specific position, count rotations, or maintain consistent speed. Most modern FTC builds rely on encoders heavily, so it's worth making sure your motors have them (all goBILDA Yellow Jackets and REV HD Hex motors do).

## Servos

Servos look like small motors, but they work differently. A standard servo moves to a specific angular position based on the signal it receives, rather than spinning continuously. They're used for things like claws, flippers, rotating turrets, and any mechanism that needs to snap to a precise position.

### Types of Servos

**Standard (positional) servos** move to a target angle and hold there. The range is usually 0 to 180 degrees, but many FTC-grade servos support a wider range, up to 270 degrees, when programmed via a servo programmer.

**Continuous rotation servos** behave more like motors. Instead of moving to an angle, they spin continuously. You control the speed and direction rather than the position. These are useful for intake rollers or other applications where you need a compact spinning mechanism without needing precise position control.

### Popular Servo Options

**REV Smart Robot Servo (SRS)** is a versatile servo that can be configured as either a standard positional servo or a continuous rotation servo. It also includes a built-in encoder, which is unusual for a servo and can be useful for certain applications.

**goBILDA Dual Mode Servo (25-2)** is another widely used option. It supports both positional and continuous modes and has solid torque for its size.

**Axon Mini and Axon Micro** are high-performance servos popular at the competitive level. They're programmable using the Axon programmer, which lets you configure things like the rotation range, maximum speed, and direction. This programmability makes them very flexible.

### Servo Torque Ratings

Servo torque is typically listed in kg-cm (kilogram-centimeters). A rating of 10 kg-cm means the servo can hold 10 kilograms at a distance of 1 centimeter from the shaft, or 1 kilogram at 10 centimeters. The further out the load is from the servo shaft, the more torque it takes to hold. Keep this in mind when designing mechanisms that put a lot of leverage on a servo.

## Physical Connections

**Motors** connect to the Control Hub using JST-VH connectors (for goBILDA motors) or bare wire with Anderson Powerpole connectors. The encoder cable is a separate JST-PH 4-pin connector that goes to the encoder port on the Control Hub.

**Servos** use a standard 3-wire connector: signal (usually white or yellow), power (red, +5V), and ground (black or brown). The ground wire goes on the outside edge of the servo port (away from the center of the Control Hub). Getting this backwards won't always break the servo immediately, but it's wrong and can cause issues. The Control Hub provides 5V power to servos directly through the servo ports.

## Heat

Motors get hot under load, especially at high current draws. If a motor on your robot is too hot to touch after a match, that's a sign something is off. Common causes include too much load for the gear ratio you're using, a mechanism that's binding or jamming, or code that's running the motor at full power against a hard stop for extended periods.

Persistent overheating shortens the motor's life. If you notice it, investigate the root cause rather than just letting it run hot.
