---
title: Types of OpModes
panelCategory: "Basics"
date: 2026-04-22
description: The difference between OpMode and LinearOpMode.
tags: [completed, software, beginner]
author: Blueprint
published: true
---

Every program you write for the robot is an OpMode. The SDK gives you two base classes: `OpMode` and `LinearOpMode`. Both are shown in the SDK samples as `BasicOpMode_Iterative` and `BasicOpMode_Linear`.

## OpMode

`OpMode` (also called an iterative OpMode) splits your program into methods the SDK calls for you:

- `init()` runs once when the driver presses Init.
- `init_loop()` runs repeatedly until Start is pressed.
- `start()` runs once when Start is pressed.
- `loop()` runs repeatedly until the OpMode is stopped.
- `stop()` runs once at the end.

You do not write your own loop. The SDK calls `loop()` over and over, and each call should handle one pass of logic and return.

Do not put a `while` loop or `sleep()` inside `loop()`. It blocks the SDK from running and the robot stops responding.

```java
@TeleOp(name="Basic: Iterative OpMode", group="Iterative OpMode")
public class BasicOpMode_Iterative extends OpMode
{
    private ElapsedTime runtime = new ElapsedTime();
    private DcMotor leftDrive = null;
    private DcMotor rightDrive = null;

    @Override
    public void init() {
        // These strings must match the names in the robot configuration.
        leftDrive  = hardwareMap.get(DcMotor.class, "left_drive");
        rightDrive = hardwareMap.get(DcMotor.class, "right_drive");

        // Most robots need one side reversed, because the axles point opposite ways.
        leftDrive.setDirection(DcMotor.Direction.REVERSE);
        rightDrive.setDirection(DcMotor.Direction.FORWARD);

        telemetry.addData("Status", "Initialized");
    }

    @Override
    public void init_loop() {
    }

    @Override
    public void start() {
        runtime.reset();
    }

    @Override
    public void loop() {
        double leftPower;
        double rightPower;

        // Left stick drives forward and back, right stick turns.
        double drive = -gamepad1.left_stick_y;
        double turn  =  gamepad1.right_stick_x;
        leftPower    = Range.clip(drive + turn, -1.0, 1.0) ;
        rightPower   = Range.clip(drive - turn, -1.0, 1.0) ;

        leftDrive.setPower(leftPower);
        rightDrive.setPower(rightPower);

        telemetry.addData("Status", "Run Time: " + runtime.toString());
        telemetry.addData("Motors", "left (%.2f), right (%.2f)", leftPower, rightPower);
    }

    @Override
    public void stop() {
    }
}
```

## LinearOpMode

`LinearOpMode` has one method, `runOpMode()`, that runs top to bottom. You initialize hardware, call `waitForStart()`, then write your own loop with `while (opModeIsActive())`.

Blocking calls like `sleep()` are allowed here. That makes it easier to write autonomous routines where steps happen in order.

Most teams use `LinearOpMode` for both TeleOp and autonomous. The examples on this site use it.

```java
@TeleOp(name="Basic: Linear OpMode", group="Linear OpMode")
public class BasicOpMode_Linear extends LinearOpMode {

    private ElapsedTime runtime = new ElapsedTime();
    private DcMotor leftDrive = null;
    private DcMotor rightDrive = null;

    @Override
    public void runOpMode() {
        telemetry.addData("Status", "Initialized");
        telemetry.update();

        // These strings must match the names in the robot configuration.
        leftDrive  = hardwareMap.get(DcMotor.class, "left_drive");
        rightDrive = hardwareMap.get(DcMotor.class, "right_drive");

        // Most robots need one side reversed, because the axles point opposite ways.
        leftDrive.setDirection(DcMotor.Direction.REVERSE);
        rightDrive.setDirection(DcMotor.Direction.FORWARD);

        waitForStart();
        runtime.reset();

        while (opModeIsActive()) {
            double leftPower;
            double rightPower;

            double drive = -gamepad1.left_stick_y;
            double turn  =  gamepad1.right_stick_x;
            leftPower    = Range.clip(drive + turn, -1.0, 1.0) ;
            rightPower   = Range.clip(drive - turn, -1.0, 1.0) ;

            leftDrive.setPower(leftPower);
            rightDrive.setPower(rightPower);

            telemetry.addData("Status", "Run Time: " + runtime.toString());
            telemetry.addData("Motors", "left (%.2f), right (%.2f)", leftPower, rightPower);
            telemetry.update();
        }
    }
}
```

Both programs drive the same two-motor robot. The iterative version seperates init and runtime into methods. The linear version keeps it in one place and you control the loop.

Both samples ship with the SDK in `FtcRobotController/src/main/java/org/firstinspires/ftc/robotcontroller/external/samples`. Copy the file into `TeamCode`, rename the class, and delete the `@Disabled` line so it shows up on the Driver Station.
