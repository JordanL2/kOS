RUNPATH("0:/vtol.ks",

// Vertical Control
//  Accel F
	1.6,
//  Z velocity PID Kp, Ki, Kd, Min, Max
	0.005, 0.0005, 0.00005, -0.1, 0.1,

//  Horizontal Control
//  Accel F
	0.5,
//  X velocity PID Kp, Ki, Kd, Min, Max
	6, 0.6, 0.06, -25, 25,
//  Y velocity PID Kp, Ki, Kd, Min, Max
	6, 0.6, 0.06, -30, 30,

//  Steering Control
//  Pitch momentum F, Roll momentum F, Yaw momentum F
	0.5, 0.1, 0.2,
//  Pitch PID Kp, Ki, Kd, Min, Max
	0.3, 0, 0, -1, 1,
//  Roll PID Kp, Ki, Kd, Min, Max
	0.3, 0, 0, -1, 1,
//  Yaw PID Kp, Ki, Kd, Min, Max
	0.5, 0.1, 0.02, -1, 1,

	{
		PARAMETER ch.
		SET return_val TO FALSE.

		SET rotors TO SHIP:PARTSTITLED("EM-16 Light Duty Rotor").
		FOR rotor IN rotors {
			rotor:GETMODULE("ModuleRoboticServoRotor"):SETFIELD("rpm limit", THROTTLE * 460).
			rotor:GETMODULE("ModuleRoboticServoRotor"):SETFIELD("torque limit(%)", 100).
		}

		SET rws TO SHIP:PARTSTITLED("Advanced Inline Stabilizer").
		IF (SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" OR SHIP:STATUS = "PRELAUNCH") AND THROTTLE = 0 {
			FOR rw IN rws {
				rw:GETMODULE("ModuleReactionWheel"):DOACTION("deactivate wheel", TRUE).
			}
		} ELSE {
			FOR rw IN rws {
				rw:GETMODULE("ModuleReactionWheel"):DOACTION("activate wheel", TRUE).
			}
		}

		RETURN return_val.
	}

).
