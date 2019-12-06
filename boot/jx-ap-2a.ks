RUNPATH("0:/vtol.ks",

// Vertical Control
//  Accel F
	0.1, 
//  Z velocity PID Kp, Ki, Kd, Min, Max
	0.08, 0.08, 0.08, -0.1, 0.1,

//  Horizontal Control
//  Accel F
	0.5, 
//  X velocity PID Kp, Ki, Kd, Min, Max
	3, 3, 0.01, -25, 25,
//  Y velocity PID Kp, Ki, Kd, Min, Max
	3, 3, 0.05, -45, 25,

//  Steering Control
//  Pitch momentum F, Roll momentum F
	1, 0.3,
//  Pitch PID Kp, Ki, Kd, Min, Max
	0.1, 0.05, 0.01, -1, 1,
//  Roll PID Kp, Ki, Kd, Min, Max
	0.1, 0.03, 0.006, -1, 1,
//  Yaw PID Kp, Ki, Kd, Min, Max
	0.1, 0.03, 0.006, -1, 1

).
