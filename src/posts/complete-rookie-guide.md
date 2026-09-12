---
title: 'Complete Rookie Guide'
panelCategory: "Rookie Guide"
date: 2026-06-20
description: 'What a new team needs to know: the competition, the hardware, the first programs, and competition day.'
tags:
  - rookie
  - guide
published: true
---

This page is for a team that just formed. It covers the competition format, the hardware, the first TeleOp and autonomous programs, and what happens at a tournament. Read it in order or jump to the section you need.

## 1. The competition

FIRST Tech Challenge is for students in grades 7 through 12. A new game is released each September. Matches are played on a 12 by 12 foot field between two alliances, red and blue, of two teams each.

A match is 2 minutes 30 seconds:

- **Autonomous**, 30 seconds. The robot runs on its own.
- **Driver-controlled**, 2 minutes. Drivers control the robot with controllers. The last 30 seconds is the end game.

### Season timeline

1. **Kickoff**, early September. The game is revealed and the game manual is published.
2. **Build season**, September through December. Build, program, practice. Many regions hold scrimmages.
3. **Qualifiers**, roughly November through February depending on region. Teams play qualification matches, then the top ranked teams pick alliance partners for elimination matches. Winning alliances and award winners advance.
4. **Regional or state championships**, January through March.
5. **World Championship**, April, in Houston.

## 2. Roles

- **Drive coach**: stands with the drivers and calls strategy during matches.
- **Driver**: `gamepad1`. Drives the robot.
- **Operator**: `gamepad2`. Runs the mechanisms.
- **Programmers**: write and test the code.
- **Builders**: design and assemble the robot.
- **Documentation**: maintain the engineering portfolio, which judges use for awards.

On a small team one person covers several roles. Make sure each one is covered.

## 3. The game manual

FIRST publishes the game manual at kickoff. Read the robot rules, the field rules, and the scoring section before building anything. Robot size and weight limits, allowed parts, and what counts for points are all in there. An illegal robot fails inspection and cannot play.

## 4. Hardware

**Electronics**

- REV Control Hub. Runs the code and connects to the Driver Station over Wi-Fi.
- REV Driver Hub or an Android phone for the Driver Station.
- 12 V FTC-legal battery.
- REV Expansion Hub, optional, for more ports.

**Motors and servos**

- Four DC motors with encoders for a mecanum drivetrain. goBILDA Yellow Jacket and REV HD Hex motors are common.
- Servos for mechanisms.

**Sensors**

- Encoders, built into the motors.
- IMU, built into the Control Hub.
- A webcam for vision. Optional for a first robot.

**Wiring**

- JST VH motor cables and JST PH encoder cables.
- Servo cables.
- XT30 battery cable and a power switch.

**Structure**

- goBILDA or REV extrusion, brackets, and fasteners.

## 5. Control Hub ports

- **Motor ports 0-3**, JST VH. Each has a matching encoder port next to it.
- **Servo ports 0-5**.
- **I2C ports 0-3** for color and distance sensors.
- **Digital ports** for touch sensors and limit switches.
- **Analog ports** for potentiometers.
- **USB** for a webcam.
- **XT30** for battery power.

Mount the hub where it will not be hit and where the ports are reachable.

## 6. Building the first robot

Build the drivetrain first and get it driving before adding anything else.

Mecanum wheels are the standard choice. Each wheel has rollers at 45 degrees, which lets the robot strafe and rotate in place. Four wheels, one motor each.

- Viewed from above, the rollers must form an X. If the robot rotates when it should strafe, a wheel is in the wrong corner.
- Keep the robot low and the weight spread over all four wheels.
- Leave slack in the motor cables so nothing pulls when the robot moves.

Do not build a large mechanism before the drivetrain is reliable. A robot that drives well and scores a little in TeleOp beats one that does everything and breaks.

## 7. Wiring

Loose connectors cause more match failures then code does.

- Use the same device names everywhere: `frontLeft`, `frontRight`, `backLeft`, `backRight`, `slideMotor`, and so on.
- Write down which port each motor and servo is in.
- Put the power switch between the battery and the hub.
- Zip tie cables to the frame and keep them away from moving parts.
- Pull on every connector before every match.

See [Wiring and Configuration](/software/basics-wiring).

## 8. Software setup

Code is written in Java in Android Studio.

1. Install Android Studio.
2. Clone [FtcRobotController](https://github.com/FIRST-Tech-Challenge/FtcRobotController).
3. Open it and wait for the Gradle sync.
4. Team code goes in the `TeamCode` module.

Deploy over USB or over the hub's Wi-Fi. See [Android Studio Setup](/software/basics-android-studio).

Update to the current SDK version each season. Some updates are required to be legal at competition.

## 9. Robot configuration

The Driver Station stores a configuration that maps names to ports.

1. In the Driver Station app, open the menu and choose Configure Robot.
2. Create a new configuration.
3. For each motor and servo port in use, pick the device type and type the name used in code.
4. Save and activate it.

The name in the configuration and the string in `hardwareMap.get()` must match exactly.

## 10. First TeleOp

```java
package org.firstinspires.ftc.teamcode;

import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;
import com.qualcomm.robotcore.eventloop.opmode.TeleOp;
import com.qualcomm.robotcore.hardware.DcMotor;

@TeleOp(name = "Drive TeleOp")
public class DriveTeleOp extends LinearOpMode {

    DcMotor frontLeft, frontRight, backLeft, backRight;

    @Override
    public void runOpMode() {
        frontLeft  = hardwareMap.get(DcMotor.class, "frontLeft");
        frontRight = hardwareMap.get(DcMotor.class, "frontRight");
        backLeft   = hardwareMap.get(DcMotor.class, "backLeft");
        backRight  = hardwareMap.get(DcMotor.class, "backRight");

        frontLeft.setDirection(DcMotor.Direction.REVERSE);
        backLeft.setDirection(DcMotor.Direction.REVERSE);

        waitForStart();

        while (opModeIsActive()) {
            double y  = -gamepad1.left_stick_y;
            double x  =  gamepad1.left_stick_x;
            double rx =  gamepad1.right_stick_x;

            double denominator = Math.max(Math.abs(y) + Math.abs(x) + Math.abs(rx), 1);

            frontLeft.setPower((y + x + rx) / denominator);
            frontRight.setPower((y - x - rx) / denominator);
            backLeft.setPower((y - x + rx) / denominator);
            backRight.setPower((y + x - rx) / denominator);

            telemetry.addData("Forward", y);
            telemetry.addData("Strafe", x);
            telemetry.addData("Rotate", rx);
            telemetry.update();
        }
    }
}
```

[Teleop Introduction](/software/teleop-introduction) and [Teleop Beginner](/software/teleop-beginner) explain each part.

## 11. First autonomous

Autonomous is the first 30 seconds. Even driving to a scoring position and parking is worth points. The simplest reliable method is driving by encoder counts.

```java
static final double TICKS_PER_INCH = 45.0;

public void driveForward(double inches, double power) {
    int ticks = (int) (inches * TICKS_PER_INCH);

    frontLeft.setTargetPosition(frontLeft.getCurrentPosition() + ticks);
    frontRight.setTargetPosition(frontRight.getCurrentPosition() + ticks);
    backLeft.setTargetPosition(backLeft.getCurrentPosition() + ticks);
    backRight.setTargetPosition(backRight.getCurrentPosition() + ticks);

    frontLeft.setMode(DcMotor.RunMode.RUN_TO_POSITION);
    frontRight.setMode(DcMotor.RunMode.RUN_TO_POSITION);
    backLeft.setMode(DcMotor.RunMode.RUN_TO_POSITION);
    backRight.setMode(DcMotor.RunMode.RUN_TO_POSITION);

    frontLeft.setPower(power);
    frontRight.setPower(power);
    backLeft.setPower(power);
    backRight.setPower(power);

    while (opModeIsActive() && frontLeft.isBusy() && frontRight.isBusy()) {
        telemetry.addData("Driving", "%.0f in", inches);
        telemetry.update();
    }

    frontLeft.setPower(0);
    frontRight.setPower(0);
    backLeft.setPower(0);
    backRight.setPower(0);
}
```

```java
waitForStart();
driveForward(24, 0.5);
```

Reset the encoders at init with `STOP_AND_RESET_ENCODER` first. `TICKS_PER_INCH` is about 45 for a 312 RPM goBILDA motor on a 96 mm wheel. Measure it on your robot. Full details in [Encoder Autonomous Introduction](/software/encoder-autonomous-introduction).

## 12. Engineering portfolio

Judged awards are based on an interview and the engineering portfolio, a short document that describes the team and the design process. It should include:

- Who is on the team and what each person does.
- What the team decided to focus on after reading the game manual, and why.
- Design iterations, including ones that did not work and what was learned.
- Test data.
- Outreach: events the team ran or attended, who was reached, and what came of it. Several judged awards depend on this, so record it as it happens.

Keep notes from the first meeting. Writing the portfolio the week before a tournament from memory does not work. The Inspire Award, the top award at an event, is based heavily on the portfolio and interview.

## 13. Competition day

**Before**

- Charge the Control Hub, Driver Hub, and at least two batteries.
- Pack spare parts, a screwdriver set, zip ties, tape and a spare servo.
- Deploy the code you intend to run and test it that morning.

**Inspection**

- Every robot is inspected before it can play. Know your robot's size and weight and have it inside the limits.

**Matches**

- Check the schedule and be at the field early.
- The drive coach talks, the drivers drive.
- After each match write down what broke or what did not work.

**Between matches**

- Fix things that will cost you a match first. Everything else waits.

**Scouting**

- Watch other teams and note what they score reliably. You will use this at alliance selection.

## 14. More

- [gm0.org](https://gm0.org): community-maintained guide to FTC hardware, software, and strategy.
- The FTC Discord for questions.
- FIRST's YouTube channel for game reveals and official training.

Pages on this site to read next, in order:

1. [Getting Started](/software/getting-started)
2. [Android Studio Setup](/software/basics-android-studio)
3. [Wiring and Configuration](/software/basics-wiring)
4. [Motors and Servos](/software/basics-motors-servos)
5. [Types of OpModes](/software/basics-types-of-opmodes)
6. [Teleop Introduction](/software/teleop-introduction)
7. [Teleop Beginner](/software/teleop-beginner)
8. [Finite State Machines in TeleOp](/software/teleop-fsm)
9. [Encoder Autonomous Introduction](/software/encoder-autonomous-introduction)
10. [Universal IMU Guide](/software/sensors-imu)
