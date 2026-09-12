---
title: Motion Profiling
panelCategory: "Control"
date: 2026-03-28
description: Learn how to use trapezoidal motion profiling with FTC drivetrains and single‑motor mechanisms.
tags: [completed, software, advanced, novideo]
author: Blueprint
published: true
---

# Motion Profiling

Motion profiling is a technique for moving motors smoothly by limiting not just maximum speed, but also acceleration and deceleration. In FTC, this is especially valuable for **drivetrains** and **single‑motor mechanisms** like arms or slides, because it reduces wheel slip, lowers mechanical stress, and improves positional repeatability.

---

## Why profile a drivetrain?

On a 4‑motor FTC drivetrain, slamming full power into the motors from rest can cause the wheels to break traction and skid. Motion profiling instead shapes the _target_ velocity (or position) so that the drivetrain accelerates and decelerates smoothly, which keeps the wheels rolling cleanly and makes autonomous and driver‑controlled motion more predictable.

---

## What is a trapezoid profile?

A **trapezoidal motion profile** has three phases:

- **Acceleration:** velocity ramps up from 0 to a maximum.
- **Cruise:** velocity stays constant.
- **Deceleration:** velocity ramps back down to 0.

The velocity vs. time graph looks like a trapezoid if the robot reaches max speed before slowing; if the distance is too short, the cruise phase disappears and you get a **triangular** profile. For most FTC drivetrain moves, trapezoidal profiles work well because they are simple and smooth.

---

## How profiling helps drivetrains

Instead of telling your PID controller “go to 3000 encoder ticks right now,” you tell it “here is the ideal position, velocity, and acceleration at this moment.” The profile becomes the _reference trajectory_, and the controller follows it. This approach is used in libraries like Road Runner and can be adapted to your own drivetrain code.

---

## Core kinematics

At the heart of trapezoidal motion profiling are basic constant‑acceleration equations:

$$v = v_0 + a \cdot t$$
$$x = x_0 + v_0 \cdot t + \tfrac{1}{2} a \cdot t^2$$

These equations let you compute the target position and velocity for each time step along the profile.

---

## Example 1: Single‑motor mechanism

This example shows a simple trapezoidal motion profile for a **single DcMotorEx** (e.g., an arm or slide) using a custom profile generator. The controller is PIDF‑based, and the profile is computed inline.

```java
import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.hardware.DcMotor;
import com.qualcomm.robotcore.hardware.DcMotorEx;
import com.qualcomm.robotcore.util.ElapsedTime;
import com.qualcomm.robotcore.util.Range;

public class SingleMotorProfile extends LinearOpMode {
    private DcMotorEx motor;
    private final ElapsedTime timer = new ElapsedTime();

    // control target
    private double startPos;
    private double targetPos = 2000; // encoder ticks

    // profile limits
    private double maxVel     = 1800; // ticks/sec
    private double maxAccel   = 2400; // ticks/sec^2

    // PID controller constants
    private double Kp = 0.01;
    private double Kd = 0.0004;

    @Override
    public void runOpMode() throws InterruptedException {
        motor = hardwareMap.get(DcMotorEx.class, "arm");
        motor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
        motor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
        motor.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);

        waitForStart();
        startPos = motor.getCurrentPosition();
        timer.reset();

        while (opModeIsActive()) {
            double t = timer.seconds();
            double error = targetPos - startPos;

            // compute acceleration time and distance
            double tAccel = maxVel / maxAccel;
            double dAccel = 0.5 * maxAccel * tAccel * tAccel;

            double setpoint, cmdVel;

            // Simplified trapezoidal logic
            if (Math.abs(error) < 2 * dAccel) {
                // Triangular profile
                double tPeak = Math.sqrt(Math.abs(error) / maxAccel);
                if (t < tPeak) {
                    setpoint = startPos + 0.5 * maxAccel * t * t * Math.signum(error);
                } else if (t < 2 * tPeak) {
                    double td = t - tPeak;
                    setpoint = startPos + (0.5 * maxAccel * tPeak * tPeak + maxAccel * tPeak * td - 0.5 * maxAccel * td * td) * Math.signum(error);
                } else {
                    setpoint = targetPos;
                }
            } else {
                // Full trapezoidal profile
                double dCruise = Math.abs(error) - 2 * dAccel;
                double tCruise = dCruise / maxVel;

                if (t < tAccel) {
                    setpoint = startPos + 0.5 * maxAccel * t * t * Math.signum(error);
                } else if (t < tAccel + tCruise) {
                    setpoint = startPos + (dAccel + maxVel * (t - tAccel)) * Math.signum(error);
                } else if (t < 2 * tAccel + tCruise) {
                    double td = t - tAccel - tCruise;
                    setpoint = startPos + (dAccel + dCruise + maxVel * td - 0.5 * maxAccel * td * td) * Math.signum(error);
                } else {
                    setpoint = targetPos;
                }
            }

            // Apply power using simple P-control for demo
            double currentPos = motor.getCurrentPosition();
            double pOutput = (setpoint - currentPos) * Kp;
            motor.setPower(Range.clip(pOutput, -1.0, 1.0));
            
            telemetry.addData("Setpoint", setpoint);
            telemetry.addData("Position", currentPos);
            telemetry.update();
        }
    }
}
```

---

## Notes and tuning tips

- Start with low `maxVel` and `maxAccel`.
- If the robot skips or slips, reduce acceleration first.
- Motion profiles are the foundation for consistent autonomous movement.
