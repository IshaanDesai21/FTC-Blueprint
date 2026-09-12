---
title: NextFTC Subsystems
panelCategory: "Pedro Pathing"
date: 2026-03-28
description: Building modular and reusable robot mechanisms using the NextFTC framework.
tags: [completed, software, intermediate]
author: Ishaan Desai
published: true
---

NextFTC is a powerful command-based framework for FTC that helps you organize your robot code into **Subsystems** and **Commands**. This makes your code more modular, easier to test, and prevents hardware conflicts.

## What is a Subsystem?

A subsystem is a class that represents a physical mechanism on your robot (e.g., an Arm, an Intake, or a Lift). It contains the hardware objects (motors, servos) and the basic methods to control them.

### Creating a Subsystem

In NextFTC, every subsystem should implement the `Subsystem` interface. We also recommend using the **Singleton** pattern to ensure you only have one instance of each mechanism.

```java
public class Lift implements Subsystem {
    // Singleton instance
    public static final Lift INSTANCE = new Lift();

    private MotorEx liftMotor;

    private Lift() {
        // Private constructor for Singleton
    }

    @Override
    public void initialize() {
        liftMotor = new MotorEx("liftMotor").breakMode();
    }

    @Override
    public void periodic() {
        // This runs every single loop
        // Perfect for PID updates or safety checks
    }

    public void setPower(double power) {
        liftMotor.setPower(power);
    }
}
```

## Creating Commands

Commands are the actions your subsystems perform. For example, `LiftToPosition` or `IntakeCollect`.

```java
public class LiftToTop extends Command {
    public LiftToTop() {
        // Tell the scheduler this command needs the Lift
        requires(Lift.INSTANCE);
    }

    @Override
    public void start() {
        Lift.INSTANCE.setPower(0.8);
    }

    @Override
    public boolean isDone() {
        // Return true when the lift reaches the target
        return Lift.INSTANCE.isAtTop();
    }

    @Override
    public void stop(boolean interrupted) {
        Lift.INSTANCE.setPower(0);
    }
}
```

## Why This is Better

- **Automatic Conflict Resolution:** If you try to run two commands that both require the `Lift`, NextFTC will automatically stop the old one and start the new one.
- **Cleaner OpModes:** Your OpModes become a simple list of commands rather than a mess of loops and state variables.
- **Reusability:** You can easily reuse your subsystems and commands across different autonomous and TeleOp routines.
