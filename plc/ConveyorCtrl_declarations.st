(* ConveyorCtrl: paste into the TOP (declaration) pane of the POU.
   Create the POU as: Program, language Structured Text.
   Do not paste the code body here; it goes into the bottom pane. *)
PROGRAM ConveyorCtrl
VAR
    (* unpacked inputs *)
    s1_item, s2_tall, s_exit, div_fb, estop_ok : BOOL;
    start_cmd, stop_cmd, reset_cmd             : BOOL;

    (* outputs *)
    motor_run, divert_cmd, jam, div_fail       : BOOL;

    (* internal state *)
    running, large_seen, pending               : BOOL;
    total_cnt, small_cnt, tall_cnt             : INT;

    s1_fall : F_TRIG;
    jam_tmr, travel_tmr, pulse_tmr, fb_tmr : TON;
END_VAR
