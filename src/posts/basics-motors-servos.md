---
title: Basics of Motors and Servos
panelCategory: "Basics"
date: 2026-04-15
description: Controlling DC motors, servos, and continuous rotation servos in Java.
tags: [completed, software, beginner]
author: Blueprint
published: true
---

## DC Motors

DC motors are used for drivetrains and for high-torque mechanisms like arms, slides, and intakes.

### Getting the motor

Every device comes from `hardwareMap`. The string must match the name in the robot configuration.

```java
leftDrive = hardwareMap.get(DcMotor.class, "left_drive");
```

### Direction

If a motor spins the wrong way for how it is mounted, reverse it.

```java
leftDrive.setDirection(DcMotor.Direction.REVERSE);
rightDrive.setDirection(DcMotor.Direction.FORWARD);
```

On a drivetrain, the motors on one side are usually reversed because the axles point in opposite directions. Pushing the left stick forward must make the robot go forward, so set these from your first test drive.

### Power

Power ranges from -1.0 to 1.0. Zero stops the motor.

```java
leftDrive.setPower(0.5);
```

When you combine inputs, clip the result so it stays in range.

```java
leftPower  = Range.clip(drive + turn, -1.0, 1.0) ;
rightPower = Range.clip(drive - turn, -1.0, 1.0) ;
```

### Zero power behavior

`BRAKE` resists movement when power is zero. `FLOAT` lets the motor spin freely.

```java
leftDrive.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);
```

Use `BRAKE` for arms and slides so they hold position. For drivetrains either works.

## Servos

### Standard servos

A standard servo moves to a position between 0.0 and 1.0 and holds it.

```java
leftClaw = hardwareMap.get(Servo.class, "left_hand");
leftClaw.setPosition(MID_SERVO);
```

The actual angle at 0.0 and 1.0 depends on the servo and it's range setting. Find the positions you need by testing.

The SDK sample `RobotTeleopPOV_Linear` moves a pair of claw servos by holding a position offset and adjusting it a little each loop, rather than jumping straight to a position.

```java
public static final double MID_SERVO  = 0.5 ;
public static final double CLAW_SPEED = 0.02 ;

// Bumpers open and close the claw.
if (gamepad1.right_bumper)
    clawOffset += CLAW_SPEED;
else if (gamepad1.left_bumper)
    clawOffset -= CLAW_SPEED;

// The two servos are mirror images of each other.
clawOffset = Range.clip(clawOffset, -0.5, 0.5);
leftClaw.setPosition(MID_SERVO + clawOffset);
rightClaw.setPosition(MID_SERVO - clawOffset);
```

That sample also calls `sleep(50)` at the end of the loop to keep the claw from moving too fast.

### Continuous rotation servos

A CR servo spins instead of holding a position. You set power, not position.

```java
CRServo intake = hardwareMap.get(CRServo.class, "intake");
intake.setPower(1.0);
```

## Example OpMode

Drive on the sticks, an arm on Y and A, and a claw on the bumpers. This is the SDK sample `RobotTeleopPOV_Linear`, trimmed.

```java
@TeleOp(name="Robot: Teleop POV", group="Robot")
public class RobotTeleopPOV_Linear extends LinearOpMode {

    public DcMotor leftDrive  = null;
    public DcMotor rightDrive = null;
    public DcMotor leftArm    = null;
    public Servo   leftClaw   = null;
    public Servo   rightClaw  = null;

    double clawOffset = 0;

    public static final double MID_SERVO       =  0.5 ;
    public static final double CLAW_SPEED      =  0.02 ;
    public static final double ARM_UP_POWER    =  0.45 ;
    public static final double ARM_DOWN_POWER  = -0.45 ;

    @Override
    public void runOpMode() {
        double left;
        double right;
        double drive;
        double turn;
        double max;

        leftDrive  = hardwareMap.get(DcMotor.class, "left_drive");
        rightDrive = hardwareMap.get(DcMotor.class, "right_drive");
        leftArm    = hardwareMap.get(DcMotor.class, "left_arm");

        leftDrive.setDirection(DcMotor.Direction.REVERSE);
        rightDrive.setDirection(DcMotor.Direction.FORWARD);

        leftClaw  = hardwareMap.get(Servo.class, "left_hand");
        rightClaw = hardwareMap.get(Servo.class, "right_hand");
        leftClaw.setPosition(MID_SERVO);
        rightClaw.setPosition(MID_SERVO);

        telemetry.addData(">", "Robot Ready.  Press START.");
        telemetry.update();

        waitForStart();

        while (opModeIsActive()) {

            // Left stick drives, right stick turns.
            drive = -gamepad1.left_stick_y;
            turn  =  gamepad1.right_stick_x;

            left  = drive + turn;
            right = drive - turn;

            // Scale both down together if either exceeds 1.0.
            max = Math.max(Math.abs(left), Math.abs(right));
            if (max > 1.0)
            {
                left /= max;
                right /= max;
            }

            leftDrive.setPower(left);
            rightDrive.setPower(right);

            if (gamepad1.right_bumper)
                clawOffset += CLAW_SPEED;
            else if (gamepad1.left_bumper)
                clawOffset -= CLAW_SPEED;

            clawOffset = Range.clip(clawOffset, -0.5, 0.5);
            leftClaw.setPosition(MID_SERVO + clawOffset);
            rightClaw.setPosition(MID_SERVO - clawOffset);

            if (gamepad1.y)
                leftArm.setPower(ARM_UP_POWER);
            else if (gamepad1.a)
                leftArm.setPower(ARM_DOWN_POWER);
            else
                leftArm.setPower(0.0);

            telemetry.addData("claw",  "Offset = %.2f", clawOffset);
            telemetry.addData("left",  "%.2f", left);
            telemetry.addData("right", "%.2f", right);
            telemetry.update();

            sleep(50);
        }
    }
}
```

The left stick Y value is negated because the gamepad reports up as negative. Negating it makes pushing forward give positive power.
