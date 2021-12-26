SET storage_open TO FALSE.

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
	6, 0.6, 0.06, -25, 25,
//  Y velocity PID Kp, Ki, Kd, Min, Max
	6, 0.6, 0.06, -30, 30,

//  Steering Control
//  Pitch momentum F, Roll momentum F, Yaw momentum F
	0.2, 0.05, 0.1,
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

		SET storage_module TO SHIP:PARTSTITLED("PAS-C Storage Module")[0].
		IF (vcontrol = 0 AND storage_open) OR (vcontrol = 1 AND NOT storage_open) {
			storage_module:GETMODULE("ModuleAnimateGeneric"):DOACTION("toggle bay doors", TRUE).
			SET storage_open TO NOT storage_open.
		}

		RETURN return_val.
	}

).
