RUNPATH("0:/vtol.ks",

// Vertical Control
//  Accel F
	0.2,
//  Z velocity PID Kp, Ki, Kd, Min, Max
	0.01, 0.01, 0.01, -0.01, 0.01,

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
	0.1, 0.05, 0.01, -0.5, 0.5,
//  Roll PID Kp, Ki, Kd, Min, Max
	0.4, 0.005, 0.1, -0.5, 0.5,
//  Yaw PID Kp, Ki, Kd, Min, Max
	0.1, 0.03, 0.006, -0.5, 0.5

).
