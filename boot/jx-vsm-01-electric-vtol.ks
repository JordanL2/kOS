SET prop_ready TO FALSE.


RUNPATH("0:/vtol.ks",

// Vertical Control
//  Accel F
	0.2,
//  Z velocity PID Kp, Ki, Kd, Min, Max
	0.01, 0.001, 0.01, -0.01, 0.01,

//  Horizontal Control
//  Accel F
	0.5,
//  X velocity PID Kp, Ki, Kd, Min, Max
	3, 3, 0.01, -25, 25,
//  Y velocity PID Kp, Ki, Kd, Min, Max
	3, 3, 0.05, -45, 25,

//  Steering Control
//  Pitch momentum F, Roll momentum F
	0.1, 0.02,
//  Pitch PID Kp, Ki, Kd, Min, Max
	0.2, 0.01, 0.01, -0.5, 0.5,
//  Roll PID Kp, Ki, Kd, Min, Max
	0.4, 0.005, 0.1, -0.5, 0.5,
//  Yaw PID Kp, Ki, Kd, Min, Max
	0.1, 0.03, 0.006, -0.5, 0.5,

	{
		PARAMETER ch.
		SET return_val TO FALSE.

		IF ch = "1" {

			SET service_bay TO SHIP:PARTSTITLED("Service Bay (1.25m)")[0].
			SET piston TO SHIP:PARTSTITLED("1P2 Hydraulic Cylinder")[0].
			SET engine TO SHIP:PARTSTITLED("FS1FPE Folding Electric Propeller")[0].
			SET reactionwheel TO SHIP:PARTSTITLED("Advanced Inline Stabilizer")[0].

			SET prop_ready TO NOT prop_ready.
			IF prop_ready {

				// Activate engine
				reactionwheel:GETMODULE("ModuleReactionWheel"):DOACTION("activate wheel", TRUE).
				service_bay:GETMODULE("ModuleAnimateGeneric"):DOACTION("toggle", TRUE).
				WAIT 1.
				piston:GETMODULE("ModuleRoboticServoPiston"):DOACTION("extend piston", TRUE).
				WAIT 1.5.
				engine:GETMODULE("FSanimateGeneric"):DOACTION("toggle folded state", TRUE).
				WAIT 2.
				engine:GETMODULE("ModuleEngines"):DOACTION("activate engine", TRUE).

			} ELSE {

				// Deactivate engine
				engine:GETMODULE("ModuleEngines"):DOACTION("shutdown engine", TRUE).
				WAIT 3.
				engine:GETMODULE("FSanimateGeneric"):DOACTION("toggle folded state", TRUE).
				WAIT 2.
				piston:GETMODULE("ModuleRoboticServoPiston"):DOACTION("retract piston", TRUE).
				WAIT 1.5.
				service_bay:GETMODULE("ModuleAnimateGeneric"):DOACTION("toggle", TRUE).
				reactionwheel:GETMODULE("ModuleReactionWheel"):DOACTION("deactivate wheel", TRUE).

			}

			SET return_val TO TRUE.
		}

		IF prop_ready {
			PRINT "      VTOL ENGINE: ACTIVE  " AT (0, 31).
		} ELSE {
			PRINT "      VTOL ENGINE: DISABLED" AT (0, 31).
		}

		RETURN return_val.
	}

).
