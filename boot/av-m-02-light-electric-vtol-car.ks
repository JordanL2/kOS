RUNPATH("0:/vtol.ks",

// Vertical Control
//  Accel F
	0.8,
//  Z velocity PID Kp, Ki, Kd, Min, Max
	0.01, 0.001, 0.001, -0.01, 0.01,

//  Horizontal Control
//  Accel F
	0.5,
//  X velocity PID Kp, Ki, Kd, Min, Max
	3, 3, 0.01, -25, 25,
//  Y velocity PID Kp, Ki, Kd, Min, Max
	3, 3, 0.05, -30, 30,

//  Steering Control
//  Pitch momentum F, Roll momentum F, Yaw momentum F
	0.1, 0.02, 0.1,
//  Pitch PID Kp, Ki, Kd, Min, Max
	1, 0, 0, -1, 1,
//  Roll PID Kp, Ki, Kd, Min, Max
	1, 0, 0, -1, 1,
//  Yaw PID Kp, Ki, Kd, Min, Max
	1, 0, 0, -1, 1,

	{
		PARAMETER ch.
		SET return_val TO FALSE.

		SET rotors TO SHIP:PARTSTITLED("EM-16 Light Duty Rotor").
		FOR rotor IN rotors {
			rotor:GETMODULE("ModuleRoboticServoRotor"):SETFIELD("rpm limit", THROTTLE * 460).
			rotor:GETMODULE("ModuleRoboticServoRotor"):SETFIELD("torque limit(%)", 100).
		}

		SET rw TO SHIP:PARTSTITLED("Small Inline Reaction Wheel")[0].
		IF (SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" OR SHIP:STATUS = "PRELAUNCH") AND THROTTLE = 0 {
			rw:GETMODULE("ModuleReactionWheel"):DOACTION("deactivate wheel", TRUE).
		} ELSE {
			rw:GETMODULE("ModuleReactionWheel"):DOACTION("activate wheel", TRUE).
		}

		RETURN return_val.
	}

).
