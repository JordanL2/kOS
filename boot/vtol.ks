// Default Values

SET vcontrol TO 0.
SET velztgt TO 0.

SET hcontrol TO 0.
SET velxtgt TO 0.
SET velytgt TO 0.

SET displayframes TO 5.


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

SET velzaccF TO 0.1.
LOCK velzacctgt TO (velztgt - velz) * velzaccF.
SET vertpid TO PIDLOOP(0.08, 0.08, 0.08, -0.1, 0.1).
vertpid:RESET().


// Horizontal Velocity Control Setup

LOCK velx TO SHIP:VELOCITY:SURFACE * SHIP:FACING:STARVECTOR.
LOCK vely TO SHIP:VELOCITY:SURFACE * SHIP:FACING:FOREVECTOR.

SET velxpid TO PIDLOOP(3, 1, 0.1, -25, 25).
velxpid:RESET().
// This gets inverted, the pitch is actually limited from -25 (down) to +45 (up) in order to enable quick stopping
SET velypid TO PIDLOOP(3, 1, 0.1, -45, 25).
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
SET yawmomtgt TO 0.

SET momF TO 1.
LOCK pitchmomtgt TO (pitchtgt - pitch) * momF.
LOCK rollmomtgt TO (rolltgt - roll) * momF.

SET pitchpid TO PIDLOOP(0.1, 0.05, 0.01, -1, 1).
pitchpid:RESET().
SET rollpid TO PIDLOOP(0.1, 0.03, 0.006, -1, 1).
rollpid:RESET().
SET yawpid TO PIDLOOP(0.1, 0.03, 0.006, -1, 1).
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

            PRINT "   V-CONTROL: OFF [V to enable]" AT(0, 0).

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
            SET vertpid:SETPOINT TO velzacctgt.
            SET thrott TO MAX(0, MIN(1, thrott + vertpid:UPDATE(TIME:SECONDS, velzacc))).
        }

    }


    // Horizontal Control

    IF hcontrol = 0 {

        IF framecount = displayframes {

            PRINT "   H-CONTROL: OFF [H to enable]" AT(0, 9).

            PRINT "----------------------------------" AT(0, 25).

        }

    } ELSE {

        IF framecount = displayframes {
        
            PRINT "   H-CONTROL: ON  [H to disable]" AT(0, 9).

            PRINT " MOM-YAW-TGT: " + display(yawmomtgt) + " [Q/E, R to zero]" AT(0, 11).
            PRINT "     MOM-YAW: " + display(yawmom)    + "     " AT(0, 12).
            PRINT "     BEARING: " + display(yaw)       + "     " AT(0, 13).

            PRINT "   VEL-X-TGT: " + display(velxtgt) + " [A/D, R to zero]" AT(0, 15).
            PRINT "       VEL-X: " + display(velx)    + "     " AT(0, 16).
            PRINT "    ROLL-TGT: " + display(rolltgt)   + "     " AT(0, 17).
            PRINT "        ROLL: " + display(roll)      + "     " AT(0, 18).
            
            PRINT "   VEL-Y-TGT: " + display(velytgt) + " [W/S, R to zero]" AT(0, 20).
            PRINT "       VEL-Y: " + display(vely)    + "     " AT(0, 21).
            PRINT "   PITCH-TGT: " + display(pitchtgt)  + "     " AT(0, 22).
            PRINT "       PITCH: " + display(pitch)     + "     " AT(0, 23).

            PRINT "----------------------------------" AT(0, 25).

        }


        // Horizontal Velocity PID Loop

        SET velxpid:SETPOINT TO velxtgt.
        SET rolltgt TO velxpid:UPDATE(TIME:SECONDS, velx).

        SET velypid:SETPOINT TO velytgt.
        SET pitchtgt TO (0 - velypid:UPDATE(TIME:SECONDS, vely)).

    
        // Steering PID Loop
    
        SET pitchpid:SETPOINT TO pitchmomtgt.
        SET SHIP:CONTROL:PITCH TO pitchpid:UPDATE(TIME:SECONDS, pitchmom).
        
        SET rollpid:SETPOINT TO rollmomtgt.
        SET SHIP:CONTROL:ROLL TO rollpid:UPDATE(TIME:SECONDS, rollmom).
        
        SET yawpid:SETPOINT TO yawmomtgt.
        SET SHIP:CONTROL:YAW TO yawpid:UPDATE(TIME:SECONDS, yawmom).

    }


    // Frame Count for Display
    
    SET framecount TO framecount + 1.
    IF framecount > displayframes {
        SET framecount TO 0.
    }


    // Get Input From User

    IF Terminal:Input:HASCHAR {
        SET framecount TO displayframes.

        SET ch TO Terminal:Input:GETCHAR.
        IF ch = "v" {
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
        }
        IF ch = "-" {
            SET velztgt TO velztgt - 1.
        }
        IF ch = "=" {
            SET velztgt TO velztgt + 1.
        }
        IF ch = Terminal:Input:BACKSPACE {
            SET velztgt TO 0.
        }
        
        IF ch = "h" {
            IF hcontrol = 0 {
                SET hcontrol TO 1.

                SET SHIP:CONTROL:PITCH TO 0.
                SET SHIP:CONTROL:ROLL TO 0.
                SET SHIP:CONTROL:YAW TO 0.
                SAS OFF.

                SET velxtgt TO 0.
                SET velytgt TO 0.
                SET yawmomtgt TO 0.
            } ELSE {
                SET hcontrol TO 0.
                
                SET SHIP:CONTROL:PITCH TO 0.
                SET SHIP:CONTROL:ROLL TO 0.
                SET SHIP:CONTROL:YAW TO 0.
                SET SHIP:CONTROL:NEUTRALIZE to TRUE.
                SAS ON.

                CLEARSCREEN.
            }
        }
        IF ch = "q" {
            SET yawmomtgt TO yawmomtgt - 1.
        }
        IF ch = "e" {
            SET yawmomtgt TO yawmomtgt + 1.
        }
        IF ch = "w" {
            SET velytgt TO velytgt + 1.
        }
        IF ch = "s" {
            SET velytgt TO velytgt - 1.
        }
        IF ch = "a" {
            SET velxtgt TO velxtgt - 1.
        }
        IF ch = "d" {
            SET velxtgt TO velxtgt + 1.
        }
        IF ch = "r" {
            SET velxtgt TO 0.
            SET velytgt TO 0.
            SET yawmomtgt TO 0.
        }
    }


    // Frame Timing
    
    SET fpscount TO fpscount + 1.
    IF TIME:SECONDS - fpstimestart >= 1 {
        SET fpstimestart TO fpstimestart + 1.
        PRINT "         FPS: " + display(fpscount) + "    " AT (0, 27).
        SET fpscount TO 0.
    }

    WAIT 0.09 - (TIME:SECONDS - framestarttime).

}
