(* Global Variable List: GVL_Modbus
   Create under Application -> Add Object -> Global Variable List.

   Modbus mapping (see docs/modbus_map.md):
     hr_inputs -> Holding register 0   (written by Node-RED, read by PLC)
     hr_status -> Input register 0     (written by PLC, read by Node-RED)
     hr_total  -> Input register 1
     hr_small  -> Input register 2
     hr_tall   -> Input register 3

   hr_inputs bits:
     bit0 S1 entry sensor      bit4 E-stop healthy (1 = OK)
     bit1 S2 tall sensor       bit5 Start button
     bit2 S_EXIT sensor        bit6 Stop button
     bit3 diverter feedback    bit7 Reset button

   hr_status bits:
     bit0 motor run   bit1 divert command   bit2 jam   bit3 diverter fail
*)
VAR_GLOBAL
    hr_inputs : WORD;
    hr_status : WORD;
    hr_total  : WORD;
    hr_small  : WORD;
    hr_tall   : WORD;
END_VAR
