(* ConveyorCtrl: paste into the BOTTOM (code) pane of the POU.
   Then call it from PLC_PRG with:  ConveyorCtrl();  *)

(* ---- unpack inputs from the Modbus word ---- *)
s1_item   := (GVL_Modbus.hr_inputs AND 16#0001) <> 0;
s2_tall   := (GVL_Modbus.hr_inputs AND 16#0002) <> 0;
s_exit    := (GVL_Modbus.hr_inputs AND 16#0004) <> 0;
div_fb    := (GVL_Modbus.hr_inputs AND 16#0008) <> 0;
estop_ok  := (GVL_Modbus.hr_inputs AND 16#0010) <> 0;
start_cmd := (GVL_Modbus.hr_inputs AND 16#0020) <> 0;
stop_cmd  := (GVL_Modbus.hr_inputs AND 16#0040) <> 0;
reset_cmd := (GVL_Modbus.hr_inputs AND 16#0080) <> 0;

(* ---- run control: seal-in, E-stop and faults drop it out ---- *)
running   := (start_cmd OR running) AND NOT stop_cmd
             AND estop_ok AND NOT jam AND NOT div_fail;
motor_run := running;

(* ---- jam: S1 blocked too long while running ---- *)
jam_tmr(IN := s1_item AND running, PT := T#3S);
IF jam_tmr.Q THEN
    jam := TRUE;
END_IF;
IF reset_cmd AND NOT s1_item THEN
    jam      := FALSE;
    div_fail := FALSE;
END_IF;

(* ---- classify: tall if S2 was seen while S1 was blocked ---- *)
IF s1_item AND s2_tall THEN
    large_seen := TRUE;
END_IF;

s1_fall(CLK := s1_item);
IF s1_fall.Q THEN
    IF large_seen THEN
        pending  := TRUE;
        tall_cnt := tall_cnt + 1;
    ELSE
        small_cnt := small_cnt + 1;
    END_IF;
    total_cnt  := total_cnt + 1;
    large_seen := FALSE;
END_IF;

(* ---- timed divert pulse (one box in flight at a time) ---- *)
travel_tmr(IN := pending AND running, PT := T#2S);
IF travel_tmr.Q THEN
    divert_cmd := TRUE;
END_IF;

pulse_tmr(IN := divert_cmd, PT := T#500MS);
IF pulse_tmr.Q THEN
    divert_cmd := FALSE;
    pending    := FALSE;
END_IF;

(* ---- diverter feedback supervision ---- *)
fb_tmr(IN := divert_cmd AND NOT div_fb, PT := T#300MS);
IF fb_tmr.Q THEN
    div_fail := TRUE;
END_IF;

(* ---- pack outputs for Modbus ---- *)
GVL_Modbus.hr_status := BOOL_TO_WORD(motor_run)
                        OR SHL(BOOL_TO_WORD(divert_cmd), 1)
                        OR SHL(BOOL_TO_WORD(jam), 2)
                        OR SHL(BOOL_TO_WORD(div_fail), 3);
GVL_Modbus.hr_total := INT_TO_WORD(total_cnt);
GVL_Modbus.hr_small := INT_TO_WORD(small_cnt);
GVL_Modbus.hr_tall  := INT_TO_WORD(tall_cnt);
