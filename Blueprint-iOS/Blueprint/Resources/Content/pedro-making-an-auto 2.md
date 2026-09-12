---
title: "Pedro Pathing: Making an Auto"
panelCategory: "Pedro Pathing"
date: 2026-03-28
description: Building a complete autonomous routine with Pedro Pathing.
tags: [completed, software, intermediate]
author: Ishaan Desai
published: true
---

# Making an Autonomous Routine with Pedro Pathing

Designing an autonomous routine involves defining a sequence of paths and subsystem actions to achieve a specific goal.

## Designing Your Path

- **Bezier Curves:** Use Bezier curves to define the robot's trajectory.
- **Pose Generation:** Use your robot's pose and heading to generate paths.
- **Path Segmenting:** Break down your routine into several smaller, manageable segments.

## Programming Your Auto

- **State Machines:** Use state machines to manage different parts of your autonomous routine.
- **Asynchronicity:** Ensure your autonomous routine is non-blocking and can handle simultaneous actions.
- **Path Following:** Use Pedro's `Follower` class to follow your paths.

### Basic Autonomous Example

```java
@Autonomous(name = "Basic Auto")
public class BasicAuto extends LinearOpMode {
    public Follower follower;

    @Override
    public void runOpMode() {
        // Initialize the follower
        follower = new Follower(hardwareMap);

        // Define your path
        Path path = new Path(new BezierLine(new Point(0, 0, Point.CARTESIAN), new Point(100, 100, Point.CARTESIAN)));

        waitForStart();

        // Follow the path
        follower.followPath(path);

        // Update the follower
        while (opModeIsActive() && follower.isFollowing()) {
            follower.update();
        }
    }
}
```

## Tips for Autonomous routines

- **Logging:** Use logging to track your robot's performance during autonomous routines.
- **Testing:** Test your autonomous routine several times to ensure consistency.
- **Subsystem Integration:** Integrate your subsystems for a more efficient and reliable autonomous routine.
