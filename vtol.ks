// Arguments

PARAMETER
    velzaccF,
    velzpidKp, velzpidKi, velzpidKd, velzpidMi, velzpidMa,
    velhaccF,
    velxpidKp, velxpidKi, velxpidKd, velxpidMi, velxpidMa,
    velypidKp, velypidKi, velypidKd, velypidMi, velypidMa,
    pitchmomF, rollmomF, yawmomF,
    pitchpidKp, pitchpidKi, pitchpidKd, pitchpidMi, pitchpidMa,
    rollpidKp, rollpidKi, rollpidKd, rollpidMi, rollpidMa,
    yawpidKp, yawpidKi, yawpidKd, yawpidMi, yawpidMa,
    loopFunction IS { PARAMETER ch. RETURN FALSE. }
    .


// Default Values

SET vcontrol TO 0.
SET velztgt TO 0.

SET hcontrol TO 0.
SET velxtgt TO 0.
SET velytgt TO 0.

SET displayframes TO 5.

SET finecontrol TO 0.
SET normalinc TO 1.
SET fineinc TO 0.1.
SET superinc to 10.
SET inc TO normalinc.

SET autogear TO 0.
SET autogear_altitude to 20.


// Functions

DECLARE FUNCTION degrees {
    DECLARE PARAMETER deg.

    UNTIL deg >= 0 {
        SET deg TO deg + 360.
    }
    UNTIL deg < 360 {
        SET deg TO deg - 360.
    }

    RETURN deg.
}

DECLARE FUNCTION balanced_degrees {
    DECLARE PARAMETER deg.

    UNTIL deg >= -180 {
        SET deg TO deg + 360.
    }
    UNTIL deg < 180 {
        SET deg TO deg - 360.
    }

    RETURN deg.
}

DECLARE FUNCTION display {
    DECLARE PARAMETER num.
    SET num TO ROUND(num, 3).

    IF num < 0 {
        RETURN num.
    }
    RETURN " " + num.
}


// Vertical Velocity Control Setup

LOCK velz TO SHIP:VERTICALSPEED.
LOCK velzacc TO SHIP:SENSORS:ACC:Z.

LOCK velzacctgt TO (velztgt - velz) * velzaccF.
SET velzpid TO PIDLOOP(velzpidKp, velzpidKi, velzpidKd, velzpidMi, velzpidMa).
velzpid:RESET().


// Horizontal Velocity Control Setup

LOCK velx TO SHIP:VELOCITY:SURFACE * SHIP:FACING:STARVECTOR.
LOCK vely TO SHIP:VELOCITY:SURFACE * SHIP:FACING:FOREVECTOR.

LOCK velxacc TO SHIP:SENSORS:ACC * SHIP:FACING:STARVECTOR.
LOCK velyacc TO SHIP:SENSORS:ACC * SHIP:FACING:FOREVECTOR.

LOCK velxacctgt TO (velxtgt - velx) * velhaccF / MAX(1, ABS(vely)).
LOCK velyacctgt TO (velytgt - vely) * velhaccF.

SET velxpid TO PIDLOOP(velxpidKp, velxpidKi, velxpidKd, velxpidMi, velxpidMa).
velxpid:RESET().
// This gets inverted, the pitch is actually limited from -25 (down) to +45 (up) in order to enable quick stopping
SET velypid TO PIDLOOP(velypidKp, velypidKi, velypidKd, velypidMi, velypidMa).
velypid:RESET().


// Steering Control Setup

LOCK pitch TO 90 - vectorangle(UP:FOREVECTOR, FACING:FOREVECTOR).
LOCK yaw TO degrees(360 - SHIP:BEARING).
LOCK roll TO balanced_degrees(vectorangle(up:vector,ship:facing:starvector) + 270).

LOCK pitchmom TO 0 - SHIP:ANGULARMOMENTUM:X.
LOCK rollmom TO 0 - SHIP:ANGULARMOMENTUM:Y.
LOCK yawmom TO 0 - SHIP:ANGULARMOMENTUM:Z.

SET pitchtgt TO 0.
SET rolltgt TO 0.
SET yawtgt TO ROUND(yaw).

LOCK pitchmomtgt TO (pitchtgt - pitch) * pitchmomF.
LOCK rollmomtgt TO (rolltgt - roll) * rollmomF.
LOCK yawmomtgt TO (yawtgt - yaw) * yawmomF.

SET pitchpid TO PIDLOOP(pitchpidKp, pitchpidKi, pitchpidKd, pitchpidMi, pitchpidMa).
pitchpid:RESET().
SET rollpid TO PIDLOOP(rollpidKp, rollpidKi, rollpidKd, rollpidMi, rollpidMa).
rollpid:RESET().
SET yawpid TO PIDLOOP(yawpidKp, yawpidKi, yawpidKd, yawpidMi, yawpidMa).
yawpid:RESET().


// Main Loop

CLEARSCREEN.
SET framecount TO displayframes.
SET fpstimestart TO TIME:SECONDS.
SET fpscount TO 0.
UNTIL FALSE {

    // Frame Timing

    SET framestarttime TO TIME:SECONDS.


    // Vertical Control

    IF vcontrol = 0 {

        IF framecount = displayframes {

            PRINT "   V-CONTROL: OFF [V to enable] " AT(0, 0).

            PRINT "----------------------------------" AT(0, 7).

        }

    } ELSE {

        // Display Status

        IF framecount = displayframes {

            PRINT "   V-CONTROL: ON  [V to disable]" AT(0, 0).

            PRINT "   VEL-Z-TGT: " + display(velztgt)    + " [-/+, BSP to zero]" AT(0, 2).
            PRINT "       VEL-Z: " + display(velz)       + "     " AT(0, 3).
            PRINT "VEL-Z-ACCTGT: " + display(velzacctgt) + "     " AT(0, 4).
            print "   VEL-Z-ACC: " + display(velzacc)    + "     " AT(0, 5).

            PRINT "----------------------------------" AT(0, 7).

        }


        // Vertical Velocity PID Loop

        IF (SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" OR SHIP:STATUS = "PRELAUNCH") AND velztgt <= 0 {
            SET thrott TO 0.
        } ELSE {
            SET velzpid:SETPOINT TO velzacctgt.
            SET thrott TO MAX(0, MIN(1, thrott + velzpid:UPDATE(TIME:SECONDS, velzacc))).
        }

    }


    // Horizontal Control

    IF hcontrol = 0 {

        IF framecount = displayframes {

            PRINT "   H-CONTROL: OFF [H to enable] " AT(0, 9).

            PRINT "----------------------------------" AT(0, 26).

        }

    } ELSE {

        IF framecount = displayframes {

            PRINT "   H-CONTROL: ON  [H to disable]" AT(0, 9).

            PRINT " BEARING-TGT: " + display(yawtgt)    + " [Q/E, R to zero]" AT(0, 11).
            PRINT "     BEARING: " + display(yaw)       + "     " AT(0, 12).
            PRINT " MOM-YAW-TGT: " + display(yawmomtgt) + "     " AT(0, 13).
            PRINT "     MOM-YAW: " + display(yawmom)    + "     " AT(0, 14).

            PRINT "   VEL-X-TGT: " + display(velxtgt) + " [A/D, R to zero]" AT(0, 16).
            PRINT "       VEL-X: " + display(velx)    + "     " AT(0, 17).
            PRINT "    ROLL-TGT: " + display(rolltgt)   + "     " AT(0, 18).
            PRINT "        ROLL: " + display(roll)      + "     " AT(0, 19).

            PRINT "   VEL-Y-TGT: " + display(velytgt) + " [W/S or PgUp/PgDown, R to zero]" AT(0, 21).
            PRINT "       VEL-Y: " + display(vely)    + "     " AT(0, 22).
            PRINT "   PITCH-TGT: " + display(pitchtgt)  + "     " AT(0, 23).
            PRINT "       PITCH: " + display(pitch)     + "     " AT(0, 24).

            PRINT "----------------------------------" AT(0, 26).

        }


        // Horizontal Velocity PID Loop

        SET velxpid:SETPOINT TO velxacctgt.
        SET rolltgt TO velxpid:UPDATE(TIME:SECONDS, velxacc).

        SET velypid:SETPOINT TO velyacctgt.
        SET pitchtgt TO (0 - velypid:UPDATE(TIME:SECONDS, velyacc)).


        // Steering PID Loop

        SET pitchpid:SETPOINT TO pitchmomtgt.
        SET SHIP:CONTROL:PITCH TO pitchpid:UPDATE(TIME:SECONDS, pitchmom).

        SET rollpid:SETPOINT TO rollmomtgt.
        SET SHIP:CONTROL:ROLL TO rollpid:UPDATE(TIME:SECONDS, rollmom).

        SET yawpid:SETPOINT TO yawmomtgt.
        SET SHIP:CONTROL:YAW TO yawpid:UPDATE(TIME:SECONDS, yawmom).

    }


    // Fine Control Display

    IF framecount = displayframes {
        IF finecontrol = 0 {
            PRINT "     FINE-CONTROL: OFF [F to enable] " AT(0, 28).
        } ELSE {
            PRINT "     FINE-CONTROL: ON  [F to disable]" AT(0, 28).
        }
    }


    // Auto-gear control and Altitude

	SET ship_altitude TO ROUND(ALTITUDE - MAX(0, GEOPOSITION:TERRAINHEIGHT), 3).
    IF autogear = 0 {
		PRINT "AUTO GEAR CONTROL: OFF [G to enable]" AT(0, 29).
    } ELSE {
		PRINT "AUTO GEAR CONTROL: ON  [G to disable]" AT(0, 29).

		IF ship_altitude < autogear_altitude {
			GEAR ON.
		} ELSE {
			GEAR OFF.
		}
    }
    PRINT "         ALTITUDE: " + ship_altitude + "m       " AT(0, 30).


    // Frame Count for Display

    SET framecount TO framecount + 1.
    IF framecount > displayframes {
        SET framecount TO 0.
    }


    // Get Input From User

    IF Terminal:Input:HASCHAR {
        SET framecount TO displayframes.

        SET ch TO Terminal:Input:GETCHAR.

        IF loopFunction(ch) {
        	// Custom loop function consumed the input

        } ELSE IF ch = "v" {
            IF vcontrol = 0 {
                SET vcontrol TO 1.

                SET velztgt TO 0.
                IF (SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" OR SHIP:STATUS = "PRELAUNCH") {
                    SET thrott TO 0.
                } ELSE {
                    SET thrott TO 1.
                }
                LOCK THROTTLE to thrott.
            } ELSE {
                SET vcontrol TO 0.

                UNLOCK THROTTLE.

                CLEARSCREEN.
            }

        } ELSE IF ch = "-" {
            SET velztgt TO velztgt - inc.
        } ELSE IF ch = "=" {
            SET velztgt TO velztgt + inc.
        } ELSE IF ch = Terminal:Input:BACKSPACE {
            SET velztgt TO 0.

        } ELSE IF ch = "h" {
            IF hcontrol = 0 {
                SET hcontrol TO 1.

                SET SHIP:CONTROL:PITCH TO 0.
                SET SHIP:CONTROL:ROLL TO 0.
                SET SHIP:CONTROL:YAW TO 0.
                SAS OFF.

                SET velxtgt TO 0.
                SET velytgt TO 0.
                SET yawtgt TO ROUND(yaw).

            } ELSE {
                SET hcontrol TO 0.

                SET SHIP:CONTROL:PITCH TO 0.
                SET SHIP:CONTROL:ROLL TO 0.
                SET SHIP:CONTROL:YAW TO 0.
                SET SHIP:CONTROL:NEUTRALIZE to TRUE.
                SAS ON.

                CLEARSCREEN.
            }

        } ELSE IF ch = "q" {
            SET yawtgt TO yawtgt - inc.
        } ELSE IF ch = "e" {
            SET yawtgt TO yawtgt + inc.

        } ELSE IF ch = "w" {
            SET velytgt TO velytgt + inc.
        } ELSE IF ch = "s" {
            SET velytgt TO velytgt - inc.
        } ELSE IF ch = "a" {
            SET velxtgt TO velxtgt - inc.
        } ELSE  IF ch = "d" {
            SET velxtgt TO velxtgt + inc.

        } ELSE IF ch = Terminal:Input:PAGEUPCURSOR {
            SET velytgt TO velytgt + superinc.
        } ELSE IF ch = Terminal:Input:PAGEDOWNCURSOR {
            SET velytgt TO velytgt - superinc.

        } ELSE IF ch = "r" {
            SET velxtgt TO 0.
            SET velytgt TO 0.
            SET yawtgt TO ROUND(yaw).

        } ELSE IF ch = "f" {
            IF finecontrol = 0 {
                SET finecontrol TO 1.
                SET inc TO fineinc.
            } ELSE {
                SET finecontrol TO 0.
                SET inc TO normalinc.
            }

        } ELSE IF ch = "g" {
            IF autogear = 0 {
                SET autogear TO 1.
            } ELSE {
                SET autogear TO 0.
            }

		} ELSE IF ch = "1" {
			TOGGLE AG1.
		} ELSE IF ch = "2" {
			TOGGLE AG2.
		} ELSE IF ch = "3" {
			TOGGLE AG3.
		} ELSE IF ch = "4" {
			TOGGLE AG4.
		} ELSE IF ch = "5" {
			TOGGLE AG5.
		} ELSE IF ch = "6" {
			TOGGLE AG6.
		} ELSE IF ch = "7" {
			TOGGLE AG7.
		} ELSE IF ch = "8" {
			TOGGLE AG8.
		} ELSE IF ch = "9" {
			TOGGLE AG9.
		} ELSE IF ch = "0" {
			TOGGLE AG10.

        }

    } ELSE {
    	// Key wasn't pressed but we should call
    	// the custom loop function anyway
    	loopFunction("").

    }


    // Frame Timing

    SET fpscount TO fpscount + 1.
    IF TIME:SECONDS - fpstimestart >= 1 {
        SET fpstimestart TO fpstimestart + 1.
        PRINT "FPS: " + fpscount + "    " AT (0, 36).
        SET fpscount TO 0.
    }

    WAIT 0.08 - (TIME:SECONDS - framestarttime).

}
