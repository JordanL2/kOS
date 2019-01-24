CLEARSCREEN.


// Default Values

SET vcontrol TO 0.
SET vveltgt TO 0.

SET hcontrol TO 0.
SET velxtgt TO 0.
SET velytgt TO 0.

SET displayframes TO 10.


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

LOCK vertacc TO SHIP:SENSORS:ACC:Z.
LOCK vvel TO SHIP:VERTICALSPEED.

SET vertaccF TO 0.2.
LOCK vertacctgt TO vertaccF * (vveltgt - vvel).
SET vertpid TO PIDLOOP(0.04, 0.04, 0.04, -0.05, 0.05).
vertpid:RESET().


// Horizontal Velocity Control Setup

SET maxtilt TO 45.

LOCK velx TO SHIP:VELOCITY:SURFACE * SHIP:FACING:STARVECTOR.
LOCK vely TO SHIP:VELOCITY:SURFACE * SHIP:FACING:FOREVECTOR.
SET velxpid TO PIDLOOP(3, 1, 0.1, -maxtilt, maxtilt).
velxpid:RESET().
SET velypid TO PIDLOOP(3, 1, 0.1, -maxtilt, maxtilt).
velypid:RESET().


// Steering Control Setup

SET pitchtgt TO 0.
SET rolltgt TO 0.
SET yawtgtvel TO 0.

LOCK pitch TO 90 - vectorangle(UP:FOREVECTOR, FACING:FOREVECTOR).
LOCK yaw TO degrees(360 - SHIP:BEARING).
LOCK roll TO balanced_degrees(vectorangle(up:vector,ship:facing:starvector) + 270).

LOCK pitchmom TO 0 - SHIP:ANGULARMOMENTUM:X.
LOCK rollmom TO 0 - SHIP:ANGULARMOMENTUM:Y.
LOCK yawmom TO 0 - SHIP:ANGULARMOMENTUM:Z.

SET momF TO 1.
LOCK pitchmomtgt TO (pitchtgt - pitch) * momF.
LOCK rollmomtgt TO (rolltgt - roll) * momF.
LOCK yawmomtgt TO yawtgtvel.

SET pitchpid TO PIDLOOP(0.1, 0.05, 0.01, -1, 1).
pitchpid:RESET().
SET rollpid TO PIDLOOP(0.1, 0.03, 0.006, -1, 1).
rollpid:RESET().
SET yawpid TO PIDLOOP(0.1, 0.03, 0.006, -1, 1).
yawpid:RESET().

SET SHIP:CONTROL:PITCH TO 0.
SET SHIP:CONTROL:ROLL TO 0.
SET SHIP:CONTROL:YAW TO 0.



// Main Loop

SET framecount TO 0.
UNTIL FALSE {

    // Vertical Control

    IF vcontrol = 0 {

        PRINT "     CONTROL: OFF [V to toggle]" AT(0, 0).

    } ELSE {
        
        // Display Status

        IF framecount = displayframes {

            PRINT "   V-CONTROL: ON  [V to toggle]" AT(0, 0).

            PRINT "   VEL-V-TGT: " + display(vveltgt)    + " [-/+, BSP to zero]" AT(0, 2).
            PRINT "       VEL-V: " + display(vvel)       + "     " AT(0, 3).
            PRINT "VEL-V-ACCTGT: " + display(vertacctgt) + "     " AT(0, 4).
            print "   VEL-V-ACC: " + display(vertacc)    + "     " AT(0, 5).

        }


        // Vertical Velocity PID Loop

        IF (SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED" OR SHIP:STATUS = "PRELAUNCH") AND vveltgt <= 0 {
            SET thrott TO 0.
        } ELSE {
            SET vertpid:SETPOINT TO vertacctgt.
            SET thrott TO MAX(0, MIN(1, thrott + vertpid:UPDATE(TIME:SECONDS, vertacc))).
        }

    }


    // Horizontal Control

    IF hcontrol = 0 {

        PRINT "----------------------------------" AT(0, 7).
        PRINT "   H-CONTROL: OFF [H to toggle]" AT(0, 9).

    } ELSE {

        IF framecount = displayframes {

            PRINT "   H-CONTROL: ON  [H to toggle]" AT(0, 9).

            PRINT " YAW-TGT-VEL: " + display(yawtgtvel) + " [Q/E, R to zero]" AT(0, 11).
            PRINT "     YAW-VEL: " + display(yawmom)    + "     " AT(0, 12).
            PRINT "     BEARING: " + display(yaw)       + "     " AT(0, 13).

            PRINT "   VEL-X-TGT: " + display(velxtgt) + " [Q/E, R to zero]" AT(0, 15).
            PRINT "       VEL-X: " + display(velx)    + "     " AT(0, 16).
            PRINT "    ROLL-TGT: " + display(rolltgt)   + "     " AT(0, 17).
            PRINT "        ROLL: " + display(roll)      + "     " AT(0, 18).
            
            PRINT "   VEL-Y-TGT: " + display(velytgt) + " [Q/E, R to zero]" AT(0, 20).
            PRINT "       VEL-Y: " + display(vely)    + "     " AT(0, 21).
            PRINT "   PITCH-TGT: " + display(pitchtgt)  + "     " AT(0, 22).
            PRINT "       PITCH: " + display(pitch)     + "     " AT(0, 23).

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

                SET vveltgt TO 0.
                SET thrott TO 0.
                LOCK THROTTLE to thrott.
            } ELSE {
                SET vcontrol TO 0.

                UNLOCK THROTTLE.

                CLEARSCREEN.
            }
        }
        IF ch = "-" {
            SET vveltgt TO vveltgt - 1.
        }
        IF ch = "=" {
            SET vveltgt TO vveltgt + 1.
        }
        IF ch = Terminal:Input:BACKSPACE {
            SET vveltgt TO 0.
        }
        
        IF ch = "h" {
            IF hcontrol = 0 {
                SET hcontrol TO 1.

                SET velxtgt TO 0.
                SET velytgt TO 0.
                SET yawtgtvel TO 0.

                SAS OFF.
            } ELSE {
                SET hcontrol TO 0.
                
                SET SHIP:CONTROL:NEUTRALIZE to TRUE.
                SET SHIP:CONTROL:PITCH TO 0.
                SET SHIP:CONTROL:ROLL TO 0.
                SET SHIP:CONTROL:YAW TO 0.
                SAS ON.

                CLEARSCREEN.
            }
        }
        IF ch = "q" {
            SET yawtgtvel TO yawtgtvel - 1.
        }
        IF ch = "e" {
            SET yawtgtvel TO yawtgtvel + 1.
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
            SET yawtgtvel TO 0.
        }
    }

    WAIT 0.001.
}
