---
title: Common Practices
panelCategory: "Miscellaneous"
date: 2026-06-14
description: Habits that keep FTC code readable and working at competition.
tags: [software, manual, beginner, completed]
author: Blueprint
published: true
---

## Organize OpModes

OpModes live in `TeamCode/src/main/java/org/firstinspires/ftc/teamcode/`. Put autonomous programs in an `auto` package and TeleOp programs in a `teleop` package. One OpMode per file.

## Naming

- Variables and fields: `camelCase` (`frontLeftMotor`, `clawServo`)
- Classes: `PascalCase` (`MecanumDrive`, `TeleOpMain`)
- Constants: `UPPER_SNAKE_CASE` (`MAX_DRIVE_SPEED`, `CLAW_OPEN_POSITION`)

Name motors by what they do. The SDK samples use names like `front_left_drive` and `left_arm` in the robot configuration, and matching camelCase variables in code. `motor0` tells you nothing.

## Initialize hardware in one place

Put all `hardwareMap.get()` calls at the top of `runOpMode()`, before `waitForStart()`. A missing device then fails on init instead of during the match.

```java
@Override
public void runOpMode() {
    DcMotor frontLeft  = hardwareMap.get(DcMotor.class, "front_left_drive");
    DcMotor frontRight = hardwareMap.get(DcMotor.class, "front_right_drive");
    DcMotor backLeft   = hardwareMap.get(DcMotor.class, "back_left_drive");
    DcMotor backRight  = hardwareMap.get(DcMotor.class, "back_right_drive");
    Servo claw = hardwareMap.get(Servo.class, "claw");

    frontLeft.setDirection(DcMotor.Direction.REVERSE);
    backLeft.setDirection(DcMotor.Direction.REVERSE);
    frontRight.setDirection(DcMotor.Direction.FORWARD);
    backRight.setDirection(DcMotor.Direction.FORWARD);

    claw.setPosition(0.0);

    waitForStart();

    while (opModeIsActive()) {
        // loop
    }
}
```

## Set every motor direction

Set the direction of every motor yourself, even the ones that stay `FORWARD`. It documents what you expect and it does not depend on a default.

## Reset encoders at the start of autonomous

Encoder counts persist from whatever ran before. Reset every drive motor before using positions.

```java
frontLeft.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
frontLeft.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
```

## Telemetry

Call `telemetry.update()` once per loop, at the end. Each call sends what was added since the last call, so a second call in the same loop replaces the first.

```java
while (opModeIsActive()) {
    double power = -gamepad1.left_stick_y;
    frontLeft.setPower(power);

    telemetry.addData("Front Left Power", frontLeft.getPower());
    telemetry.update();
}
```

Before competition, remove debug lines and leave what the drivers need.

## Use ElapsedTime instead of sleep()

`sleep()` stops the whole OpMode. The gamepad is not read and nothing else updates. Use `ElapsedTime` to wait without blocking.

```java
ElapsedTime clawTimer = new ElapsedTime();
boolean clawClosing = false;

// inside the loop
if (gamepad1.a && !clawClosing) {
    claw.setPosition(1.0);
    clawTimer.reset();
    clawClosing = true;
}

if (clawClosing && clawTimer.seconds() > 0.5) {
    claw.setPosition(0.0);
    clawClosing = false;
}
```

The loop keeps running and the driver keeps control while the timer counts.

## Constants at the top

Put tunable numbers in named constants so there is one place to change them.

```java
public class TeleOpMain extends LinearOpMode {

    static final double MAX_DRIVE_SPEED = 0.8;
    static final double CLAW_OPEN_POSITION = 0.0;
    static final double CLAW_CLOSED_POSITION = 0.9;
    static final double SLOW_MODE_MULTIPLIER = 0.4;

    @Override
    public void runOpMode() {
        claw.setPosition(CLAW_OPEN_POSITION);
    }
}
```

## Test one thing at a time

Test each subsystem on its own before combining them. Check that the drivetrain drives, then that the arm moves, then run them together. Problems are easier to find when only one thing changed.

## Keep a working version

Before a competition, tag or branch the version of the code that works. If a last minute change breaks something you can go back to it instead of debuging in the pit.
